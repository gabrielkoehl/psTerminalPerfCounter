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
Write-Host "Terminal.Gui geladen."

$pstpcDll = Join-Path $PSScriptRoot "..\..\src\psTerminalPerfCounter\psTerminalPerfCounter\Lib\psTPCCLASSES.dll"
if (Test-Path $pstpcDll) {
    Add-Type -Path (Resolve-Path $pstpcDll).Path
    Write-Host "psTPCCLASSES geladen."
} else {
    Write-Host "psTPCCLASSES.dll nicht gefunden, baue..."
    $buildDir = Join-Path $PSScriptRoot "..\..\src\lib\psTPCCLASSES"
    Push-Location $buildDir
    dotnet build -c Release 2>&1 | Out-Null
    Pop-Location
    Add-Type -Path (Join-Path $buildDir "bin\Release\net8.0\psTPCCLASSES.dll")
    Write-Host "psTPCCLASSES gebaut und geladen."
}

# ============================================================================
# SCHRITT 2: Fake-Counter erstellen
# ============================================================================

function New-FakeCounter {
    param([string]$ComputerName, [string]$Title, [string]$Unit, [int]$DecimalPlaces = 1)
    $counter = [System.Runtime.Serialization.FormatterServices]::GetUninitializedObject([psTPCCLASSES.CounterConfiguration])
    $counter.ComputerName     = $ComputerName
    $counter.Title            = $Title
    $counter.Unit             = $Unit
    $counter.DecimalPlaces    = $DecimalPlaces
    $counter.MaxHistoryPoints = 100
    $counter.HistoricalData   = [System.Collections.Generic.List[psTPCCLASSES.CounterConfiguration+DataPoint]]::new()
    $counter.Statistics       = [System.Collections.Generic.Dictionary[string, object]]::new()
    $counter.IsAvailable      = $true
    $counter.LastError        = ''
    return $counter
}

$counters = [System.Collections.Generic.List[psTPCCLASSES.CounterConfiguration]]::new()
$counters.Add((New-FakeCounter -ComputerName "SRV-DB01"  -Title "CPU"              -Unit "%"    -DecimalPlaces 1))
$counters.Add((New-FakeCounter -ComputerName "SRV-DB01"  -Title "Available Memory" -Unit "MB"   -DecimalPlaces 0))
$counters.Add((New-FakeCounter -ComputerName "SRV-WEB01" -Title "CPU"              -Unit "%"    -DecimalPlaces 1))
$counters.Add((New-FakeCounter -ComputerName "SRV-WEB01" -Title "Disk Read"        -Unit "MB/s" -DecimalPlaces 2))

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
Write-Host "$($counters.Count) Fake-Counter mit je 20 Datenpunkten erstellt."

# ============================================================================
# SCHRITT 3: Hilfsfunktionen für Textausrichtung
# ============================================================================

function Format-Cell {
    param([string]$Text, [int]$Width, [switch]$Left)
    $inner = if ($Left) { $Text.PadRight($Width) } else { $Text.PadLeft($Width) }
    return " $inner "
}

function Format-Center {
    param([string]$Text, [int]$Width)
    if ($Text.Length -ge $Width) { return $Text.Substring(0, $Width) }
    $leftPad = [int][Math]::Floor(($Width - $Text.Length) / 2.0)
    $rightPad = $Width - $Text.Length - $leftPad
    return (" " * $leftPad) + $Text + (" " * $rightPad)
}

# ============================================================================
# SCHRITT 4: Terminal.Gui initialisieren & Layout
# ============================================================================

[Terminal.Gui.Application]::Init()

$window = [Terminal.Gui.Window]@{ Title = "psTerminalPerfCounter Monitor"; Width = [Terminal.Gui.Dim]::Fill(); Height = [Terminal.Gui.Dim]::Fill() }
$headerLabel = [Terminal.Gui.Label]@{ X = 1; Y = 0; Width = [Terminal.Gui.Dim]::Fill(1); Height = 2 }
$window.Add($headerLabel)

$tableFrame = [Terminal.Gui.FrameView]@{ Title = "Counter Uebersicht"; X = 0; Y = 2; Width = [Terminal.Gui.Dim]::Fill(); Height = [Terminal.Gui.Dim]::Percent(40) }

