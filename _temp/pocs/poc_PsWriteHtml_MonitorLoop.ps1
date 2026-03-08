<#

Das funktioniert grundsaetzlich, aber gefaellt mir nicht. Steif, das permanente reloading unterbricht den visuellen Fluss
Ich komme auch auch nicht auf den Ajax HTML Kram klar. Ich werde das mit erst mit Vibe Coding loesen und mich dann
einarbeiten in den Code

JSON export war auch unnoetig

#>

# POC Code


# PSWriteHTML Report - direkt aus Counter-Objekten (kein JSON-Umweg fuer Chart)
$htmlPath = Join-Path ([Environment]::GetFolderPath('Desktop')) 'psTPC_report.html'
$script:chartColors = @('#007acc', '#ff6b35', '#4caf50', '#ff9800', '#9c27b0', '#e91e63', '#00bcd4', '#795548')


$activeCounters = @($Config.Counters | Where-Object { $_.IsAvailable -and $_.HistoricalData.Count -gt 0 })

$overviewData = foreach ( $c in $activeCounters ) {
    $vals = @($c.HistoricalData | ForEach-Object { $_.Value })
    [PSCustomObject]@{
        Computer     = $c.ComputerName
        Counter      = $c.Title
        Unit         = $c.Unit
        Aktuell      = $vals[-1]
        Min          = ($vals | Measure-Object -Minimum).Minimum
        Max          = ($vals | Measure-Object -Maximum).Maximum
        Durchschnitt = [Math]::Round(($vals | Measure-Object -Average).Average, 2)
        Samples      = $vals.Count
    }
}

# Chart-Daten vorbereiten (script scope fuer Zugriff in PSWriteHTML ScriptBlocks)
$script:chartLabels = @()
$script:chartSeries = @()

if ( $activeCounters.Count -gt 0 ) {
    $script:chartLabels = @($activeCounters[0].HistoricalData | ForEach-Object { $_.Timestamp.ToString("HH:mm:ss") })

    $colorIndex = 0
    $script:chartSeries = foreach ( $c in $activeCounters ) {
        [PSCustomObject]@{
            Name   = "$($c.ComputerName) - $($c.Title) ($($c.Unit))"
            Values = @($c.HistoricalData | ForEach-Object { $_.Value })
            Color  = $script:chartColors[$colorIndex % $script:chartColors.Count]
        }
        $colorIndex++
    }
    $script:chartSeries = @($script:chartSeries)
}

