
# ============================================================================
# SCHRITT 4: Terminal.Gui initialisieren & Layout aufbauen
# ============================================================================
# Terminal.Gui arbeitet mit einer Hierarchie von Views (UI-Elementen):
#   Application.Top          <-- Wurzel-Container (der gesamte Bildschirm)
#     └── Window             <-- Hauptfenster mit Titel und Rahmen
#           ├── headerLabel  <-- Statuszeile oben (Session-Info, Uhrzeit)
#           ├── tableFrame   <-- Rahmen fuer die Tabelle (obere 40% des Fensters)
#           │     └── tableView   <-- Die eigentliche Datentabelle
#           ├── chartFrame   <-- Rahmen fuer die Sparklines (restlicher Platz)
#           │     └── sparkLabel  <-- Label, das die Sparkline-Zeichen enthaelt
#           ├── btnPause     <-- Button: Pause/Resume
#           ├── btnToggle    <-- Button: Sparklines ein/aus
#           └── btnQuit      <-- Button: Beenden



# ============================================================================
# SCHRITT 5: Anwendungslogik (Update-Funktionen, Timer, Event-Handler)
# ============================================================================

# Globale Zustandsvariablen (script-Scope, damit sie in Closures/Callbacks erreichbar sind)
$script:showSparklines = $true       # Sparklines sichtbar?
$script:isPaused = $false            # Datenaktualisierung pausiert?
$script:startTime = Get-Date         # Session-Startzeit fuer die Anzeige

function Update-Header {
    # Aktualisiert die Statuszeile oben mit Session-Infos, Counter-Anzahl,
    # Anzahl gesammelter Samples und aktueller Uhrzeit
    $sampleCount = if ($counters[0].HistoricalData.Count -gt 0) { $counters[0].HistoricalData.Count } else { 0 }
    $now = Get-Date -Format "HH:mm:ss"
    $paused = if ($script:isPaused) { "  [PAUSED]" } else { "" }
    $headerLabel.Text = " Session: $($script:startTime.ToString('dd.MM.yyyy HH:mm:ss'))  |  Intervall: 2s  |  Counter: $($counters.Count)  |  Samples: $sampleCount  |  Update: $now$paused"
}

function Update-Table {
    # Aktualisiert die gesamte Datentabelle: Loescht alle Zeilen und baut sie neu auf.
    # Das ist bei 4 Countern performant genug - bei vielen Countern muesste man
    # stattdessen einzelne Zellen updaten.
    $dataTable.Rows.Clear()
    foreach ($c in $counters) {
        $stats = $c.Statistics    # Dictionary mit berechneten Werten: Current, Minimum, Maximum, Average, Count, Last5

        $row = $dataTable.NewRow()
        $row[$script:colNames.Computer] = Format-Cell $c.ComputerName 12 -Left                                                                                         # Servername linksbuendig
        $row[$script:colNames.Counter]  = Format-Cell $c.Title 18 -Left                                                                                                # Counter-Name linksbuendig
        $row[$script:colNames.Unit]     = Format-Cell $c.Unit 6                                                                                                        # Einheit rechtsbuendig
        $row[$script:colNames.Aktuell]  = Format-Cell $(if ($stats.ContainsKey('Current')) { $stats['Current'].ToString("F$($c.DecimalPlaces)") } else { "-" }) 10      # Aktueller Wert
        $row[$script:colNames.Min]      = Format-Cell $(if ($stats.ContainsKey('Minimum')) { $stats['Minimum'].ToString("F1") } else { "-" }) 10                        # Minimum
        $row[$script:colNames.Max]      = Format-Cell $(if ($stats.ContainsKey('Maximum')) { $stats['Maximum'].ToString("F1") } else { "-" }) 10                        # Maximum
        $row[$script:colNames.Avg]      = Format-Cell $(if ($stats.ContainsKey('Average')) { $stats['Average'].ToString("F1") } else { "-" }) 10                        # Durchschnitt
        $row[$script:colNames.Samples]  = Format-Cell $(if ($stats.ContainsKey('Count'))   { $stats['Count'].ToString() } else { "0" }) 8                               # Anzahl Datenpunkte

        # "Last 5" Spalte: Die letzten 5 Messwerte nebeneinander anzeigen
        if ($stats.ContainsKey('Last5')) {
            $formattedLast5 = @($stats['Last5'] | ForEach-Object { $_.ToString().PadLeft(6) }) -join " | "
            $row[$script:colNames.Last5] = " $formattedLast5 "
        } else {
            $row[$script:colNames.Last5] = " - "
        }
        [void]$dataTable.Rows.Add($row)
    }
    # TableView muss explizit zum Neuzeichnen aufgefordert werden
    $tableView.Update()
}