# Spaltennamen direkt zentriert anlegen, um zentrierte Header zu erzwingen
$script:colNames = @{
    Computer = Format-Center "Computer" 14
    Counter  = Format-Center "Counter" 20
    Unit     = Format-Center "Unit" 8
    Aktuell  = Format-Center "Aktuell" 12
    Last5    = Format-Center "Last 5" 44
    Min      = Format-Center "Min" 12
    Max      = Format-Center "Max" 12
    Avg      = Format-Center "Avg" 12
    Samples  = Format-Center "Samples" 10
}

$dataTable = [System.Data.DataTable]::new()
[void]$dataTable.Columns.Add($script:colNames.Computer, [string])
[void]$dataTable.Columns.Add($script:colNames.Counter,  [string])
[void]$dataTable.Columns.Add($script:colNames.Unit,     [string])
[void]$dataTable.Columns.Add($script:colNames.Aktuell,  [string])
[void]$dataTable.Columns.Add($script:colNames.Last5,    [string])
[void]$dataTable.Columns.Add($script:colNames.Min,      [string])
[void]$dataTable.Columns.Add($script:colNames.Max,      [string])
[void]$dataTable.Columns.Add($script:colNames.Avg,      [string])
[void]$dataTable.Columns.Add($script:colNames.Samples,  [string])

$tableView = [Terminal.Gui.TableView]@{ X = 0; Y = 0; Width = [Terminal.Gui.Dim]::Fill(); Height = [Terminal.Gui.Dim]::Fill(); FullRowSelect = $true; Table = $dataTable }

$columnStyles = @{
    $script:colNames.Computer = [Terminal.Gui.TableView+ColumnStyle]@{ MinWidth = 14; MaxWidth = 14 }
    $script:colNames.Counter  = [Terminal.Gui.TableView+ColumnStyle]@{ MinWidth = 20; MaxWidth = 20 }
    $script:colNames.Unit     = [Terminal.Gui.TableView+ColumnStyle]@{ MinWidth = 8;  MaxWidth = 8  }
    $script:colNames.Aktuell  = [Terminal.Gui.TableView+ColumnStyle]@{ MinWidth = 12; MaxWidth = 12 }
    $script:colNames.Last5    = [Terminal.Gui.TableView+ColumnStyle]@{ MinWidth = 44; MaxWidth = 44 }
    $script:colNames.Min      = [Terminal.Gui.TableView+ColumnStyle]@{ MinWidth = 12; MaxWidth = 12 }
    $script:colNames.Max      = [Terminal.Gui.TableView+ColumnStyle]@{ MinWidth = 12; MaxWidth = 12 }
    $script:colNames.Avg      = [Terminal.Gui.TableView+ColumnStyle]@{ MinWidth = 12; MaxWidth = 12 }
    $script:colNames.Samples  = [Terminal.Gui.TableView+ColumnStyle]@{ MinWidth = 10; MaxWidth = 10 }
}

foreach ($colName in $columnStyles.Keys) {
    $colIdx = $dataTable.Columns[$colName].Ordinal
    $tableView.Style.ColumnStyles[$colIdx] = $columnStyles[$colName]
}

$tableFrame.Add($tableView)
$window.Add($tableFrame)

$chartFrame = [Terminal.Gui.FrameView]@{ Title = "Sparklines (Live-Verlauf)"; X = 0; Y = [Terminal.Gui.Pos]::Bottom($tableFrame); Width = [Terminal.Gui.Dim]::Fill(); Height = [Terminal.Gui.Dim]::Fill(3) }
$sparkLabel = [Terminal.Gui.Label]@{ X = 1; Y = 0; Width = [Terminal.Gui.Dim]::Fill(1); Height = [Terminal.Gui.Dim]::Fill() }
$chartFrame.Add($sparkLabel)
$window.Add($chartFrame)

$btnPause  = [Terminal.Gui.Button]@{ Text = "|| Pause"; X = 1; Y = [Terminal.Gui.Pos]::Bottom($chartFrame) }
$btnToggle = [Terminal.Gui.Button]@{ Text = "Sparklines ein/aus"; X = [Terminal.Gui.Pos]::Right($btnPause) + 2; Y = [Terminal.Gui.Pos]::Bottom($chartFrame) }
$btnQuit   = [Terminal.Gui.Button]@{ Text = "Beenden (ESC)"; X = [Terminal.Gui.Pos]::Right($btnToggle) + 2; Y = [Terminal.Gui.Pos]::Bottom($chartFrame) }

