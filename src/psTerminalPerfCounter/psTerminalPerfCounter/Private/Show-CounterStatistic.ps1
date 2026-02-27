function Show-CounterStatistic {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [psTPCCLASSES.CounterConfiguration]$Counter
    )

    $Config             = $Counter.GraphConfiguration
    $colorMap           = $Counter.colorMap
    $Stats              = $Counter.Statistics
    $ExecutionTime      = $Counter.ExecutionDuration
    $Indent             = "  "
    $StatColor          = if ($null -ne $Config -and $null -ne $Config.Colors) { $Config.Colors.statistics } else { "Gray" }

    $current = if ($Stats.ContainsKey('Current')) { $Stats.Current } else { "-" }
    $min     = if ($Stats.ContainsKey('Minimum')) { $Stats.Minimum } else { "-" }
    $max     = if ($Stats.ContainsKey('Maximum')) { $Stats.Maximum } else { "-" }
    $avg     = if ($Stats.ContainsKey('Average')) { $Stats.Average } else { "-" }

    $StatLine = "$Indent Current: $current | Min: $min | Max: $max | Avg: $avg"
    Write-Host -ForegroundColor $StatColor -NoNewline $StatLine

    $last5Values = if ( $Stats.ContainsKey('Last5') ) { @($Stats.Last5) } else { @() }

    if ( $last5Values.Count -gt 0 ) {

        Write-Host -ForegroundColor $StatColor -NoNewline " | Last 5: "

        foreach ( $currentValue in $last5Values ) {

            $color = "White"

            foreach ( $entry in $Counter.ColorMap ) {
                if ( $currentValue -lt $entry.Key ) {
                    $color = $entry.Value
                    break
                }
            }

            if ( $color -eq "White" ) {
                $color = $Counter.ColorMap[-1].Value
            }

            Write-Host -ForegroundColor $color -NoNewline "$currentValue"
            Write-Host -ForegroundColor $StatColor -NoNewline " | "

        }

        if ( $Counter.isRemote ) { Write-Host " RT: $($ExecutionTime)ms" -ForegroundColor DarkGray }

        Write-Host ""

    }



}
