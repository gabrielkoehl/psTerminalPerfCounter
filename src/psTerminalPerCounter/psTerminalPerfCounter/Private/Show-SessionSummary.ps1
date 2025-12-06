function Show-SessionSummary {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [CounterConfiguration[]]  $Counters
    )

    Write-Host "`n=== Session Summary ===" -ForegroundColor Cyan

    foreach ( $Counter in $Counters ) {

        if ( $Counter.Statistics.Count -gt 0 ) {
            $Stats = $Counter.Statistics
            Write-Host "$($Counter.Title):" -ForegroundColor Green
            Write-Host "  Samples: $($Stats.Count)" -ForegroundColor Gray
            Write-Host "  Min: $($Stats.Minimum) | Max: $($Stats.Maximum) | Avg: $($Stats.Average)" -ForegroundColor Gray
            Write-Host "  Last Value: $($Stats.Current)" -ForegroundColor Gray
        }

    }

    Write-Host ""
    Write-Host "Session completed successfully." -ForegroundColor Green

}