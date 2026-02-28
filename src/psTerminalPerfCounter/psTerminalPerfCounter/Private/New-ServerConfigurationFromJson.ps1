function New-ServerConfigurationFromJson {
    [CmdletBinding()]
    [OutputType([System.Object[]])]
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject] $JsonConfig
    )

        $servers = [System.Collections.Generic.List[psTPCCLASSES.ServerConfiguration]]::new()

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

                $paramServer                = @{ 'Computername' = $ServerConfig.computername }
                if ( $null -ne $setCredential ) {
                    $paramServer['Credential'] = $setCredential
                }
                $serverCounterMap           = Get-CounterMap @paramServer
                $paramServer['counterMap']  = $serverCounterMap


                $performanceCounters    = [System.Collections.Generic.List[psTPCCLASSES.CounterConfiguration]]::new()
                $skipServer             = $false


                if ( $ServerConfig.CounterConfig ) {

                    foreach ( $CounterConfig in $ServerConfig.CounterConfig ) {

                        $paramCounter = $paramServer.Clone()

                        if ($CounterConfig -match '^[A-Za-z][A-Za-z0-9_]*$') {
                            # counter name
                            $paramCounter['ConfigName'] = $CounterConfig
                        } elseif ($CounterConfig -match '^[A-Za-z]:\\|^\\\\') {
                            # counter path (local, unc)
                            $paramCounter['ConfigPath'] = $CounterConfig
                        } else {
                            # Nothing to do here - schema validation would have already aborted before reaching this point
                        }

                        $config = Get-CounterConfiguration @paramCounter

                        if ( $config.SkipServer ) {
                            $skipServer = $true
                            break
                        }

                        $performanceCounters.AddRange($config.Counters)
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
                    $performanceCounters,
                    $true # skip availability check - server already validated via Get-CounterMap
                )

                $servers.Add($serverConfiguration)

            } catch {

                Write-Warning "Failed to create ServerConfiguration for $($ServerConfig.computername): $_ . Skipping this server."
                continue

            }

        }

    return , $servers


}