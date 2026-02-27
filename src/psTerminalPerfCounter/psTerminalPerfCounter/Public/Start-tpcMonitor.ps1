function Start-tpcMonitor {
<#
    .SYNOPSIS
        Starts real-time performance counter monitoring for a single local or remote system.

    .PARAMETER ConfigName
        Name of the configuration template (without 'tpc_' prefix and '.json' extension).
        Cannot be combined with ConfigPath.

    .PARAMETER ConfigPath
        Absolute path to a JSON configuration file (pattern 'tpc_*.json').
        Cannot be combined with ConfigName.

    .PARAMETER ComputerName
        DNS name of the remote computer to monitor.

    .PARAMETER Credential
        PSCredential for remote authentication. Only applicable with ComputerName.

    .PARAMETER UpdateInterval
        Seconds between counter updates. Default: 1.

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

    $configParams       = @{}
    $monitorType        = 'local'

    try {

        if ( ($PSCmdlet.ParameterSetName -in @('RemoteByName', 'RemoteByPath') -and $ComputerName -eq $env:COMPUTERNAME) -or # in case local computername to avoid self remoting
                ($PSCmdlet.ParameterSetName -in @('ConfigPath', 'ConfigName') ) ) {


            if ($PSCmdlet.ParameterSetName -in @('RemoteByName', 'RemoteByPath')) {
                Write-Host "ComputerName '$ComputerName' matches local host. Falling back to local monitoring." -ForegroundColor Yellow
                Start-Sleep -Seconds 1
            }

            $configParams['counterMap'] = $(Get-CounterMap)

            if ( $PSCmdlet.ParameterSetName -in @('ConfigPath', 'RemoteByPath') ) {

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

            } elseif ( $PSCmdlet.ParameterSetName -in @('ConfigName', 'RemoteByName') ) {

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
                Write-Host "using $env:USERDOMAIN\$env:USERNAME ." -ForegroundColor Yellow
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