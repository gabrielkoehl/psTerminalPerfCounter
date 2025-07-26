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

    .PARAMETER UpdateInterval
        Interval in seconds between performance counter updates and display refreshes.
        Lower values provide more responsive monitoring but increase system load.
        Default: 1 second

    .PARAMETER MaxDataPoints
        Maximum number of data points to retain in memory for each counter.
        Affects currently only statistical calculations.
        Default: 100 data points

    .EXAMPLE
        Start-tpcMonitor

        Starts monitoring using the default CPU configuration with 1-second updates and 100 data points.

    .EXAMPLE
        Start-tpcMonitor -ConfigName "Memory" -UpdateInterval 2

        Starts memory monitoring with 2-second update intervals using the 'tpc_Memory.json' configuration.

    .EXAMPLE
        Start-tpcMonitor -ConfigName "Disk" -UpdateInterval 1 -MaxDataPoints 200

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

    [CmdletBinding()]
    param(
        [string]    $ConfigName         = "CPU",
        [int]       $UpdateInterval     = 1,
        [int]       $MaxDataPoints      = 100
    )

    try {

        Write-Host "Loading configuration '$ConfigName'..." -ForegroundColor Yellow
        $Config = Get-PerformanceConfig -ConfigName $ConfigName

        if ( $Config.Counters.Count -eq 0 ) {
            throw "No counters found in configuration '$ConfigName'"
        }

        Write-Host "Testing performance counters..." -ForegroundColor Yellow
        $TestResults = Test-CounterAvailability -Counters $Config.Counters

        # Filter available counters
        $AvailableCounters      = @()
        $UnavailableCounters    = @()

        for ( $i = 0; $i -lt $Config.Counters.Count; $i++ ) {
            if ( $TestResults[$i].Available ) {
                $AvailableCounters      += $Config.Counters[$i]
            } else {
                $UnavailableCounters    += $TestResults[$i]
            }
        }

        # Show unavailable counters
        if ( $UnavailableCounters.Count -gt 0 ) {
            Write-Host "Warning: The following counters are not available:" -ForegroundColor Yellow
            foreach ( $Counter in $UnavailableCounters ) {
                Write-Host "    $($Counter.Title): $($Counter.Error)" -ForegroundColor Red
            }
            Write-Host ""
        }

        if ( $AvailableCounters.Count -eq 0 ) {
            throw "No performance counters are available for monitoring"
        }

        Write-Host "Available counters:" -ForegroundColor Green
        foreach ( $Counter in $AvailableCounters ) {
            Write-Host "    $($Counter.Title)$LangInfo" -ForegroundColor Green
        }
        Write-Host ""


        # Start monitoring
        $MonitoringParams = @{
            Counters       = $AvailableCounters
            Config         = $Config
            UpdateInterval = $UpdateInterval
            MaxDataPoints  = $MaxDataPoints
        }

        Start-MonitoringLoop @MonitoringParams

    } catch [System.Management.Automation.HaltCommandException] {

        Write-Host "`n=== Monitoring stopped by user ===" -ForegroundColor Green

    } catch {

        Write-Host "`n=== ERROR ===" -ForegroundColor Red
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Yellow
        throw

    } finally {
        if ( $AvailableCounters.Count -gt 0 ) {
            Show-SessionSummary -Counters $AvailableCounters
        }
    }

}