# ============================================================================
# Unicode-Block-Zeichen fuer Sparklines
# ============================================================================
# Diese 9 Zeichen bilden einen vertikalen Balken von leer bis voll:
#   Index 0: Leerzeichen (kein Balken)
#   Index 1-8: Ansteigende Blockhoehe (1/8 bis 8/8 = voller Block)
# Hexadezimal definiert, um Copy-Paste-Fehler bei Unicode zu vermeiden

$script:sparkBlocks = @(
    ' ',            # 0: Leerzeichen (kein Balken)
    [char]0x2581,   # 1: ▁ (1/8 Block)
    [char]0x2582,   # 2: ▂ (2/8 Block)
    [char]0x2583,   # 3: ▃ (3/8 Block)
    [char]0x2584,   # 4: ▄ (4/8 Block)
    [char]0x2585,   # 5: ▅ (5/8 Block)
    [char]0x2586,   # 6: ▆ (6/8 Block)
    [char]0x2587,   # 7: ▇ (7/8 Block)
    [char]0x2588    # 8: █ (voller Block)
)


function Get-Sparkline3Row {
    # Erzeugt eine 3-zeilige Sparkline aus den historischen Datenpunkten.
    #
    # KONZEPT: Jeder Datenpunkt wird auf einen Level von 0-23 abgebildet.
    #   - Level  0-7:  Nur untere Zeile hat einen Balken (bottomLine)
    #   - Level  8-15: Untere Zeile voll + mittlere Zeile hat Balken (midLine)
    #   - Level 16-23: Untere+mittlere Zeile voll + obere Zeile hat Balken (topLine)
    #
    # Dadurch erhaelt man eine hoehere vertikale Aufloesung als mit nur einer Zeile
    # (24 Stufen statt 8). Die 3 Zeilen werden uebereinander dargestellt.
    #
    # $MaxWidth bestimmt, wie viele Datenpunkte (= Zeichen) maximal angezeigt werden.
    param([System.Collections.Generic.List[psTPCCLASSES.CounterConfiguration+DataPoint]]$Data, [int]$MaxWidth = 60)

    # Bei leeren Daten: 3 leere Zeilen zurueckgeben
    if ($Data.Count -eq 0) {
        $empty = " " * $MaxWidth
        return @($empty, $empty, $empty)
    }

    # Nur die letzten $MaxWidth Datenpunkte verwenden (neueste rechts)
    $values = $Data | Select-Object -Last $MaxWidth | ForEach-Object { $_.Value }
    $min = ($values | Measure-Object -Minimum).Minimum
    $max = ($values | Measure-Object -Maximum).Maximum
    $range = $max - $min    # Wertebereich fuer die Normalisierung

    $topLine = ""; $midLine = ""; $bottomLine = ""

    # Wenn weniger Datenpunkte als Breite: Links mit Leerzeichen auffuellen
    # Damit ist der Graph rechtsbuendig und waechst nach links
    $padCount = $MaxWidth - $values.Count
    if ($padCount -gt 0) {
        $padStr = " " * $padCount
        $topLine += $padStr; $midLine += $padStr; $bottomLine += $padStr
    }

    foreach ($val in $values) {
        # Wert auf Level 0-23 normalisieren (24 Stufen = 3 Zeilen × 8 Block-Stufen)
        $level = if ($range -gt 0) {
            [int][Math]::Floor((($val - $min) / $range) * 23.999)
        } else {
            12    # Bei konstantem Wert: Mitte (halbe Hoehe)
        }
        $level = [Math]::Clamp($level, 0, 23)

        # Level auf die 3 Zeilen aufteilen:
        if ($level -ge 16) {
            # Hoher Wert: Untere und mittlere Zeile komplett voll, obere Zeile teilweise
            $bottomIdx = 8              # Voller Block
            $midIdx    = 8              # Voller Block
            $topIdx    = $level - 16 + 1   # 1-8 (teilweiser Block)
        } elseif ($level -ge 8) {
            # Mittlerer Wert: Untere Zeile voll, mittlere Zeile teilweise, oben leer
            $bottomIdx = 8              # Voller Block
            $midIdx    = $level - 8 + 1    # 1-8 (teilweiser Block)
            $topIdx    = 0              # Leer
        } else {
            # Niedriger Wert: Nur untere Zeile teilweise gefuellt
            $bottomIdx = $level + 1        # 1-8 (teilweiser Block)
            $midIdx    = 0              # Leer
            $topIdx    = 0              # Leer
        }

        # Entsprechende Unicode-Block-Zeichen anhaengen
        $bottomLine += $script:sparkBlocks[$bottomIdx]
        $midLine    += $script:sparkBlocks[$midIdx]
        $topLine    += $script:sparkBlocks[$topIdx]
    }

    # Rueckgabe: Array mit 3 Strings [oben, mitte, unten]
    return @($topLine, $midLine, $bottomLine)
}