$window.Add($btnPause); $window.Add($btnToggle); $window.Add($btnQuit)

# ============================================================================
# SCHRITT 5: Logik
# ============================================================================

$script:showSparklines = $true; $script:isPaused = $false; $script:startTime = Get-Date

function Update-Header {
    $sampleCount = if ($counters[0].HistoricalData.Count -gt 0) { $counters[0].HistoricalData.Count } else { 0 }
    $now = Get-Date -Format "HH:mm:ss"
    $paused = if ($script:isPaused) { "  [PAUSED]" } else { "" }
    $headerLabel.Text = " Session: $($script:startTime.ToString('dd.MM.yyyy HH:mm:ss'))  |  Intervall: 2s  |  Counter: $($counters.Count)  |  Samples: $sampleCount  |  Update: $now$paused"
}

function Update-Table {
    $dataTable.Rows.Clear()
    foreach ($c in $counters) {
        $stats = $c.Statistics
        $row = $dataTable.NewRow()
        $row[$script:colNames.Computer] = Format-Cell $c.ComputerName 12 -Left
        $row[$script:colNames.Counter]  = Format-Cell $c.Title 18 -Left
        $row[$script:colNames.Unit]     = Format-Cell $c.Unit 6
        $row[$script:colNames.Aktuell]  = Format-Cell $(if ($stats.ContainsKey('Current')) { $stats['Current'].ToString("F$($c.DecimalPlaces)") } else { "-" }) 10
        $row[$script:colNames.Min]      = Format-Cell $(if ($stats.ContainsKey('Minimum')) { $stats['Minimum'].ToString("F1") } else { "-" }) 10
        $row[$script:colNames.Max]      = Format-Cell $(if ($stats.ContainsKey('Maximum')) { $stats['Maximum'].ToString("F1") } else { "-" }) 10
        $row[$script:colNames.Avg]      = Format-Cell $(if ($stats.ContainsKey('Average')) { $stats['Average'].ToString("F1") } else { "-" }) 10
        $row[$script:colNames.Samples]  = Format-Cell $(if ($stats.ContainsKey('Count'))   { $stats['Count'].ToString() } else { "0" }) 8

        if ($stats.ContainsKey('Last5')) {
            $formattedLast5 = @($stats['Last5'] | ForEach-Object { $_.ToString().PadLeft(6) }) -join " | "
            $row[$script:colNames.Last5] = " $formattedLast5 "
        } else {
            $row[$script:colNames.Last5] = " - "
        }
        [void]$dataTable.Rows.Add($row)
    }
    $tableView.Update()
}

# Unicode Block-Definition. Explizit hexadezimal, um Copy-Paste-Fehler zu vermeiden.


$script:sparkBlocks = @(
    [char]0x00A0,   # 0: Leerzeichen
    [char]0x2581,   # 1: 1/8 Block
    [char]0x2582,   # 2: 2/8 Block
    [char]0x2583,   # 3: 3/8 Block
    [char]0x2584,   # 4: 4/8 Block
    [char]0x2585,   # 5: 5/8 Block
    [char]0x2586,   # 6: 6/8 Block
    [char]0x2587,   # 7: 7/8 Block
    [char]0x2588    # 8: Voller Block
)


