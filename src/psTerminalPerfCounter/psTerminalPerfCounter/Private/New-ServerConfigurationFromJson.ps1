function New-ServerConfigurationFromJson {
    [CmdletBinding()]
    [OutputType([psTPCCLASSES.ServerConfiguration[]])]
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject] $JsonConfig
    )

        $servers = @()

        # Credential
        if ( $JsonConfig.CredentialName -and $JsonConfig.CredentialName -eq 'integrated') {
            $setCredential = $null
        } elseif ( $JsonConfig.CredentialName -eq 'get' ) {
            $setCredential = Get-Credential
        } else {
            $setCredential = Get-CredentialFromVault -VaultName $JsonConfig.SecretVaultName -CredentialName $JsonConfig.CredentialName
        }

        foreach ( $ServerConfig in $JsonConfig.servers ) {

            try {

                $param                  = @{'Computername' = $ServerConfig.computername }
                $performanceCounters    = @()
                $skipServer             = $false
                $serverCounterMap       = Get-CounterMap @param

                if ( $ServerConfig.CounterConfig ) {

                    foreach ( $CounterConfig in $ServerConfig.CounterConfig ) {

                        if ( $null -eq $setCredential ) { $param['Credential'] = $setCredential }

                        $param = @{
                            "computername"  = $ServerConfig.computername
                            "credential"    = $setCredential
                            "counterMap"    = $serverCounterMap
                        }

                        if ($CounterConfig -match '^[A-Za-z][A-Za-z0-9_]*$') {
                            # counter name
                            $param['ConfigName'] = $CounterConfig
                        } elseif ($CounterConfig -match '^[A-Za-z]:\\|^\\\\') {
                            # counter path (local, unc)
                            $param['ConfigPath'] = $CounterConfig
                        } else {
                            # Nothing to do here - schema validation would have already aborted before reaching this point
                        }

                        $config = Get-CounterConfiguration @param

                        if ( $config.SkipServer ) {
                            $skipServer = $true
                            break
                        }

                        $performanceCounters += $config.Counters
                    }
                }

                if ( $skipServer ) {
                    Write-Warning "Skipping server '$($ServerConfig.computername)' - marked as unreachable during counter configuration."
                    Start-Sleep 1
                    continue
                }

                $serverConfiguration = [psTPCCLASSES.ServerConfiguration]::new(
                    $ServerConfig.computername,
                    $ServerConfig.comment,
                    $performanceCounters
                )

                $servers += $serverConfiguration

            } catch {

                Write-Warning "Failed to create ServerConfiguration for $($ServerConfig.computername): $_ . Skipping this server."
                continue

            }

        }

    return $servers


}