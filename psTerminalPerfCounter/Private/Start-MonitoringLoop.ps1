function Start-MonitoringLoop {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [PerformanceCounter[]]  $Counters,
        [Parameter(Mandatory=$true)]
        [hashtable]             $Config,
        [Parameter(Mandatory=$true)]
        [int]                   $UpdateInterval,
        [Parameter(Mandatory=$true)]
        [int]                   $MaxDataPoints
    )

    $SampleCount    = 0
    $StartTime      = Get-Date

    while ( $true ) {

        $SampleCount++

        # Collect data from all counters
        foreach ( $Counter in $Counters ) {

            try {
                $Value = $Counter.GetCurrentValue()
                $Counter.AddDataPoint($Value, $MaxDataPoints)
            } catch {
                Write-Warning "Error reading counter '$($Counter.Title)': $($_.Exception.Message)"
            }

        }

        Show-SessionHeader -ConfigName $Config.Name -StartTime $StartTime -SampleCount $SampleCount

        # Separate counters by format
        $graphCounters = @()
        $tableCounters = @()

        foreach ( $Counter in $Counters ) {
            if ( $Counter.HistoricalData.Count -gt 3 ) {  # Need some data points
                switch ($Counter.Format) {
                    "graph" { $graphCounters += $Counter }
                    "table" { $tableCounters += $Counter }
                    "both"  {
                              $graphCounters += $Counter
                              $tableCounters += $Counter
                    }
                    default { $graphCounters += $Counter }  # Default to graph
                }
            } else {
                Write-Host "$($Counter.GetFormattedTitle()): Collecting data... ($($Counter.HistoricalData.Count)/3 samples)" -ForegroundColor Yellow
                Write-Host ""
            }
        }

        # Show graphs first
        foreach ( $Counter in $graphCounters ) {
            try {
                Show-CounterGraph -Counter $Counter
            } catch {
                Write-Host "$($Counter.Title) Graph error: $($_.Exception.Message)" -ForegroundColor Red
                Write-Host ""
            }
        }

        # Show table if there are any table counters
        if ( $tableCounters.Count -gt 0 ) {
            try {
                Show-CounterTable -Counters $tableCounters
            } catch {
                Write-Host "Table display error: $($_.Exception.Message)" -ForegroundColor Red
                Write-Host ""
            }
        }

        Start-Sleep -Seconds $UpdateInterval

    }

}