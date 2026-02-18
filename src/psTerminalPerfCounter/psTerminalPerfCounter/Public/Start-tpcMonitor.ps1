function Start-tpcMonitor {
    <#
    .SYNOPSIS
        Starts real-time performance counter monitoring for local or remote systems using predefined configuration templates with language-independent counter IDs.

    .DESCRIPTION
        This function launches the main monitoring interface of the psTerminalPerfCounter module. It loads performance
        counter configurations from JSON templates, validates counter availability, and starts continuous real-time
        monitoring with configurable update intervals and data retention.

        The function uses the module's language-independent ID system to ensure configurations work across different
        system locales. It automatically filters unavailable counters and provides detailed feedback about monitoring status.
        Supports interactive monitoring with graphical displays, tables, and statistics based on configuration settings.

        Monitoring can be performed on the local system or on remote computers by specifying ComputerName parameter.
        Remote monitoring requires appropriate permissions and network connectivity to the target system.

    .PARAMETER ConfigName
        Name of the configuration template to load (without 'tpc_' prefix and '.json' extension).
        Must correspond to a JSON file in the config directories (e.g., 'CPU' loads 'tpc_CPU.json').
        Default: 'CPU'
        Cannot be used together with ConfigPath parameter.
        Required when using remote monitoring with ComputerName parameter.

    .PARAMETER ConfigPath
        Absolute path to a specific JSON configuration file.
        The file must follow the naming convention 'tpc_*.json' and exist at the specified location.
        Cannot be used together with ConfigName parameter.
        Only available for local monitoring.

    .PARAMETER ComputerName
        DNS name of the remote computer to monitor.
        Requires ConfigName parameter to be specified.
        The remote system must be reachable and allow remote performance counter access.

    .PARAMETER Credential
        PSCredential object for authenticating to the remote computer.
        If not specified, uses the current user's credentials.
        Only applicable when ComputerName is specified.

    .PARAMETER UpdateInterval
        Interval in seconds between performance counter updates and display refreshes.
        Lower values provide more responsive monitoring but increase system load.
        Graph time span = Samples (from JSON config) × UpdateInterval seconds.
        Default: 1 second

    .PARAMETER ProgressAction
        Common parameter to control the display of progress bars. (PowerShell 7.4+)

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
        Start-tpcMonitor -ConfigName "Disk" -UpdateInterval 1

        Starts disk monitoring with 1-second updates and extended data retention of 200 points.

    .EXAMPLE
        Start-tpcMonitor -ConfigName "CPU" -ComputerName "Server01"

        Monitors CPU performance on remote server 'Server01' using current user credentials.

    .EXAMPLE
        Start-tpcMonitor -ConfigName "Memory" -ComputerName "SQLServer01" -Credential $cred

        Monitors memory performance on remote server 'SQLServer01' using specified credentials.

    .OUTPUTS
        Interactive real-time monitoring display with configurable output formats:
        - Graphical plots (line, bar, scatter based on configuration)
        - Statistical summaries (min, max, average, current values)
        - Tabular data with formatted values and units
        - Session summary upon completion

    .NOTES
        Main entry point for the psTerminalPerfCounter monitoring system.
        Requires JSON configuration files in the module's config directory or custom directories.
        Press Ctrl+C to stop monitoring and display session summary.

        Remote monitoring requires:
        - Network connectivity to target system
        - Appropriate permissions for remote performance counter access
        - Windows Remote Management (WinRM) enabled on target system
    #>

    [CmdletBinding()]
    param(
        [Parameter(ParameterSetName = 'ConfigName',         Mandatory)]
        [Parameter(ParameterSetName = 'SingleRemoteServer')]
        [string]        $ConfigName,

        [Parameter(ParameterSetName = 'ConfigPath',         Mandatory)]
        [Parameter(ParameterSetName = 'SingleRemoteServer')]
        [string]        $ConfigPath,

        [Parameter(ParameterSetName = 'SingleRemoteServer', Mandatory)]
        [string]        $ComputerName,
        [Parameter(ParameterSetName = 'SingleRemoteServer')]
        [pscredential]  $Credential = $null,

        [int]           $UpdateInterval     = 1
    )

    BEGIN {

        $config         = @()
        $monitorType    = 'local'

    }

    PROCESS {

        try {

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
                $Config = Get-CounterConfiguration -ConfigPath $ConfigPath -counterMap $(Get-CounterMap)

            } elseif ( $PSCmdlet.ParameterSetName -eq 'ConfigName' ) {

                Write-Host "Loading configuration '$ConfigName'..." -ForegroundColor Yellow
                $Config = Get-CounterConfiguration -ConfigName $ConfigName  -counterMap $(Get-CounterMap)

            }

            if ( $PSCmdlet.ParameterSetName -eq 'SingleRemoteServer' ) {

                $monitorType = 'remoteSingle'

                Write-Host "Starting remote monitoring for $computername " -ForegroundColor Yellow -NoNewline

                if ( $credential ) {
                    Write-Host "using $($credential.UserName)." -ForegroundColor Yellow -NoNewline
                } else {
                    Write-Host "using $(whoami)." -ForegroundColor Yellow
                }

                if ( Test-Connection -ComputerName $ComputerName -Count 1 -Quiet ) {

                    $Config = Get-CounterConfiguration -ConfigName $ConfigName -isRemote -computername $ComputerName -credential $credential -counterMap $(Get-CounterMap)

                    $config.name = "$($Config.Name) @ REMOTE $($ComputerName)"


                } else {
                    Write-Warning "Remote computer $computername not reachable. Aborting"
                    Return
                }
            }


            # Start monitoring
            $MonitoringParams = @{
                MonitorType     = $monitorType
                Config          = $Config
                UpdateInterval  = $UpdateInterval
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

    END {

    }

}