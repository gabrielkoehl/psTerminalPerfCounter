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

        [int]       $UpdateInterval = 1,
        [int]       $MaxHistoryPoints  = 100
    )

    try {

        # Validate ConfigPath if provided
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

        } else {

            Write-Host "Loading configuration '$ConfigName'..." -ForegroundColor Yellow
            $Config = Get-CounterConfiguration -ConfigName $ConfigName

        }

        if ( $Config.Counters.Count -eq 0 ) {
            $configInfo = if ( $PSCmdlet.ParameterSetName -eq 'ConfigPath' ) { $ConfigPath } else { $ConfigName }
            Write-Warning "No counters found in configuration '$configInfo'"
            return
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
        if ( $AvailableCounters.Count -gt 0 ) {
            Show-SessionSummary -Counters $AvailableCounters
        }
    }

}