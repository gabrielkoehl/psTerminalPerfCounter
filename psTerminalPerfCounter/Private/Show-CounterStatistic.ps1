function Show-CounterStatistic {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [PerformanceCounter]$Counter
    )

    $Config             = $Counter.GraphConfiguration
    $colorMap           = $Counter.colorMap
    $Stats              = $Counter.Statistics
    $Indent             = "  "
    $StatLine           = ""

    $colorMapOrdered = [ordered]@{}
    $colorMap.Keys | Sort-Object | ForEach-Object {
        $colorMapOrdered.add($_, $colorMap[$_])
    }

    $StatLine = "$Indent Current: $($Stats.Current) | Min: $($Stats.Minimum) | Max: $($Stats.Maximum) | Avg: $($Stats.Average)"
    Write-Host -ForegroundColor $Config.Colors.Statistics -NoNewline $StatLine

    if ( $Stats.Last5.Count -gt 0 ) {

        Write-Host -ForegroundColor $Config.Colors.Statistics -NoNewline " | Last 5: "

        foreach ( $currentValue in $Stats.Last5 ) {

            $color = for ( $b = 0; $b -lt $colorMapOrdered.Count; $b++ ) {
                $bound = $colorMapOrdered.Keys[$b]
                if ( $currentValue -lt $bound ) {
                    $colorMapOrdered[$b]
                    break
                }
            }

            if ( [string]::IsNullOrEmpty($color) ) {
                $color = $colorMapOrdered[-1]
            }

            Write-Host -ForegroundColor $color -NoNewline "$currentValue"
            Write-Host -ForegroundColor $Config.Colors.Statistics -NoNewline " | "

        }

        Write-Host ""

    }



}
