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

    $StatLine = "$Indent Current: $($Stats.Current) | Min: $($Stats.Minimum) | Max: $($Stats.Maximum) | Avg: $($Stats.Average)"
    Write-Host -ForegroundColor $StatColor -NoNewline $StatLine

    if ( $Stats.Last5.Count -gt 0 ) {

        Write-Host -ForegroundColor $StatColor -NoNewline " | Last 5: "

        foreach ( $currentValue in $Stats.Last5 ) {

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
