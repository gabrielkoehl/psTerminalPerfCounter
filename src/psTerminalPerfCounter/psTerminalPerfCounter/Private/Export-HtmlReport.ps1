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
        [int] $UpdateInterval
    )

    # PSWriteHTML is a soft dependency - only required when -ExportHtml is used
    if (-not (Get-Module -Name PSWriteHTML -ListAvailable)) {
        throw "PSWriteHTML module is required for HTML export. Install it with: Install-Module PSWriteHTML"
    }
    Import-Module PSWriteHTML -ErrorAction Stop

    # PSWriteHTML scriptblocks run in their own scope, so data must live in $script: scope
    $script:psTPC_html_colors      = @('#007acc', '#ff6b35', '#4caf50', '#ff9800', '#9c27b0', '#e91e63', '#00bcd4', '#795548')
    $script:psTPC_html_active      = @($Counters | Where-Object { $_.IsAvailable -and $_.HistoricalData.Count -gt 0 })
    $script:psTPC_html_configName  = $ConfigName
    $script:psTPC_html_startTime   = $StartTime
    $script:psTPC_html_sample      = $SampleCount
    $script:psTPC_html_interval    = $UpdateInterval
    $script:psTPC_html_lastUpdate  = Get-Date -Format 'HH:mm:ss'

    # Overview table - identical columns to TUI table
    $script:psTPC_html_overview = foreach ($c in $script:psTPC_html_active) {
        $stats = $c.Statistics
        [PSCustomObject]@{
            'Computer'   = $c.ComputerName
            'Counter'    = $c.Title
            'Unit'       = $c.Unit
            'Current'    = if ($stats.ContainsKey('Current'))  { $stats['Current'] }  else { '-' }
            'Min'        = if ($stats.ContainsKey('Minimum'))  { $stats['Minimum'] }  else { '-' }
            'Max'        = if ($stats.ContainsKey('Maximum'))  { $stats['Maximum'] }  else { '-' }
            'Avg'        = if ($stats.ContainsKey('Average'))  { $stats['Average'] }  else { '-' }
            'ExecTime'   = if ($null -ne $c.LastUpdate)        { $c.LastUpdate.ToString('HH:mm:ss') } else { '-' }
            'Dur.ms'     = if ($null -ne $c.ExecutionDuration) { $c.ExecutionDuration } else { '-' }
            'Samples'    = $c.HistoricalData.Count
        }
    }

    # Combined chart - all counters together
    $script:psTPC_html_labels = @()
    $script:psTPC_html_series = @()

    if ($script:psTPC_html_active.Count -gt 0) {
        $script:psTPC_html_labels = @($script:psTPC_html_active[0].HistoricalData | ForEach-Object { $_.Timestamp.ToString('HH:mm:ss') })

        $colorIdx = 0
        $script:psTPC_html_series = @(foreach ($c in $script:psTPC_html_active) {
            [PSCustomObject]@{
                Name   = "$($c.ComputerName) - $($c.Title) ($($c.Unit))"
                Values = @($c.HistoricalData | ForEach-Object { $_.Value })
                Color  = $script:psTPC_html_colors[$colorIdx % $script:psTPC_html_colors.Count]
            }
            $colorIdx++
        })
    }

    New-HTML -TitleText "psTerminalPerfCounter - $script:psTPC_html_configName" -FilePath $HtmlFilePath -ShowHTML:$false {

        # ── Header ──────────────────────────────────────────────────────────────
        New-HTMLSection -HeaderText "Session: $script:psTPC_html_configName" -HeaderBackGroundColor DarkSlateGray {
            New-HTMLPanel {
                New-HTMLTag -Tag 'div' -Attributes @{ style = 'display:flex;justify-content:space-between;align-items:flex-start' } -Value {
                    New-HTMLTag -Tag 'div' -Value {
                        New-HTMLText -Text @(
                            "Started: $($script:psTPC_html_startTime.ToString('dd.MM.yyyy HH:mm:ss'))"
                            "Sample: $script:psTPC_html_sample"
                            "Interval: $($script:psTPC_html_interval)s"
                            "Last Update: $script:psTPC_html_lastUpdate"
                        ) -FontSize 14 -Color White -LineBreak
                    }
                }
                New-HTMLTag -Tag 'div' -Attributes @{ style = 'display:flex;align-items:center;gap:10px;margin:10px 0;flex-wrap:wrap' } -Value {
                    New-HTMLTag -Tag 'button' -Attributes @{
                        style   = 'padding:8px 16px;font-size:14px;cursor:pointer;background:#007acc;color:white;border:none;border-radius:4px'
                        onclick = 'location.reload()'
                    } -Value { 'Refresh' }
                    New-HTMLTag -Tag 'select' -Attributes @{
                        id       = 'arSelect'
                        style    = 'padding:8px 12px;font-size:14px;border-radius:4px;border:1px solid #ccc;cursor:pointer'
                        onchange = 'setAR(this.value)'
                    } -Value {
                        New-HTMLTag -Tag 'option' -Attributes @{ value = '0'  } -Value { 'Auto-Refresh: Off' }
                        New-HTMLTag -Tag 'option' -Attributes @{ value = '5'  } -Value { '5 Seconds'  }
                        New-HTMLTag -Tag 'option' -Attributes @{ value = '10' } -Value { '10 Seconds' }
                        New-HTMLTag -Tag 'option' -Attributes @{ value = '15' } -Value { '15 Seconds' }
                        New-HTMLTag -Tag 'option' -Attributes @{ value = '30' } -Value { '30 Seconds' }
                        New-HTMLTag -Tag 'option' -Attributes @{ value = '60' } -Value { '60 Seconds' }
                    }
                    New-HTMLTag -Tag 'span' -Attributes @{ id = 'arStatus'; style = 'font-size:13px;color:#888' } -Value { '' }
                }
                New-HTMLTag -Tag 'script' -Value {
@'
var LS=localStorage;
function setAR(v){LS.setItem('psTPC_ar',v);if(v>0){document.getElementById('arStatus').textContent='Refresh in '+v+'s';setTimeout(function(){location.reload()},v*1000)}else{document.getElementById('arStatus').textContent=''}}
var savedAR=LS.getItem('psTPC_ar');if(savedAR&&savedAR>0){document.getElementById('arSelect').value=savedAR;setAR(savedAR)}
'@
                }
            }
        }

        # ── Overview Table (mirrors TUI table) ───────────────────────────────────
        New-HTMLSection -HeaderText "Counter Overview" {
            New-HTMLTable -DataTable $script:psTPC_html_overview -HideFooter -ScrollX {
                New-TableCondition -Name 'Samples' -ComparisonType number -Operator lt -Value 5 -BackgroundColor Orange -Color White
            }
        }

        if ($script:psTPC_html_active.Count -gt 0) {

            # ── Combined chart - all counters ────────────────────────────────────
            New-HTMLSection -HeaderText "All Counters" {
                New-HTMLChart {
                    New-ChartAxisX -Name $script:psTPC_html_labels
                    foreach ($s in $script:psTPC_html_series) {
                        New-ChartLine -Name $s.Name -Value $s.Values -Color $s.Color
                    }
                }
            }

            # ── Individual chart per counter ─────────────────────────────────────
            for ($script:psTPC_html_idx = 0; $script:psTPC_html_idx -lt $script:psTPC_html_active.Count; $script:psTPC_html_idx++) {
                $script:psTPC_html_c      = $script:psTPC_html_active[$script:psTPC_html_idx]
                $script:psTPC_html_cTitle = "$($script:psTPC_html_c.ComputerName) - $($script:psTPC_html_c.Title) ($($script:psTPC_html_c.Unit))"
                $script:psTPC_html_cColor = $script:psTPC_html_colors[$script:psTPC_html_idx % $script:psTPC_html_colors.Count]
                $script:psTPC_html_cLbls  = @($script:psTPC_html_c.HistoricalData | ForEach-Object { $_.Timestamp.ToString('HH:mm:ss') })
                $script:psTPC_html_cVals  = @($script:psTPC_html_c.HistoricalData | ForEach-Object { $_.Value })

                New-HTMLSection -HeaderText $script:psTPC_html_cTitle {
                    New-HTMLChart {
                        New-ChartAxisX -Name $script:psTPC_html_cLbls
                        New-ChartLine -Name $script:psTPC_html_cTitle -Value $script:psTPC_html_cVals -Color $script:psTPC_html_cColor
                    }
                }
            }
        }

    } -Online

}
