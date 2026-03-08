# ============================================================================
# demo_tui.ps1 - Terminal UI Demo (Pure PowerShell + Terminal.Gui)
# ============================================================================
#
# ANSATZ: Wie PSTuiTools - Terminal.Gui wird DIREKT aus PowerShell benutzt.
#         Kein C# noetig! Die DLLs werden einfach geladen und dann
#         benutzt man die .NET Klassen wie normale PowerShell-Objekte.
#
# AUSFUEHREN:  pwsh -NoProfile -File demo_tui.ps1
# BEENDEN:     ESC druecken oder Ctrl+Q
# ============================================================================

#requires -Version 7.4

# ============================================================================
# SCHRITT 1: DLLs laden
# ============================================================================

$tuiLibDir = Join-Path $PSScriptRoot "..\..\src\psTerminalPerfCounter\psTerminalPerfCounter\Lib\TUI"
$tuiLibDir = (Resolve-Path $tuiLibDir).Path

$nstackDll     = Join-Path $tuiLibDir "NStack.dll"
$termGuiDll    = Join-Path $tuiLibDir "Terminal.Gui.dll"

if (-not (Test-Path $termGuiDll)) {
    Write-Error "Terminal.Gui.dll nicht gefunden in: $tuiLibDir"
    return
}

[System.Reflection.Assembly]::LoadFrom($nstackDll) | Out-Null
[System.Reflection.Assembly]::LoadFrom($termGuiDll) | Out-Null
Write-Host "Terminal.Gui geladen." -ForegroundColor Green

$pstpcDll = Join-Path $PSScriptRoot "..\..\src\psTerminalPerfCounter\psTerminalPerfCounter\Lib\psTPCCLASSES.dll"
if (Test-Path $pstpcDll) {
    Add-Type -Path (Resolve-Path $pstpcDll).Path
    Write-Host "psTPCCLASSES geladen." -ForegroundColor Green
} else {
    Write-Host "psTPCCLASSES.dll nicht gefunden, baue..." -ForegroundColor Yellow
    $buildDir = Join-Path $PSScriptRoot "..\..\src\lib\psTPCCLASSES"
    Push-Location $buildDir
    dotnet build -c Release 2>&1 | Out-Null
    Pop-Location
    Add-Type -Path (Join-Path $buildDir "bin\Release\net8.0\psTPCCLASSES.dll")
    Write-Host "psTPCCLASSES gebaut und geladen." -ForegroundColor Green
}

# ============================================================================
# SCHRITT 2: Fake-Counter mit ColorMap erstellen
# ============================================================================
#
# ColorMap = Schwellwert-basierte Farbzuordnung:
#   KeyValuePair<int, string>[] z.B. [{30,"Green"}, {70,"Yellow"}, {80,"Red"}]
#   Bedeutung: Wert < 30 = Green, < 70 = Yellow, < 80 = Red, >= 80 = Red (letzter)
#
# Das ist die gleiche Logik wie in Show-CounterTable.ps1
# ============================================================================

function New-FakeCounter {
    param(
        [string]$ComputerName,
        [string]$Title,
        [string]$Unit,
        [int]$DecimalPlaces = 1,
        [hashtable[]]$ColorMapDef   # z.B. @(@{Key=30;Value="Green"}, @{Key=70;Value="Yellow"}, @{Key=80;Value="Red"})
    )
    $counter = [System.Runtime.Serialization.FormatterServices]::GetUninitializedObject(
        [psTPCCLASSES.CounterConfiguration]
    )
    $counter.ComputerName     = $ComputerName
    $counter.Title            = $Title
    $counter.Unit             = $Unit
    $counter.DecimalPlaces    = $DecimalPlaces
    $counter.MaxHistoryPoints = 100
    $counter.HistoricalData   = [System.Collections.Generic.List[psTPCCLASSES.CounterConfiguration+DataPoint]]::new()
    $counter.Statistics       = [System.Collections.Generic.Dictionary[string, object]]::new()
    $counter.IsAvailable      = $true
    $counter.LastError        = ''

    # ColorMap setzen (private set -> Reflection noetig)
    if ($ColorMapDef) {
        $colorMapArray = $ColorMapDef | ForEach-Object {
            [System.Collections.Generic.KeyValuePair[int, string]]::new($_.Key, $_.Value)
        }
        $prop = [psTPCCLASSES.CounterConfiguration].GetProperty('ColorMap')
        $prop.SetValue($counter, [System.Collections.Generic.KeyValuePair[int, string][]]$colorMapArray)
    }

    return $counter
}

