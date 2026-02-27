function Start-MonitoringLoop {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]    $monitorType,
        [Parameter(Mandatory=$true)]
        [psobject]  $Config,
        [Parameter(Mandatory=$true)]
        [int]       $UpdateInterval
    )

    $SampleCount    = 0
    $StartTime      = Get-Date


    if ( $monitorType -in @('local','remoteSingle') ) {

        while ( $true ) {

            $SampleCount++

            # Collect data from all counters
            [psTPCCLASSES.CounterConfiguration]::GetValuesBatched($Config.Counters)


            Show-SessionHeader -ConfigName $Config.Name -StartTime $StartTime -SampleCount $SampleCount

            # Separate counters by format
            $graphCounters = [System.Collections.Generic.List[object]]::new()
            $tableCounters = [System.Collections.Generic.List[object]]::new()

            foreach ( $Counter in $Config.Counters ) {
                if ( $Counter.HistoricalData.Count -gt 3 ) {  # Need some data points
                    switch ($Counter.Format) {
                        "graph" { $graphCounters.Add($Counter) }
                        "table" { $tableCounters.Add($Counter) }
                        "both"  {
                                $graphCounters.Add($Counter)
                                $tableCounters.Add($Counter)
                        }
                        default { $tableCounters.Add($Counter) }  # Default to table
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
                    Show-CounterTable -Counters $tableCounters -MonitorType $monitorType
                } catch {
                    Write-Host "Table display error: $($_.Exception.Message)" -ForegroundColor Red
                    Write-Host ""
                }
            }

            Start-Sleep -Seconds $UpdateInterval

        }

    } elseif ( $monitorType -eq 'environment' ) {

        while ( $true ) {

            $SampleCount++

            $Config.GetAllValuesBatched()

            # Clear screen
            Clear-Host

            # Show header with environment info
            Write-Host "=== $($Config.Name) ===" -ForegroundColor Cyan
            Write-Host "Sample: $SampleCount | Started: $($StartTime.ToString('HH:mm:ss')) | Query Time: $($Config.QueryTimestamp.ToString('HH:mm:ss.fff')) | Duration: $($Config.QueryDuration)ms" -ForegroundColor Gray
            Write-Host ""

            # Collect all counters from all servers for display
            $allCounters = [System.Collections.Generic.List[object]]::new()

            foreach ( $server in $Config.Servers ) {
                if ( $server.IsAvailable ) {
                    foreach ( $counter in $server.Counters ) {
                        if ( $counter.IsAvailable -and $counter.HistoricalData.Count -gt 0 ) {
                            $allCounters.Add($counter)
                        }
                    }
                }
            }

            # Display table with all counters from all servers
            if ( $allCounters.Count -gt 0 ) {
                try {
                    Show-CounterTable -Counters $allCounters -MonitorType 'environment'
                } catch {
                    Write-Host "Table display error: $($_.Exception.Message)" -ForegroundColor Red
                    Write-Host ""
                }
            } else {
                Write-Host "No data available from any server." -ForegroundColor Yellow
            }

            # Show environment statistics
            Write-Host ""
            Write-Host "Environment Statistics:" -ForegroundColor Cyan
            $stats = $Config.GetEnvironmentStatistics()
            Write-Host "  Total Servers: $($stats['TotalServers']) | Available: $($stats['AvailableServers'])" -ForegroundColor White
            Write-Host "  Total Counters: $($stats['TotalCounters']) | Available: $($stats['AvailableCounters'])" -ForegroundColor White
            Write-Host "  Last Query: $($stats['LastQueryTimestamp']) | Duration: $($stats['LastQueryDuration']) | Interval: $($stats['Interval'])" -ForegroundColor White

            Start-Sleep -Seconds $UpdateInterval
        }

    }

}