function Export-HtmlReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Counters,

        [Parameter(Mandatory)]
        [string] $ConfigName,

        [Parameter(Mandatory)]
        [string] $HtmlFilePath,

        [Parameter(Mandatory)]
        [DateTime] $StartTime,

        [Parameter(Mandatory)]
        [int] $SampleCount,

        [Parameter(Mandatory)]
        [int] $UpdateInterval,

        [ValidateSet('Counter', 'Host')]
        [string] $GroupBy = 'Counter'
    )

    if (-not (Get-Module -Name PSWriteHTML -ListAvailable)) {
        throw "PSWriteHTML module is required for HTML export. Install it with: Install-Module PSWriteHTML"
    }
    Import-Module PSWriteHTML -ErrorAction Stop

    # ── Pre-compute all data before entering New-HTML ─────────────────────────
    # PSWriteHTML invokes scriptblocks in module scope, so all data must be in $script:

    $script:psTPC_html_colors     = @('#007acc', '#ff6b35', '#4caf50', '#ff9800', '#9c27b0', '#e91e63', '#00bcd4', '#795548')
    $script:psTPC_html_active     = @($Counters | Where-Object { $_.IsAvailable -and $_.HistoricalData.Count -gt 0 })
    $script:psTPC_html_configName = $ConfigName
    $script:psTPC_html_startTime  = $StartTime
    $script:psTPC_html_sample     = $SampleCount
    $script:psTPC_html_interval   = $UpdateInterval
    $script:psTPC_html_lastUpdate = Get-Date -Format 'HH:mm:ss'

    # Overview table — same columns as TUI table
    $script:psTPC_html_overview = foreach ($c in $script:psTPC_html_active) {
        $stats = $c.Statistics
        [PSCustomObject]@{
            'Computer' = $c.ComputerName
            'Counter'  = $c.Title
            'Unit'     = $c.Unit
            'Current'  = if ($stats.ContainsKey('Current'))  { $stats['Current'] }  else { '-' }
            'Min'      = if ($stats.ContainsKey('Minimum'))  { $stats['Minimum'] }  else { '-' }
            'Max'      = if ($stats.ContainsKey('Maximum'))  { $stats['Maximum'] }  else { '-' }
            'Avg'      = if ($stats.ContainsKey('Average'))  { $stats['Average'] }  else { '-' }
            'ExecTime' = if ($null -ne $c.LastUpdate)        { $c.LastUpdate.ToString('HH:mm:ss') } else { '-' }
            'Dur.ms'   = if ($null -ne $c.ExecutionDuration) { $c.ExecutionDuration } else { '-' }
            'Samples'  = $c.HistoricalData.Count
        }
    }

    # Combined chart — all counters, all hosts
    $script:psTPC_html_allLabels = @()
    $script:psTPC_html_allSeries = @()

    if ($script:psTPC_html_active.Count -gt 0) {
        $script:psTPC_html_allLabels = @($script:psTPC_html_active[0].HistoricalData |
            ForEach-Object { $_.Timestamp.ToString('HH:mm:ss') })

        $ci = 0
        $script:psTPC_html_allSeries = @(foreach ($c in $script:psTPC_html_active) {
            [PSCustomObject]@{
                Name   = "$($c.ComputerName) - $($c.Title) ($($c.Unit))"
                Values = @($c.HistoricalData | ForEach-Object { $_.Value })
                Color  = $script:psTPC_html_colors[$ci % $script:psTPC_html_colors.Count]
            }
            $ci++
        })
    }

    # Grouped chart data
    # GroupBy=Counter → one tab per counter type, series = one per host
    # GroupBy=Host    → one tab per host, series = one per counter
    $grouping = if ($GroupBy -eq 'Counter') {
        $script:psTPC_html_active | Group-Object -Property Title
    } else {
        $script:psTPC_html_active | Group-Object -Property ComputerName
    }

    $script:psTPC_html_groups = @(foreach ($g in $grouping) {
        $gCounters = @($g.Group)
        $gLabels   = @($gCounters[0].HistoricalData | ForEach-Object { $_.Timestamp.ToString('HH:mm:ss') })
        $ci2 = 0
        $gSeries = @(foreach ($gc in $gCounters) {
            $sName = if ($GroupBy -eq 'Counter') {
                $gc.ComputerName
            } else {
                "$($gc.Title) ($($gc.Unit))"
            }
            [PSCustomObject]@{
                Name   = $sName
                Values = @($gc.HistoricalData | ForEach-Object { $_.Value })
                Color  = $script:psTPC_html_colors[$ci2 % $script:psTPC_html_colors.Count]
            }
            $ci2++
        })
        [PSCustomObject]@{
            Name   = $g.Name
            Labels = $gLabels
            Series = $gSeries
        }
    })

    # ── HTML ──────────────────────────────────────────────────────────────────
    New-HTML -TitleText "psTerminalPerfCounter - $script:psTPC_html_configName" -FilePath $HtmlFilePath -ShowHTML:$false {

        New-HTMLSection -HeaderText "Session: $script:psTPC_html_configName" -HeaderBackGroundColor DarkSlateGray {
            New-HTMLPanel {
                New-HTMLText -Text @(
                    "Started: $($script:psTPC_html_startTime.ToString('dd.MM.yyyy HH:mm:ss'))"
                    "Sample: $script:psTPC_html_sample"
                    "Interval: $($script:psTPC_html_interval)s"
                    "Last Update: $script:psTPC_html_lastUpdate"
                ) -FontSize 14 -Color White -LineBreak
            }
        }

        New-HTMLTabPanel {

            # ── Tab: Overview table ───────────────────────────────────────────
            New-HTMLTab -Name "Overview" -IconSolid "table" {
                New-HTMLSection -HeaderText "Counter Overview" {
                    New-HTMLTable -DataTable $script:psTPC_html_overview -HideFooter -ScrollX {
                        New-TableCondition -Name 'Samples' -ComparisonType number -Operator lt -Value 5 `
                            -BackgroundColor Orange -Color White
                    }
                }
            }

            # ── Tab: All counters combined ────────────────────────────────────
            New-HTMLTab -Name "All Counters" -IconSolid "chart-line" {
                New-HTMLSection -HeaderText "All Counters" {
                    New-HTMLChart {
                        New-ChartAxisX -Name $script:psTPC_html_allLabels
                        foreach ($s in $script:psTPC_html_allSeries) {
                            New-ChartLine -Name $s.Name -Value $s.Values -Color $s.Color
                        }
                    }
                }
            }

            # ── Tab per group (Counter or Host) ───────────────────────────────
            # PSWriteHTML executes scriptblocks synchronously (builder pattern),
            # so $script:psTPC_html_gd is captured correctly each iteration.
            for ($script:psTPC_html_gi = 0; $script:psTPC_html_gi -lt $script:psTPC_html_groups.Count; $script:psTPC_html_gi++) {
                $script:psTPC_html_gd = $script:psTPC_html_groups[$script:psTPC_html_gi]

                New-HTMLTab -Name $script:psTPC_html_gd.Name {
                    New-HTMLSection -HeaderText $script:psTPC_html_gd.Name {
                        New-HTMLChart {
                            New-ChartAxisX -Name $script:psTPC_html_gd.Labels
                            foreach ($s in $script:psTPC_html_gd.Series) {
                                New-ChartLine -Name $s.Name -Value $s.Values -Color $s.Color
                            }
                        }
                    }
                }
            }
        }

    } -Online

}