# CPU: < 30 = gruen, < 70 = gelb, >= 70 = rot
$cpuColors = @(
    @{ Key = 30;  Value = "Green" },
    @{ Key = 70;  Value = "Yellow" },
    @{ Key = 80;  Value = "Red" }
)

# Memory (Available): < 1000 = rot (wenig frei), < 2000 = gelb, >= 2000 = gruen (viel frei)
$memColors = @(
    @{ Key = 1000; Value = "Red" },
    @{ Key = 2000; Value = "Yellow" },
    @{ Key = 4000; Value = "Green" }
)

# Disk: < 20 = gruen, < 50 = gelb, >= 50 = rot
$diskColors = @(
    @{ Key = 20;  Value = "Green" },
    @{ Key = 50;  Value = "Yellow" },
    @{ Key = 80;  Value = "Red" }
)

$counters = [System.Collections.Generic.List[psTPCCLASSES.CounterConfiguration]]::new()
$counters.Add((New-FakeCounter -ComputerName "SRV-DB01"  -Title "CPU"              -Unit "%"    -DecimalPlaces 1 -ColorMapDef $cpuColors))
$counters.Add((New-FakeCounter -ComputerName "SRV-DB01"  -Title "Available Memory" -Unit "MB"   -DecimalPlaces 0 -ColorMapDef $memColors))
$counters.Add((New-FakeCounter -ComputerName "SRV-WEB01" -Title "CPU"              -Unit "%"    -DecimalPlaces 1 -ColorMapDef $cpuColors))
$counters.Add((New-FakeCounter -ComputerName "SRV-WEB01" -Title "Disk Read"        -Unit "MB/s" -DecimalPlaces 2 -ColorMapDef $diskColors))

# Anfangswerte
foreach ($c in $counters) {
    for ($i = 0; $i -lt 20; $i++) {
        switch ($c.Title) {
            "CPU"              { $val = Get-Random -Minimum 10.0 -Maximum 80.0 }
            "Available Memory" { $val = Get-Random -Minimum 1500.0 -Maximum 3500.0 }
            "Disk Read"        { $val = Get-Random -Minimum 0.5  -Maximum 50.0 }
            default            { $val = Get-Random -Minimum 1.0  -Maximum 100.0 }
        }
        $c.AddDataPoint([Math]::Round($val, $c.DecimalPlaces))
    }
}

Write-Host "$($counters.Count) Fake-Counter mit je 20 Datenpunkten erstellt." -ForegroundColor Green

# ============================================================================
# SCHRITT 3: Farb-Hilfsfunktionen
# ============================================================================
#
# Get-ValueColor: Gleiche Logik wie in Show-CounterTable.ps1
# Geht die ColorMap durch bis der Wert kleiner als der Schwellwert ist.
#
# Map-ColorToTermGui: Wandelt Farbnamen ("Green") in Terminal.Gui Farben um.
# ============================================================================

function Get-ValueColor {
    param($Value, $ColorMap)
    if ($null -eq $Value -or $Value -eq "-") { return "White" }
    foreach ($entry in $ColorMap) {
        if ([double]$Value -lt $entry.Key) { return $entry.Value }
    }
    return $ColorMap[-1].Value
}

# Mapping: String-Farbname -> Terminal.Gui.Color
$script:colorMapping = @{
    "Green"   = [Terminal.Gui.Color]::BrightGreen
    "Yellow"  = [Terminal.Gui.Color]::BrightYellow
    "Red"     = [Terminal.Gui.Color]::BrightRed
    "White"   = [Terminal.Gui.Color]::White
    "Cyan"    = [Terminal.Gui.Color]::BrightCyan
}

