function Start-tpcEnvironmentMonitor {
    <#
    .SYNOPSIS
        Starts real-time performance counter monitoring for multiple remote servers in parallel

    .DESCRIPTION
        This function launches environment-level monitoring across multiple servers.
        It loads an environment configuration from JSON (containing multiple servers),
        queries all servers and their counters IN PARALLEL, and displays results in a table format.

        Key features:
        - Parallel querying: All servers are queried simultaneously
        - Within each server: All counters are queried in parallel
        - Common timestamp: All data points share the same timestamp
        - Performance tracking: Total query duration is measured

        The function uses async/await pattern internally for maximum performance.

    .PARAMETER ConfigPath
        Absolute path to the environment JSON configuration file.
        Example: "_remoteconfigs\AD_SERVER_001.json"

        JSON structure:
        {
            "name": "SQL_ENVIRONMENT_001",
            "description": "SQL Server Production Environment",
            "interval": 2,
            "servers": [
                {
                    "computername": "DEV-DC",
                    "comment": "Domain Controller",
                    "counterConfig": ["CPU"]
                }
            ]
        }

    .PARAMETER UpdateInterval
        Interval in seconds between performance counter updates and display refreshes.
        Lower values provide more responsive monitoring but increase system load.
        Default: Uses interval from JSON configuration (or 2 seconds if not specified)

    .PARAMETER ProgressAction
        Common parameter to control the display of progress bars. (PowerShell 7.4+)

    .EXAMPLE
        Start-tpcEnvironmentMonitor -ConfigPath "_remoteconfigs\AD_SERVER_001.json"

        Starts monitoring using the default interval from JSON configuration.
        Queries all servers in parallel every 2 seconds (or as configured).

    .EXAMPLE
        Start-tpcEnvironmentMonitor -ConfigPath "C:\Configs\SQL_PROD.json" -UpdateInterval 5

        Starts monitoring with 5-second update intervals (overrides JSON interval).

    .OUTPUTS
        Interactive real-time monitoring display with:
        - Tabular data showing all servers and their counters
        - Common timestamp for all measurements
        - Query duration in milliseconds
        - Statistical summaries (min, max, average, current values)

    .NOTES
        Environment monitoring entry point for multi-server scenarios.

        Requirements:
        - JSON configuration file with server definitions
        - Network connectivity to all target systems
        - Appropriate permissions for remote performance counter access
        - Windows Remote Management (WinRM) enabled on target systems

        Performance characteristics:
        - 3 servers with 2 counters each (6 total) queries in ~1-2 seconds
        - All servers and counters run in parallel (not sequentially)

        Press Ctrl+C to stop monitoring and display session summary.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string] $EnvConfigPath,

        [Parameter()]
        [int] $UpdateInterval = 0  # 0 = use from config
    )

    $environment = $null

    try {

        # Load environment configuration
        Write-Host "Loading environment configuration from '$ConfigPath'..." -ForegroundColor Yellow

        $environment = Get-EnvironmentConfiguration -EnvConfigPath $EnvConfigPath
        if ( -not $environment ) {
            Write-Warning "Failed to load environment configuration"
            Return
        }

        # Determine update interval (parameter overrides config)
        $effectiveInterval = if ( $UpdateInterval -gt 0 ) {
            $UpdateInterval
        } else {
            if ( $environment.Interval -gt 0 ) {
                $environment.Interval
            } else {
                2  # Fallback default
            }
        }

        Write-Host ""
        Write-Host "=== Environment Monitoring ===" -ForegroundColor Cyan
        Write-Host "Environment   : $($environment.Name)" -ForegroundColor White
        Write-Host "Description   : $($environment.Description)" -ForegroundColor White
        Write-Host "Servers       : $($environment.Servers.Count)" -ForegroundColor White
        Write-Host "Update Interval: $effectiveInterval second(s)" -ForegroundColor White
        Write-Host ""

        # Display server overview
        Write-Host "Servers in environment:" -ForegroundColor Cyan
        foreach ( $server in $environment.Servers ) {
            $status = if ($server.IsAvailable) { "Available" } else { "Unavailable - $($server.LastError)" }
            $statusColor = if ($server.IsAvailable) { "Green" } else { "Red" }
            Write-Host "  [$status] $($server.ComputerName) - $($server.Comment) ($($server.Counters.Count) counter(s))" -ForegroundColor $statusColor
        }
        Write-Host ""

        # Start monitoring loop
        $MonitoringParams = @{
            MonitorType     = 'environment'
            Config          = $environment
            UpdateInterval  = $effectiveInterval
        }

        Start-MonitoringLoop @MonitoringParams

    } catch [System.Management.Automation.HaltCommandException] {

        Write-Host "`n=== Monitoring stopped by user ===" -ForegroundColor Green

    } catch {

        Write-Host "`n=== ERROR ===" -ForegroundColor Red
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Yellow
        throw

    } finally {

        # Display summary if environment was loaded
        if ( $environment ) {

            Write-Host ""
            Write-Host "=== Environment Monitoring Summary ===" -ForegroundColor Cyan
            Write-Host "Environment     : $($environment.Name)" -ForegroundColor White
            Write-Host "Last Query Time : $($environment.QueryTimestamp)" -ForegroundColor White
            Write-Host "Last Query Duration: $($environment.QueryDuration)ms" -ForegroundColor White
            Write-Host ""

            # Show statistics per server
            Write-Host "Server Statistics:" -ForegroundColor Cyan
            foreach ( $server in $environment.Servers ) {
                if ( $server.IsAvailable ) {
                    $availableCounters = $server.Counters | Where-Object { $_.IsAvailable }
                    Write-Host "  $($server.ComputerName): $($availableCounters.Count)/$($server.Counters.Count) counters available, Last Update: $($server.LastUpdate)" -ForegroundColor Green
                } else {
                    Write-Host "  $($server.ComputerName): Unavailable - $($server.LastError)" -ForegroundColor Red
                }
            }

            Write-Host ""
            Write-Host "Environment statistics:" -ForegroundColor Cyan
            $stats = $environment.GetEnvironmentStatistics()
            $stats.GetEnumerator() | Sort-Object Name | ForEach-Object {
                Write-Host "  $($_.Key): $($_.Value)" -ForegroundColor White
            }

        }

    }

}