function Update-Sparklines {
    # Aktualisiert den gesamten Sparkline-Bereich.
    # Jeder Counter bekommt 3 Zeilen (oben/mitte/unten) + 1 Leerzeile dazwischen.

    if (-not $script:showSparklines) {
        $sparkLabel.Text = " [Sparklines deaktiviert]"
        return
    }

    # 1. Verfuegbare Breite des Labels im Terminal ermitteln
    #    (aendert sich dynamisch, wenn der Benutzer das Fenster skaliert)
    $availableWidth = $sparkLabel.Bounds.Width

    # Fallback fuer den allerersten Aufruf, bevor Application::Run() das Layout berechnet hat
    if ($availableWidth -le 0) {
        $availableWidth = 115
    }

    $labelWidth = 35
    # 2. Berechnung des Platzbedarfs fuer statische Elemente:
    #    39 Zeichen fuer Praefix (" # " + Label + " ")
    #    10 Zeichen fuer Suffix ("  " + Wert)
    $reservedWidth = 49

    # 3. Verbleibender Platz = maximale Sparkline-Breite
    $dynamicMaxWidth = $availableWidth - $reservedWidth

    # Sicherheitsschranke: Verhindert Fehler bei extrem kleinem Fenster
    if ($dynamicMaxWidth -lt 10) {
        $dynamicMaxWidth = 10
    }

    # Alle Zeilen in einer Liste sammeln, am Ende als ein String ins Label schreiben
    $lines = [System.Collections.Generic.List[string]]::new()
    $prefixEmpty = " " * 39    # Leerer Praefix fuer obere und untere Sparkline-Zeile

    for ($i = 0; $i -lt $counters.Count; $i++) {
        $c = $counters[$i]

        # 3-zeilige Sparkline fuer diesen Counter berechnen
        $sparkRows = Get-Sparkline3Row -Data $c.HistoricalData -MaxWidth $dynamicMaxWidth

        # Label-Text: "SRV-DB01 > CPU (%)" auf feste Breite gebracht
        $desc = "$($c.ComputerName) > $($c.Title) ($($c.Unit))".PadRight($labelWidth)
        # Aktueller Wert rechtsbuendig formatiert
        $valStr = if ($c.Statistics.ContainsKey('Current')) { $c.Statistics['Current'].ToString("F$($c.DecimalPlaces)").PadLeft(8) } else { " - " }

        # Zeile 1 (oben):  Nur Sparkline, kein Label (eingerueckt)
        $lines.Add($prefixEmpty + $sparkRows[0])
        # Zeile 2 (mitte): Label + Sparkline + aktueller Wert
        $lines.Add(" # $desc " + $sparkRows[1] + "  " + $valStr)
        # Zeile 3 (unten): Nur Sparkline, kein Label (eingerueckt)
        $lines.Add($prefixEmpty + $sparkRows[2])

        # Leerzeile zwischen den Countern (nicht nach dem letzten)
        if ($i -lt $counters.Count - 1) { $lines.Add("") }
    }

    # Alle Zeilen zu einem Gesamttext zusammenfuegen und ins Label schreiben
    $sparkLabel.Text = $lines -join "`n"
}