function Get-TermGuiColor {
    param([string]$ColorName)
    if ($script:colorMapping.ContainsKey($ColorName)) {
        return $script:colorMapping[$ColorName]
    }
    return [Terminal.Gui.Color]::White
}

# ============================================================================
# SCHRITT 4: Terminal.Gui initialisieren
# ============================================================================

[Terminal.Gui.Application]::Init()

$headerColors = [Terminal.Gui.ColorScheme]::new()
$headerColors.Normal = [Terminal.Gui.Attribute]::new(
    [Terminal.Gui.Color]::BrightCyan,
    [Terminal.Gui.Color]::Black
)

# ============================================================================
# SCHRITT 5: Layout aufbauen
# ============================================================================

# --- Hauptfenster ---
$window = [Terminal.Gui.Window]@{
    Title  = "psTerminalPerfCounter Monitor"
    X      = 0; Y = 0
    Width  = [Terminal.Gui.Dim]::Fill()
    Height = [Terminal.Gui.Dim]::Fill()
}

# --- Header (2 Zeilen) ---
$headerLabel = [Terminal.Gui.Label]@{
    X = 1; Y = 0
    Width       = [Terminal.Gui.Dim]::Fill(1)
    Height      = 2
    ColorScheme = $headerColors
}
$window.Add($headerLabel)

# --- Tabelle mit Last 5 Values ---
$tableFrame = [Terminal.Gui.FrameView]@{
    Title  = "Counter Uebersicht"
    X = 0; Y = 2
    Width  = [Terminal.Gui.Dim]::Fill()
    Height = [Terminal.Gui.Dim]::Percent(40)
}

$dataTable = [System.Data.DataTable]::new()
[void]$dataTable.Columns.Add("Computer",  [string])
[void]$dataTable.Columns.Add("Counter",   [string])
[void]$dataTable.Columns.Add("Unit",      [string])
[void]$dataTable.Columns.Add("Aktuell",   [string])
[void]$dataTable.Columns.Add("Last 5",    [string])
[void]$dataTable.Columns.Add("Min",       [string])
[void]$dataTable.Columns.Add("Max",       [string])
[void]$dataTable.Columns.Add("Avg",       [string])
[void]$dataTable.Columns.Add("Samples",   [string])

$tableView = [Terminal.Gui.TableView]@{
    X = 0; Y = 0
    Width         = [Terminal.Gui.Dim]::Fill()
    Height        = [Terminal.Gui.Dim]::Fill()
    FullRowSelect = $true
    Table         = $dataTable
}

# Fixed-Width Spalten
$columnStyles = @{
    "Computer" = [Terminal.Gui.ColumnStyle]@{ MinWidth = 12; MaxWidth = 12 }
    "Counter"  = [Terminal.Gui.ColumnStyle]@{ MinWidth = 18; MaxWidth = 18 }
    "Unit"     = [Terminal.Gui.ColumnStyle]@{ MinWidth = 6;  MaxWidth = 6  }
    "Aktuell"  = [Terminal.Gui.ColumnStyle]@{ MinWidth = 10; MaxWidth = 10 }
    "Last 5"   = [Terminal.Gui.ColumnStyle]@{ MinWidth = 40; MaxWidth = 40 }
    "Min"      = [Terminal.Gui.ColumnStyle]@{ MinWidth = 10; MaxWidth = 10 }
    "Max"      = [Terminal.Gui.ColumnStyle]@{ MinWidth = 10; MaxWidth = 10 }
    "Avg"      = [Terminal.Gui.ColumnStyle]@{ MinWidth = 10; MaxWidth = 10 }
    "Samples"  = [Terminal.Gui.ColumnStyle]@{ MinWidth = 8;  MaxWidth = 8  }
}