function Get-Sparkline3Row {
    param([System.Collections.Generic.List[psTPCCLASSES.CounterConfiguration+DataPoint]]$Data, [int]$MaxWidth = 60)

    if ($Data.Count -eq 0) {
        $empty = " " * $MaxWidth
        return @($empty, $empty, $empty)
    }

    $values = $Data | Select-Object -Last $MaxWidth | ForEach-Object { $_.Value }
    $min = ($values | Measure-Object -Minimum).Minimum
    $max = ($values | Measure-Object -Maximum).Maximum
    $range = $max - $min

    $topLine = ""; $midLine = ""; $bottomLine = ""

    # Graphenbreite starr halten: Rechtsbündig auffüllen
    $padCount = $MaxWidth - $values.Count
    if ($padCount -gt 0) {
        $padStr = " " * $padCount
        $topLine += $padStr; $midLine += $padStr; $bottomLine += $padStr
    }

    foreach ($val in $values) {
        # Level 0-23: maps to 3 rows × 8 blocks
        $level = if ($range -gt 0) {
            [int][Math]::Floor((($val - $min) / $range) * 23.999)
        } else {
            12
        }
        $level = [Math]::Clamp($level, 0, 23)

        if ($level -ge 16) {
            $bottomIdx = 8
            $midIdx    = 8
            $topIdx    = $level - 16 + 1   # 1-8
        } elseif ($level -ge 8) {
            $bottomIdx = 8
            $midIdx    = $level - 8 + 1    # 1-8
            $topIdx    = 0
        } else {
            $bottomIdx = $level + 1        # 1-8
            $midIdx    = 0
            $topIdx    = 0
        }

        $bottomLine += $script:sparkBlocks[$bottomIdx]
        $midLine    += $script:sparkBlocks[$midIdx]
        $topLine    += $script:sparkBlocks[$topIdx]
    }

    return @($topLine, $midLine, $bottomLine)
}

function Update-Sparklines {
    if (-not $script:showSparklines) { $sparkLabel.Text = " [Sparklines deaktiviert]"; return }
    $lines = [System.Collections.Generic.List[string]]::new()
    $labelWidth = 35

    for ($i = 0; $i -lt $counters.Count; $i++) {
        $c = $counters[$i]
        $sparkRows = Get-Sparkline3Row -Data $c.HistoricalData -MaxWidth 60
        $desc = "$($c.ComputerName) > $($c.Title) ($($c.Unit))".PadRight($labelWidth)
        $valStr = if ($c.Statistics.ContainsKey('Current')) { $c.Statistics['Current'].ToString("F$($c.DecimalPlaces)").PadLeft(8) } else { " - " }

        $lines.Add((" " * ($labelWidth + 3)) + $sparkRows[0])
        $lines.Add(" # $desc " + $sparkRows[1] + "  " + $valStr)
        $lines.Add((" " * ($labelWidth + 3)) + $sparkRows[2])
        if ($i -lt $counters.Count - 1) { $lines.Add("") }
    }
    $sparkLabel.Text = $lines -join "`n"
}

function Add-SimulatedData {
    foreach ($c in $counters) {
        switch ($c.Title) {
            "CPU" { $last = if ($c.Statistics.ContainsKey('Current')) { [double]$c.Statistics['Current'] } else { 40.0 }; $val = [Math]::Max(1, [Math]::Min(99, $last + (Get-Random -Minimum -8.0 -Maximum 8.0))) }
            "Available Memory" { $last = if ($c.Statistics.ContainsKey('Current')) { [double]$c.Statistics['Current'] } else { 2500.0 }; $val = [Math]::Max(500, [Math]::Min(4000, $last + (Get-Random -Minimum -80.0 -Maximum 80.0))) }
            "Disk Read" { $val = Get-Random -Minimum 0.1 -Maximum 60.0 }
            default { $val = Get-Random -Minimum 1.0 -Maximum 100.0 }
        }
        $c.AddDataPoint([Math]::Round($val, $c.DecimalPlaces))
    }
}

$btnPause.add_Clicked({ $script:isPaused = -not $script:isPaused; $btnPause.Text = if ($script:isPaused) { ">> Resume" } else { "|| Pause" }; Update-Header })
$btnToggle.add_Clicked({ $script:showSparklines = -not $script:showSparklines; Update-Sparklines })
$btnQuit.add_Clicked({ [Terminal.Gui.Application]::RequestStop() })

$timerCallback = [Func[Terminal.Gui.MainLoop, bool]]{ param($mainLoop); if ($script:isPaused) { return $true }; Add-SimulatedData; Update-Header; Update-Table; Update-Sparklines; return $true }
$null = [Terminal.Gui.Application]::MainLoop.AddTimeout([TimeSpan]::FromSeconds(2), $timerCallback)

Update-Header; Update-Table; Update-Sparklines
[Terminal.Gui.Application]::Top.Add($window)
[Terminal.Gui.Application]::Run()
[Terminal.Gui.Application]::Shutdown()
Write-Host "TUI beendet."