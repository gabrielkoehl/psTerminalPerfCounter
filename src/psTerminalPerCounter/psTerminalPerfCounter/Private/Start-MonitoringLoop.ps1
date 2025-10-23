function Start-MonitoringLoop {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]    $monitorType,
        [Parameter(Mandatory=$true)]
        [psobject]  $Config,
        [Parameter(Mandatory=$true)]
        [int]       $UpdateInterval,
        [Parameter(Mandatory=$true)]
        [int]       $MaxDataPoints
    )

    begin {

        $SampleCount    = 0
        $StartTime      = Get-Date

    }

    process {

        if ( $monitorType -in @('local','remoteSingle') ) {

            while ( $true ) {

            $SampleCount++

            # Collect data from all counters
            foreach ( $Counter in $Config.Counters ) {

                try {
                    if ( $Counter.IsAvailable ) {
                        $return                     = $Counter.GetCurrentValue()
                        $value                      = $return[0]
                        $Counter.ExecutionDuration  = $return[1]
                        $Counter.AddDataPoint($Value, $MaxDataPoints)
                    } else {
                        Write-Warning "Counter '$($Counter.Title)' is not available: $($Counter.LastError)"
                        Start-Sleep -Milliseconds 500 # Clear-Host is to fast to read anything
                    }
                } catch {
                    Write-Warning "Error reading counter '$($Counter.Title)': $($_.Exception.Message)"
                    Pause # Clear-Host is to fast to read anything
                }

            }

            Show-SessionHeader -ConfigName $Config.Name -StartTime $StartTime -SampleCount $SampleCount

            # Separate counters by format
            $graphCounters = @()
            $tableCounters = @()

            foreach ( $Counter in $Config.Counters ) {
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
                    Show-CounterTable -Counters $tableCounters -MonitorType $monitorType
                } catch {
                    Write-Host "Table display error: $($_.Exception.Message)" -ForegroundColor Red
                    Write-Host ""
                }
            }

            Start-Sleep -Seconds $UpdateInterval

            }

        } elseif ( $monitorType -eq 'remoteMulti' ) {

            while ( $true ) {

                $SampleCount++

                # Collect all counters from all servers
                $allCounters = @()

                foreach ( $server in $Config.Servers ) {
                    foreach ( $counterConfig in $server.PerformanceCounters ) {
                        foreach ( $counter in $counterConfig.Counters ) {

                            try {
                                if ( $counter.IsAvailable ) {
                                    $return                     = $counter.GetCurrentValue()
                                    $value                      = $return[0]
                                    $counter.ExecutionDuration  = $return[1]
                                    $counter.AddDataPoint($Value, $MaxDataPoints)

                                    $allCounters += $counter
                                } else {
                                    Write-Warning "Counter '$($counter.Title)' on $($counter.ComputerName) is not available: $($counter.LastError)"
                                    Start-Sleep -Milliseconds 500
                                }
                            } catch {
                                Write-Warning "Error reading counter '$($counter.Title)' on $($counter.ComputerName): $($_.Exception.Message)"
                            }
                        }
                    }
                }

                # Clear screen and show data
                Clear-Host
                Show-SessionHeader -ConfigName $Config.Name -StartTime $StartTime -SampleCount $SampleCount

                # Display table with all counters from all servers
                if ( $allCounters.Count -gt 0 ) {
                    try {
                        Show-CounterTable -Counters $allCounters -MonitorType $monitorType
                    } catch {
                        Write-Host "Table display error: $($_.Exception.Message)" -ForegroundColor Red
                        Write-Host ""
                    }
                } else {
                    Write-Host "No data available from any server." -ForegroundColor Yellow
                }

                Start-Sleep -Seconds $UpdateInterval
            }

        }

    }

    end {

    }

}