# ColorGetter fuer "Aktuell" Spalte:
# Liest den Wert + ColorMap des Counters und gibt das passende ColorScheme zurueck.
$aktuellStyle = $columnStyles["Aktuell"]
$aktuellStyle.ColorGetter = [Terminal.Gui.CellColorGetterDelegate]{
    param($cellArgs)
    $rowIdx = $cellArgs.RowIndex
    if ($rowIdx -ge 0 -and $rowIdx -lt $counters.Count) {
        $c = $counters[$rowIdx]
        if ($null -ne $c.ColorMap -and $c.Statistics.ContainsKey('Current')) {
            $colorName = Get-ValueColor -Value $c.Statistics['Current'] -ColorMap $c.ColorMap
            $fgColor = Get-TermGuiColor -ColorName $colorName
            $cs = [Terminal.Gui.ColorScheme]::new()
            $cs.Normal = [Terminal.Gui.Attribute]::new($fgColor, [Terminal.Gui.Color]::Black)
            return $cs
        }
    }
    return $null
}

foreach ($colName in $columnStyles.Keys) {
    $colIdx = $dataTable.Columns[$colName].Ordinal
    $tableView.Style.ColumnStyles[$colIdx] = $columnStyles[$colName]
}

$tableFrame.Add($tableView)
$window.Add($tableFrame)

# --- Sparklines (3 Zeilen pro Counter + Leerzeile) ---
$chartFrame = [Terminal.Gui.FrameView]@{
    Title  = "Sparklines (Live-Verlauf)"
    X = 0; Y = [Terminal.Gui.Pos]::Bottom($tableFrame)
    Width  = [Terminal.Gui.Dim]::Fill()
    Height = [Terminal.Gui.Dim]::Fill(3)
}

$sparkLabel = [Terminal.Gui.Label]@{
    X = 1; Y = 0
    Width  = [Terminal.Gui.Dim]::Fill(1)
    Height = [Terminal.Gui.Dim]::Fill()
}

$chartFrame.Add($sparkLabel)
$window.Add($chartFrame)

# --- Buttons ---
$btnPause = [Terminal.Gui.Button]@{
    Text = "|| Pause"
    X    = 1
    Y    = [Terminal.Gui.Pos]::Bottom($chartFrame)
}
$btnToggle = [Terminal.Gui.Button]@{
    Text = "Sparklines ein/aus"
    X    = [Terminal.Gui.Pos]::Right($btnPause) + 2
    Y    = [Terminal.Gui.Pos]::Bottom($chartFrame)
}
$btnQuit = [Terminal.Gui.Button]@{
    Text = "Beenden (ESC)"
    X    = [Terminal.Gui.Pos]::Right($btnToggle) + 2
    Y    = [Terminal.Gui.Pos]::Bottom($chartFrame)
}

$window.Add($btnPause)
$window.Add($btnToggle)
$window.Add($btnQuit)

# ============================================================================
# SCHRITT 6: Hilfsfunktionen fuer Updates
# ============================================================================

$seriesMarkers = @('█', '▓', '▒', '░', '■', '●', '▲', '◆')

$script:showSparklines = $true
$script:isPaused       = $false
$script:startTime      = Get-Date

function Update-Header {
    $sampleCount = if ($counters[0].HistoricalData.Count -gt 0) { $counters[0].HistoricalData.Count } else { 0 }
    $now   = Get-Date -Format "HH:mm:ss"
    $start = $script:startTime.ToString("dd.MM.yyyy HH:mm:ss")
    $paused = if ($script:isPaused) { "  [PAUSED]" } else { "" }

    $headerLabel.Text = " Session: $start  |  Intervall: 2s  |  Counter: $($counters.Count)  |  Samples: $sampleCount  |  Update: $now$paused"
}

