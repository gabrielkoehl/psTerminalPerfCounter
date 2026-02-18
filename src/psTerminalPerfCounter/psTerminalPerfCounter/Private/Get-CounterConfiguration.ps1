function Get-CounterConfiguration {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [System.Collections.Generic.Dictionary[int, string]] $counterMap,

        [Parameter(ParameterSetName = 'ConfigName',   Mandatory)]
        [Parameter(ParameterSetName = 'RemoteServer', Mandatory)]
        [string]        $ConfigName,

        [Parameter(ParameterSetName = 'ConfigPath',   Mandatory)]
        [string]        $ConfigPath,

        [Parameter(ParameterSetName = 'RemoteServer', Mandatory)]
        [switch]        $isRemote,
        [Parameter(ParameterSetName = 'RemoteServer')]
        [string]        $computername = $env:COMPUTERNAME,
        [Parameter(ParameterSetName = 'RemoteServer')]
        [pscredential]  $credential = $null
    )

    begin {

        $counterParam = @{
            isRemote        = $isRemote.IsPresent
            computername    = $computername
            credential      = $credential
            counterMap      = $counterMap
        }

    }

    process {

        try {

            if ( $isRemote.IsPresent -and $computername -ne $env:COMPUTERNAME ) {
                try {
                    $testResult = Test-Connection -ComputerName $computername -Count 1 -Quiet -TimeoutSeconds 2 -ErrorAction Stop
                    if ( -not $testResult ) {
                        Write-Warning "Server '$computername' is not reachable. Skipping counter configuration."
                        return @{
                            Name        = if ( $ConfigName ) { $ConfigName } else { "Unknown" }
                            Description = "Server unreachable"
                            Counters    = @()
                            ConfigPath  = ""
                            SkipServer  = $true
                        }

                    }

                } catch {

                    Write-Warning "Cannot reach server '$computername': $_. Skipping counter configuration."
                    return @{
                        Name        = if ( $ConfigName ) { $ConfigName } else { "Unknown" }
                        Description = "Server unreachable"
                        Counters    = @()
                        ConfigPath  = ""
                        SkipServer  = $true
                    }
                }
            }


            if ( $PSCmdlet.ParameterSetName -eq 'ConfigPath' ) {
                if ( [string]::IsNullOrWhiteSpace($ConfigPath) ) {
                    throw "ConfigPath parameter cannot be null or empty"
                }
                # Direct path mode - skip folder searching
                $configContent = Get-Content $ConfigPath -Raw

                if ( -not [string]::IsNullOrWhiteSpace($configContent) ) {

                    try {
                        $jsonContent = $configContent | ConvertFrom-Json
                    } catch {
                        Write-Warning "Failed to parse JSON from configuration file: $ConfigPath"
                        Return
                    }

                } else {
                    Write-Warning "Configuration file is empty: $ConfigPath"
                    Return
                }

                $counters = New-CounterConfigurationFromJson @counterParam -JsonConfig $jsonContent

                return @{
                    Name        = $jsonContent.name
                    Description = $jsonContent.description
                    Counters    = $counters
                    ConfigPath  = Split-Path $ConfigPath -Parent
                    SkipServer  = $false
                }
            }

            # ConfigName mode - use default if not provided
            if ( [string]::IsNullOrWhiteSpace($ConfigName) ) {
                throw "ConfigName parameter cannot be null or empty"
            }

            $configPaths  = Get-tpcConfigPaths
            $foundConfigs = @()

            foreach ( $configPath in $configPaths ) {

                $jsonFilePath = Join-Path $configPath "tpc_$ConfigName.json"

                if ( Test-Path $jsonFilePath ) {
                    $foundConfigs += @{
                        Path        = $jsonFilePath
                        ConfigPath  = $configPath
                    }
                }

            }

            if ( $foundConfigs.Count -eq 0 ) {
                $searchedPaths = $configPaths | ForEach-Object { Join-Path $_ "tpc_$ConfigName.json" }
                write-warning "Configuration file 'tpc_$ConfigName.json' not found in any of the following paths: $($searchedPaths -join ', ')"
                Return
            }

            if ( $foundConfigs.Count -gt 1 ) {
                $duplicatePaths = $foundConfigs | ForEach-Object { $_.Path }
                Write-Warning "Configuration 'tpc_$ConfigName.json' was found in multiple locations: $($duplicatePaths -join ', '). Please resolve this by removing duplicates. Using the first found configuration: $($foundConfigs[0].Path)"
            }

            $selectedConfig = $foundConfigs[0]
            $configContent  = Get-Content $selectedConfig.Path -Raw

            if ( -not [string]::IsNullOrWhiteSpace($configContent) ) {

                try {
                    $jsonContent = $configContent | ConvertFrom-Json
                } catch {
                    Write-Warning "Failed to parse JSON from configuration file: $($selectedConfig.Path)"
                    Return
                }

            } else {
                Write-Warning "Configuration file is empty: $($selectedConfig.Path)"
                Return
            }

            $counters       = New-CounterConfigurationFromJson @counterParam -JsonConfig $jsonContent

            return @{
                Name        = $jsonContent.name
                Description = $jsonContent.description
                Counters    = $counters
                ConfigPath  = $selectedConfig.ConfigPath
                SkipServer  = $false
            }

        } catch {

            $errorMessage = if ($PSCmdlet.ParameterSetName -eq 'ConfigPath') {
                "Error loading performance configuration from '$ConfigPath': $($_.Exception.Message)"
            } else {
                "Error loading performance configuration '$ConfigName': $($_.Exception.Message)"
            }
            throw $errorMessage

        }

    }

    end {

    }

}