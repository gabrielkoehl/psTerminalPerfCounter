function Start-tpcMonitor {
    <#
    .SYNOPSIS
        Starts real-time performance counter monitoring using predefined configuration templates with language-independent counter IDs.

    .DESCRIPTION
        This function launches the main monitoring interface of the psTerminalPerfCounter module. It loads performance
        counter configurations from JSON templates, validates counter availability, and starts continuous real-time
        monitoring with configurable update intervals and data retention.

        The function uses the module's language-independent ID system to ensure configurations work across different
        system locales. It automatically filters unavailable counters and provides detailed feedback about monitoring status.
        Supports interactive monitoring with graphical displays, tables, and statistics based on configuration settings.

    .PARAMETER ConfigName
        Name of the configuration template to load (without 'tpc_' prefix and '.json' extension).
        Must correspond to a JSON file in the config directory (e.g., 'CPU' loads 'tpc_CPU.json').
        Default: 'CPU'
        Cannot be used together with ConfigPath parameter.

    .PARAMETER ConfigPath
        Absolute path to a specific JSON configuration file.
        The file must follow the naming convention 'tpc_*.json' and exist at the specified location.
        Cannot be used together with ConfigName parameter.

    .PARAMETER UpdateInterval
        Interval in seconds between performance counter updates and display refreshes.
        Lower values provide more responsive monitoring but increase system load.
        Graph time span = Samples (from JSON config) × UpdateInterval seconds.
        Default: 1 second

    .PARAMETER MaxHistoryPoints
        Maximum number of historical data points to retain in memory for each counter.
        This is the complete historical data used for statistics and future export.
        Independent of graph display width. Time span covered by graph display = Samples × UpdateInterval seconds.
        Default: 100 historical data points

    .EXAMPLE
        Start-tpcMonitor

        Starts monitoring using the default CPU configuration with 1-second updates and 100 historical data points.
        Graph displays 70 samples covering 70 seconds (70 samples × 1 second interval).

    .EXAMPLE
        Start-tpcMonitor -ConfigPath "C:\MyConfigs\tpc_CustomCPU.json"

        Starts monitoring using a custom configuration file from an absolute path.

    .EXAMPLE
        Start-tpcMonitor -ConfigName "Memory" -UpdateInterval 2

        Starts memory monitoring with 2-second update intervals using the 'tpc_Memory.json' configuration.

    .EXAMPLE
        Start-tpcMonitor -ConfigName "Disk" -UpdateInterval 1 -MaxHistoryPoints 200

        Starts disk monitoring with 1-second updates and extended data retention of 200 points.

    .OUTPUTS
        Interactive real-time monitoring display with configurable output formats:
        - Graphical plots (line, bar, scatter based on configuration)
        - Statistical summaries (min, max, average, current values)
        - Tabular data with formatted values and units
        - Session summary upon completion

    .NOTES
        Main entry point for the psTerminalPerfCounter monitoring system.
        Requires JSON configuration files in the module's config directory.
        Press Ctrl+C to stop monitoring and display session summary.
    #>

    [CmdletBinding(DefaultParameterSetName = 'ConfigName')]
    param(
        [Parameter(ParameterSetName = 'ConfigName')]
        [string]    $ConfigName     = "CPU",

        [Parameter(ParameterSetName = 'ConfigPath')]
        [string]    $ConfigPath,

        [Parameter(ParameterSetName = 'RemoteServerConfig')]
        [string]    $RemoteServerConfig,

        [int]       $UpdateInterval     = 1,
        [int]       $MaxHistoryPoints   = 100,
        [switch]    $visHTML
    )

    try {

        $config = @()

        if ( $PSCmdlet.ParameterSetName -eq 'ConfigPath' ) {

            if ( -not (Test-Path $ConfigPath) ) {
                Write-Warning "Configuration file not found: $ConfigPath"
                Return
            }

            $fileName = Split-Path $ConfigPath -Leaf
            if ( $fileName -notmatch '^tpc_.+\.json$' ) {
                Write-Warning "Invalid configuration file name. File must follow the pattern 'tpc_*.json'. Found: $fileName"
                Return
            }

            Write-Host "Loading configuration from '$ConfigPath'..." -ForegroundColor Yellow
            $Config = Get-CounterConfiguration -ConfigPath $ConfigPath

            foreach ( $counter in $Config.Counters ) {
                $counter.TestAvailability()
            }

        } elseif ( $PSCmdlet.ParameterSetName -eq 'ConfigName' ) {

            Write-Host "Loading configuration '$ConfigName'..." -ForegroundColor Yellow
            $Config = Get-CounterConfiguration -ConfigName $ConfigName

            foreach ( $counter in $Config.Counters ) {
                $counter.TestAvailability()
            }

        } elseif ( $PSCmdlet.ParameterSetName -eq 'RemoteServerConfig' ) {

            Write-Host "Loading remote server configuration from '$RemoteServerConfig'..." -ForegroundColor Yellow

            if ( -not (Test-Path $RemoteServerConfig) ) {
                Write-Warning "Server Configuration file not found: $RemoteServerConfig"
                Return
            }

            $Config = Get-ServerConfiguration -pathServerConfiguration $RemoteServerConfig

            if ( $Config.Servers.Count -eq 0 ) {
                Write-Warning "No valid servers found in remote server configuration '$RemoteServerConfig'"
                Return
            }

        } else {
            throw "Invalid parameter set. Use ConfigName, ConfigPath, or RemoteServerConfig."
        }

        # Validate remote server, server count, only one is allowed to be visualized in console, more go external
        if ( $PSCmdlet.ParameterSetName -eq 'RemoteServerConfig' ) {

            if ( -not $visHTML.IsPresent ) {

                if ( $Config.Servers.Count -gt 1 ) {

                    Write-Host "Multiple remote servers found. Please select which server to visualize in console:" -ForegroundColor Yellow
                    Write-Host ""

                    # Display server selection menu
                    Write-Host "[0] Abort monitoring" -ForegroundColor Red
                    for ( $i = 0; $i -lt $Config.Servers.Count; $i++ ) {
                        $server = $Config.Servers[$i]
                        Write-Host "[$($i + 1)] $($server.serverName) - $($server.serverComment)" -ForegroundColor Cyan
                    }
                    Write-Host ""

                    # Get user selection
                    do {
                        $selection      = Read-Host "Enter your choice (0 to abort, 1-$($Config.Servers.Count) to select server)"
                        $selectedIndex  = $null

                        if ( [int]::TryParse($selection, [ref]$selectedIndex) ) {

                            if ( $selectedIndex -eq 0 ) {
                                Write-Host "Monitoring aborted by user." -ForegroundColor Red
                                return
                            }

                            $selectedIndex = $selectedIndex - 1  # Convert to 0-based index
                            if ( $selectedIndex -ge 0 -and $selectedIndex -lt $Config.Servers.Count ) {
                                break
                            }

                        }

                        Write-Host "Invalid selection. Please enter 0 to abort or a number between 1 and $($Config.Servers.Count)." -ForegroundColor Red

                    } while ($true)

                    # Clean up config
                    $selectedServer = $Config.Servers[$selectedIndex]
                    $Config.Servers = @($selectedServer)

                    Write-Host "Selected server: $($selectedServer.serverName)" -ForegroundColor Green
                    Write-Host ""

                }

                # rebuild config for directly use local monitoring loop
                if ( $Config.Servers.Count -eq 1) {

                    $config = @{
                        Name        = "$($Config.Servers[0].PerformanceCounters[0].Name) - REMOTE $($Config.Servers[0].serverName)" # currently only one key ( counter configuration ) is supported
                        Description = "Remote monitoring of $($Config.Servers[0].serverName)"
                        ConfigPath  = "REMOTE CONFIG"
                        Counters    = $Config.Servers[0].PerformanceCounters[0].Counters
                    }

                    foreach ( $counter in $Config.Counters ) {
                        $counter.TestAvailability()
                    }

                }
            }



        }

        # Start monitoring
        $MonitoringParams = @{
            Config         = $Config
            UpdateInterval = $UpdateInterval
            MaxDataPoints  = $MaxHistoryPoints
        }

        Start-MonitoringLoop @MonitoringParams

    } catch [System.Management.Automation.HaltCommandException] {

        Write-Host "`n=== Monitoring stopped by user ===" -ForegroundColor Green

    } catch {

        Write-Host "`n=== ERROR ===" -ForegroundColor Red
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Yellow
        throw

    } finally {

        if ( $PSCmdlet.ParameterSetName -in @('ConfigName', 'ConfigPath') ) {

            if ( $availabilityResult.Success -eq $true ) {
                Show-SessionSummary -Counters $config.Counters
            }

        }

    }

}