New-HTML -TitleText "psTerminalPerfCounter - $($Config.Name)" -FilePath $htmlPath -ShowHTML:($SampleCount -eq 1) {

    # Header + Logo + Refresh Button
    New-HTMLSection -HeaderText "Session: $($Config.Name)" -HeaderBackGroundColor DarkSlateGray {
        New-HTMLPanel {
            New-HTMLTag -Tag 'div' -Attributes @{ style = 'display:flex;justify-content:space-between;align-items:flex-start' } -Value {
                New-HTMLTag -Tag 'div' -Value {
                    New-HTMLText -Text @(
                        "Started: $($StartTime.ToString('dd.MM.yyyy HH:mm:ss'))"
                        "Sample: $SampleCount"
                        "Interval: ${UpdateInterval}s"
                        "Last Update: $(Get-Date -Format 'HH:mm:ss')"
                    ) -FontSize 14 -Color White -LineBreak
                }
                if ( $script:logoDataUri ) {
                    New-HTMLTag -Tag 'img' -Attributes @{ src = $script:logoDataUri; style = 'height:60px;opacity:0.9' } -SelfClosing
                }
            }
            New-HTMLTag -Tag 'div' -Attributes @{ style = 'display:flex;align-items:center;gap:10px;margin:10px 0;flex-wrap:wrap' } -Value {
                New-HTMLTag -Tag 'button' -Attributes @{ style = 'padding:8px 16px;font-size:14px;cursor:pointer;background:#007acc;color:white;border:none;border-radius:4px'; onclick = 'location.reload()' } -Value { 'Refresh' }
                New-HTMLTag -Tag 'select' -Attributes @{ id = 'arSelect'; style = 'padding:8px 12px;font-size:14px;border-radius:4px;border:1px solid #ccc;cursor:pointer'; onchange = 'setAR(this.value)' } -Value {
                    New-HTMLTag -Tag 'option' -Attributes @{ value = '0' } -Value { 'Auto-Refresh: Aus' }
                    New-HTMLTag -Tag 'option' -Attributes @{ value = '5' } -Value { '5 Sekunden' }
                    New-HTMLTag -Tag 'option' -Attributes @{ value = '10' } -Value { '10 Sekunden' }
                    New-HTMLTag -Tag 'option' -Attributes @{ value = '15' } -Value { '15 Sekunden' }
                    New-HTMLTag -Tag 'option' -Attributes @{ value = '30' } -Value { '30 Sekunden' }
                    New-HTMLTag -Tag 'option' -Attributes @{ value = '60' } -Value { '60 Sekunden' }
                }
                New-HTMLTag -Tag 'span' -Attributes @{ id = 'arStatus'; style = 'font-size:13px;color:#888' } -Value { '' }
            }
            New-HTMLTag -Tag 'script' -Value {
@"
var LS=localStorage;function getCharts(){return Apex._chartInstances||[]}
function setAR(v){LS.setItem('psTPC_ar',v);if(v>0){document.getElementById('arStatus').textContent='Refresh alle '+v+'s';setTimeout(function(){location.reload()},v*1000)}else{document.getElementById('arStatus').textContent=''}}
function toggleSeries(){var on=LS.getItem('psTPC_seriesHidden')==='1';LS.setItem('psTPC_seriesHidden',on?'0':'1');getCharts().forEach(function(c){c.chart.w.globals.seriesNames.forEach(function(n){on?c.chart.showSeries(n):c.chart.hideSeries(n)})});document.getElementById('toggleSeriesBtn').textContent=on?'Serien ausblenden':'Serien anzeigen'}
function toggleValues(){var on=LS.getItem('psTPC_valuesOn')==='1';LS.setItem('psTPC_valuesOn',on?'0':'1');getCharts().forEach(function(c){c.chart.updateOptions({dataLabels:{enabled:!on}})});document.getElementById('toggleValuesBtn').textContent=on?'Werte anzeigen':'Werte ausblenden'}
function toggleToolbar(){var on=LS.getItem('psTPC_toolbarOn')==='1';LS.setItem('psTPC_toolbarOn',on?'0':'1');getCharts().forEach(function(c){c.chart.updateOptions({chart:{toolbar:{show:!on}}})});document.getElementById('toggleToolbarBtn').textContent=on?'Toolbar anzeigen':'Toolbar ausblenden'}
function toggleZoom(){var on=LS.getItem('psTPC_zoomOn')==='1';LS.setItem('psTPC_zoomOn',on?'0':'1');getCharts().forEach(function(c){c.chart.updateOptions({chart:{zoom:{enabled:!on}}})});document.getElementById('toggleZoomBtn').textContent=on?'Zoom aktivieren':'Zoom deaktivieren'}
function applyState(){var sH=LS.getItem('psTPC_seriesHidden')==='1';var vOn=LS.getItem('psTPC_valuesOn')==='1';var tOn=LS.getItem('psTPC_toolbarOn')==='1';var zOn=LS.getItem('psTPC_zoomOn')==='1';getCharts().forEach(function(c){c.chart.updateOptions({chart:{animations:{enabled:false},toolbar:{show:tOn},zoom:{enabled:zOn}},tooltip:{animation:{duration:0}},dataLabels:{enabled:vOn}})});if(sH){getCharts().forEach(function(c){c.chart.w.globals.seriesNames.forEach(function(n){c.chart.hideSeries(n)})});document.getElementById('toggleSeriesBtn').textContent='Serien anzeigen'}if(vOn){document.getElementById('toggleValuesBtn').textContent='Werte ausblenden'}if(tOn){document.getElementById('toggleToolbarBtn').textContent='Toolbar ausblenden'}if(zOn){document.getElementById('toggleZoomBtn').textContent='Zoom deaktivieren'}}
var savedAR=LS.getItem('psTPC_ar');if(savedAR&&savedAR>0){document.getElementById('arSelect').value=savedAR;setAR(savedAR)}
document.addEventListener('DOMContentLoaded',function(){setTimeout(applyState,100)})
"@
            }
        }
    }

    # Overview Table
    New-HTMLSection -HeaderText "Counter Uebersicht" {
        New-HTMLTable -DataTable $overviewData -HideFooter -ScrollX {
            New-TableCondition -Name 'Samples' -ComparisonType number -Operator lt -Value 5 -BackgroundColor Orange -Color White
        }
    }

    # alle Counter
    New-HTMLSection -HeaderText "Performance Counter" {
        New-HTMLChart {
            New-ChartAxisX -Name $script:chartLabels
            foreach ( $s in $script:chartSeries ) {
                New-ChartLine -Name $s.Name -Value $s.Values -Color $s.Color
            }
        }
        New-HTMLTag -Tag 'div' -Attributes @{ style = 'display:flex;align-items:center;gap:10px;margin:10px 0;flex-wrap:wrap' } -Value {
            New-HTMLTag -Tag 'button' -Attributes @{ id = 'toggleSeriesBtn'; style = 'padding:8px 16px;font-size:13px;cursor:pointer;background:#4caf50;color:white;border:none;border-radius:4px'; onclick = 'toggleSeries()' } -Value { 'Serien ausblenden' }
            New-HTMLTag -Tag 'button' -Attributes @{ id = 'toggleValuesBtn'; style = 'padding:8px 16px;font-size:13px;cursor:pointer;background:#ff9800;color:white;border:none;border-radius:4px'; onclick = 'toggleValues()' } -Value { 'Werte anzeigen' }
            New-HTMLTag -Tag 'button' -Attributes @{ id = 'toggleToolbarBtn'; style = 'padding:8px 16px;font-size:13px;cursor:pointer;background:#795548;color:white;border:none;border-radius:4px'; onclick = 'toggleToolbar()' } -Value { 'Toolbar anzeigen' }
            New-HTMLTag -Tag 'button' -Attributes @{ id = 'toggleZoomBtn'; style = 'padding:8px 16px;font-size:13px;cursor:pointer;background:#9c27b0;color:white;border:none;border-radius:4px'; onclick = 'toggleZoom()' } -Value { 'Zoom aktivieren' }
        }
    }
} -Online