function Update-Table {
    $dataTable.Rows.Clear()

    foreach ($c in $counters) {
        $stats = $c.Statistics
        $row = $dataTable.NewRow()

        $row["Computer"] = $c.ComputerName
        $row["Counter"]  = $c.Title
        $row["Unit"]     = $c.Unit
        $row["Aktuell"]  = if ($stats.ContainsKey('Current')) { $stats['Current'].ToString() } else { "-" }
        $row["Min"]      = if ($stats.ContainsKey('Minimum')) { $stats['Minimum'].ToString() } else { "-" }
        $row["Max"]      = if ($stats.ContainsKey('Maximum')) { $stats['Maximum'].ToString() } else { "-" }
        $row["Avg"]      = if ($stats.ContainsKey('Average')) { $stats['Average'].ToString() } else { "-" }
        $row["Samples"]  = if ($stats.ContainsKey('Count'))   { $stats['Count'].ToString()   } else { "0" }

        # Last 5 Values als String
        if ($stats.ContainsKey('Last5')) {
            $last5 = @($stats['Last5'])
            $row["Last 5"] = ($last5 | ForEach-Object { $_.ToString() }) -join "  |  "
        } else {
            $row["Last 5"] = "-"
        }

        [void]$dataTable.Rows.Add($row)
    }

    $tableView.Table = $dataTable
    $tableView.Update()
}

# ============================================================================
# 3-Zeilen Sparkline
# ============================================================================
#
# 3 Zeilen = 24 Stufen vertikale Aufloesung:
#   Stufe  0-8:  Nur untere Zeile
#   Stufe  8-16: Untere Zeile voll, mittlere Zeile
#   Stufe 16-24: Untere + mittlere voll, obere Zeile
#
# Layout pro Counter:
#   Zeile 1:            [obere Sparkline]
#   Zeile 2:  Label     [mittlere Sparkline]  Wert
#   Zeile 3:            [untere Sparkline]
#   Zeile 4:  (leer)
#
$sparkBlocks = @(' ', '▁', '▂', '▃', '▄', '▅', '▆', '▇', '█')  # 0-8

function Get-Sparkline3Row {
    param(
        [System.Collections.Generic.List[psTPCCLASSES.CounterConfiguration+DataPoint]]$Data,
        [int]$MaxWidth = 50
    )

    if ($Data.Count -eq 0) { return @("", "(keine Daten)", "") }

    $values = $Data |
        Select-Object -Last $MaxWidth |
        ForEach-Object { $_.Value }

    $min   = ($values | Measure-Object -Minimum).Minimum
    $max   = ($values | Measure-Object -Maximum).Maximum
    $range = $max - $min

    $topLine    = ""
    $midLine    = ""
    $bottomLine = ""

    foreach ($val in $values) {
        if ($range -eq 0) {
            $level = 12  # Mitte
        } else {
            $level = [int](($val - $min) / $range * 24)
            $level = [Math]::Max(0, [Math]::Min(24, $level))
        }

        if ($level -le 8) {
            # Nur untere Zeile
            $bottomLine += $sparkBlocks[$level]
            $midLine    += ' '
            $topLine    += ' '
        } elseif ($level -le 16) {
            # Untere voll, mittlere teilweise
            $bottomLine += '█'
            $midLine    += $sparkBlocks[$level - 8]
            $topLine    += ' '
        } else {
            # Untere + mittlere voll, obere teilweise
            $bottomLine += '█'
            $midLine    += '█'
            $topLine    += $sparkBlocks[$level - 16]
        }
    }
    return @($topLine, $midLine, $bottomLine)
}