function Add-SimulatedData {
    # Erzeugt fuer jeden Counter einen neuen simulierten Datenpunkt.
    # CPU und Memory verwenden einen "Random Walk" (Zufallsbewegung basierend
    # auf dem letzten Wert), damit die Kurve realistisch aussieht.
    # Disk Read ist rein zufaellig.
    foreach ($c in $counters) {
        switch ($c.Title) {
            "CPU" {
                # Random Walk: Letzter Wert +/- 8, begrenzt auf 1-99%
                $last = if ($c.Statistics.ContainsKey('Current')) { [double]$c.Statistics['Current'] } else { 40.0 }
                $val = [Math]::Max(1, [Math]::Min(99, $last + (Get-Random -Minimum -8.0 -Maximum 8.0)))
            }
            "Available Memory" {
                # Random Walk: Letzter Wert +/- 80 MB, begrenzt auf 500-4000 MB
                $last = if ($c.Statistics.ContainsKey('Current')) { [double]$c.Statistics['Current'] } else { 2500.0 }
                $val = [Math]::Max(500, [Math]::Min(4000, $last + (Get-Random -Minimum -80.0 -Maximum 80.0)))
            }
            "Disk Read" {
                # Rein zufaellig (Disk I/O ist in der Realitaet auch sehr sprunghaft)
                $val = Get-Random -Minimum 0.1 -Maximum 60.0
            }
            default { $val = Get-Random -Minimum 1.0 -Maximum 100.0 }
        }
        # Neuen Datenpunkt hinzufuegen (aktualisiert auch Statistics)
        $c.AddDataPoint([Math]::Round($val, $c.DecimalPlaces))
    }
}

# ============================================================================
# SCHRITT 6: Event-Handler und Timer registrieren
# ============================================================================

# Button-Klick-Handler: Pause umschalten und Button-Text aendern
$btnPause.add_Clicked({ $script:isPaused = -not $script:isPaused; $btnPause.Text = if ($script:isPaused) { ">> Resume" } else { "|| Pause" }; Update-Header })

# Button-Klick-Handler: Sparklines ein-/ausschalten
$btnToggle.add_Clicked({ $script:showSparklines = -not $script:showSparklines; Update-Sparklines })

# Button-Klick-Handler: Anwendung beenden (RequestStop signalisiert der MainLoop aufzuhoeren)
$btnQuit.add_Clicked({ [Terminal.Gui.Application]::RequestStop() })

# Timer: Alle 2 Sekunden neue Daten simulieren und UI aktualisieren
# Der Callback gibt $true zurueck, damit der Timer weiterlaueft (bei $false wuerde er stoppen)
$timerCallback = [Func[Terminal.Gui.MainLoop, bool]]{ param($mainLoop); if ($script:isPaused) { return $true }; Add-SimulatedData; Update-Header; Update-Table; Update-Sparklines; return $true }
$null = [Terminal.Gui.Application]::MainLoop.AddTimeout([TimeSpan]::FromSeconds(2), $timerCallback)

# ============================================================================
# SCHRITT 7: Anwendung starten
# ============================================================================

# Einmaliges Update, damit sofort Daten sichtbar sind (nicht erst nach 2 Sekunden)
Update-Header; Update-Table; Update-Sparklines

# Fenster in die Anwendung einhaengen und die Hauptschleife starten
# Application::Run() blockiert, bis RequestStop() aufgerufen wird (ESC, Ctrl+Q oder Beenden-Button)
[Terminal.Gui.Application]::Top.Add($window)
[Terminal.Gui.Application]::Run()

# Nach dem Beenden: Terminal.Gui sauber herunterfahren (Terminal wiederherstellen)
[Terminal.Gui.Application]::Shutdown()
Write-Host "TUI beendet."
