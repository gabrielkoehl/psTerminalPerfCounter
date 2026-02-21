function Start-tpcMonitor {
<#
    .SYNOPSIS
        Starts real-time performance counter monitoring for local or remote systems using predefined JSON configuration templates.

    .DESCRIPTION
        Main entry point for the psTerminalPerfCounter module singler server monitoring. Loads counter configurations from JSON templates,
        resolves language-independent counter IDs via Get-CounterMap, and starts continuous monitoring via Start-MonitoringLoop.
        Supports local and remote monitoring. Remote targets are validated via Test-Connection before counter resolution.
        If ComputerName matches the local hostname, monitoring falls back to local mode.
        Press Ctrl+C to stop monitoring.

    .PARAMETER ConfigName
        Name of the configuration template (without 'tpc_' prefix and '.json' extension).
        Must correspond to a file in the module's config directories.
        Cannot be combined with ConfigPath.

    .PARAMETER ConfigPath
        Absolute path to a JSON configuration file. Must match the pattern 'tpc_*.json'.
        Cannot be combined with ConfigName.

    .PARAMETER ComputerName
        DNS name of the remote computer to monitor.
        Requires network connectivity and remote performance counter access.

    .PARAMETER Credential
        PSCredential for remote authentication. Defaults to current user credentials.
        Only applicable with ComputerName.

    .PARAMETER UpdateInterval
        Seconds between counter updates. Default: 1.
        Graph time span = Samples (from config) × UpdateInterval.

    .EXAMPLE
        Start-tpcMonitor -ConfigName "CPU"

    .EXAMPLE
        Start-tpcMonitor -ConfigPath "C:\MyConfigs\tpc_CustomCPU.json"

    .EXAMPLE
        Start-tpcMonitor -ConfigName "Memory" -ComputerName "Server01" -Credential $cred -UpdateInterval 2
    #>

    [CmdletBinding()]
    param(
        [Parameter(ParameterSetName = 'ConfigName',    Mandatory)]
        [Parameter(ParameterSetName = 'RemoteByName',  Mandatory)]
        [string]        $ConfigName,

        [Parameter(ParameterSetName = 'ConfigPath',    Mandatory)]
        [Parameter(ParameterSetName = 'RemoteByPath',  Mandatory)]
        [string]        $ConfigPath,

        [Parameter(ParameterSetName = 'RemoteByName',  Mandatory)]
        [Parameter(ParameterSetName = 'RemoteByPath',  Mandatory)]
        [string]        $ComputerName,

        [Parameter(ParameterSetName = 'RemoteByName')]
        [Parameter(ParameterSetName = 'RemoteByPath')]
        [pscredential]  $Credential = $null,

        [int]           $UpdateInterval = 1
    )

    BEGIN {

        $configParams       = @{}
        $monitorType        = 'local'

    }

    PROCESS {

        try {

            if ( ($PSCmdlet.ParameterSetName -in @('RemoteByName', 'RemoteByPath') -and $ComputerName -eq $env:COMPUTERNAME) -or # in case local computername to avoid self remoting
                 ($PSCmdlet.ParameterSetName -in @('ConfigPath', 'ConfigName') ) ) {

                $configParams['counterMap'] = $(Get-CounterMap)

                if ( $PSCmdlet.ParameterSetName -eq 'ConfigPath' ) {

                    if ( -not (Test-Path $ConfigPath) ) {
                        Write-Warning "Configuration file not found: $ConfigPath"
                        Return
                    }

                    $fileName = Split-Path $ConfigPath -Leaf
                    if ( $fileName -notmatch '^tpc_.+\.json$' ) {
                        throw "Invalid configuration file name. File must follow the pattern 'tpc_*.json'. Found: $fileName"
                    }

                    Write-Host "Loading configuration from '$ConfigPath'..." -ForegroundColor Yellow

                    $configParams['ConfigPath'] = $ConfigPath


                    #$Config = Get-CounterConfiguration -ConfigPath $ConfigPath -counterMap $(Get-CounterMap)

                } elseif ( $PSCmdlet.ParameterSetName -eq 'ConfigName' ) {

                    Write-Host "Loading configuration '$ConfigName'..." -ForegroundColor Yellow

                    $configParams['ConfigName'] = $ConfigName

                }

            } elseif ( $PSCmdlet.ParameterSetName -in @('RemoteByName', 'RemoteByPath') -and $ComputerName -ne $env:COMPUTERNAME ) {

                $monitorType = 'remoteSingle'

                $configParams['ComputerName'] = $ComputerName

                Write-Host "Starting remote monitoring for $computername " -ForegroundColor Yellow -NoNewline

                if ( $credential ) {
                    Write-Host "using $($credential.UserName)." -ForegroundColor Yellow
                    $configParams['Credential'] = $Credential
                } else {
                    Write-Host "using $(whoami)." -ForegroundColor Yellow
                }

                if ( Test-Connection -ComputerName $ComputerName -Count 1 -Quiet ) {

                    $configParams['counterMap'] = $(Get-CounterMap @configParams)

                    switch ( $PSCmdlet.ParameterSetName ) {
                        'RemoteByName' { $configParams['ConfigName'] = $ConfigName }
                        'RemoteByPath' { $configParams['ConfigPath'] = $ConfigPath }
                    }

                } else {

                    Write-Warning "Remote computer $computername not reachable. Aborting"
                    Return

                }
            }

            # Start monitoring
            $MonitoringParams = @{
                MonitorType     = $monitorType
                Config          = Get-CounterConfiguration @configParams
                UpdateInterval  = $UpdateInterval
            }

            Start-MonitoringLoop @MonitoringParams

        } catch [System.Management.Automation.HaltCommandException] {

            Write-Host "`n=== Monitoring stopped by user ===" -ForegroundColor Green

        } catch {

            Write-Host "`n=== ERROR ===" -ForegroundColor Red
            Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Yellow
            throw

        }

    }

    END {

    }

}