function Update-Sparklines {
    if (-not $script:showSparklines) {
        $sparkLabel.Text = " (Sparklines ausgeblendet - Button druecken zum Einblenden)"
        return
    }

    # Maximale Breiten fuer saubere Ausrichtung
    $maxComputerLen = ($counters | ForEach-Object { $_.ComputerName.Length } | Measure-Object -Maximum).Maximum
    $maxTitleLen    = ($counters | ForEach-Object { $_.Title.Length } | Measure-Object -Maximum).Maximum
    $maxUnitLen     = ($counters | ForEach-Object { $_.Unit.Length } | Measure-Object -Maximum).Maximum

    # Gesamtbreite des Labels: "ComputerName - Title (Unit)"
    $labelWidth = $maxComputerLen + 3 + $maxTitleLen + 2 + $maxUnitLen + 1

    $lines = [System.Collections.Generic.List[string]]::new()

    for ($i = 0; $i -lt $counters.Count; $i++) {
        $c       = $counters[$i]
        $marker  = if ($i -lt $seriesMarkers.Count) { $seriesMarkers[$i] } else { "." }
        $current = if ($c.Statistics.ContainsKey('Current')) { $c.Statistics['Current'].ToString().PadLeft(8) } else { "       -" }

        # Farbname fuer aktuellen Wert (wird als Text-Hinweis angehangen)
        $colorName = if ($null -ne $c.ColorMap -and $c.Statistics.ContainsKey('Current')) {
            Get-ValueColor -Value $c.Statistics['Current'] -ColorMap $c.ColorMap
        } else { "" }
        $colorHint = if ($colorName) { " [$colorName]" } else { "" }

        # Label: Jeder Teil auf feste Breite gepadded
        $label = "$($c.ComputerName.PadRight($maxComputerLen)) - $($c.Title.PadRight($maxTitleLen)) ($($c.Unit.PadRight($maxUnitLen)))"

        # 3-Zeilen Sparkline
        $sparkRows = Get-Sparkline3Row -Data $c.HistoricalData -MaxWidth 50
        $indent = " " * ($labelWidth + 4)  # 4 = " M " (Marker + Spaces)

        # Zeile 1: Obere Sparkline (nur Graph, eingerueckt)
        $lines.Add("   $indent$($sparkRows[0])")
        # Zeile 2: Label + Mittlere Sparkline + Wert
        $lines.Add(" $marker $label $($sparkRows[1])  $current$colorHint")
        # Zeile 3: Untere Sparkline (nur Graph, eingerueckt)
        $lines.Add("   $indent$($sparkRows[2])")

        # Leerzeile zwischen Countern (nicht nach dem letzten)
        if ($i -lt $counters.Count - 1) {
            $lines.Add("")
        }
    }

    $sparkLabel.Text = $lines -join "`n"
}

function Add-SimulatedData {
    foreach ($c in $counters) {
        switch ($c.Title) {
            "CPU" {
                $last = if ($c.Statistics.ContainsKey('Current')) { [double]$c.Statistics['Current'] } else { 40.0 }
                $val = $last + (Get-Random -Minimum -8.0 -Maximum 8.0)
                $val = [Math]::Max(1, [Math]::Min(99, $val))
            }
            "Available Memory" {
                $last = if ($c.Statistics.ContainsKey('Current')) { [double]$c.Statistics['Current'] } else { 2500.0 }
                $val = $last + (Get-Random -Minimum -80.0 -Maximum 80.0)
                $val = [Math]::Max(500, [Math]::Min(4000, $val))
            }
            "Disk Read" {
                $val = Get-Random -Minimum 0.1 -Maximum 60.0
            }
            default {
                $val = Get-Random -Minimum 1.0 -Maximum 100.0
            }
        }
        $c.AddDataPoint([Math]::Round($val, $c.DecimalPlaces))
    }
}

# ============================================================================
# SCHRITT 7: Events verdrahten
# ============================================================================

$btnPause.add_Clicked({
    $script:isPaused = -not $script:isPaused
    if ($script:isPaused) {
        $btnPause.Text = ">> Resume"
    } else {
        $btnPause.Text = "|| Pause"
    }
    Update-Header
})

$btnToggle.add_Clicked({
    $script:showSparklines = -not $script:showSparklines
    Update-Sparklines
})

$btnQuit.add_Clicked({
    [Terminal.Gui.Application]::RequestStop()
})

# ============================================================================
# SCHRITT 8: Timer
# ============================================================================

$timerCallback = [Func[Terminal.Gui.MainLoop, bool]]{
    param($mainLoop)
    if ($script:isPaused) { return $true }

    Add-SimulatedData
    Update-Header
    Update-Table
    Update-Sparklines
    return $true
}

$null = [Terminal.Gui.Application]::MainLoop.AddTimeout(
    [TimeSpan]::FromSeconds(2),
    $timerCallback
)

# ============================================================================
# SCHRITT 9: Starten
# ============================================================================

Update-Header
Update-Table
Update-Sparklines

[Terminal.Gui.Application]::Top.Add($window)
[Terminal.Gui.Application]::Run()
[Terminal.Gui.Application]::Shutdown()

Write-Host ""
Write-Host "TUI beendet." -ForegroundColor Green
