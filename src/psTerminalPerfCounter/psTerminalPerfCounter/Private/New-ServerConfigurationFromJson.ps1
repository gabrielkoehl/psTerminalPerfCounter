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

                $performanceCounters    = @()
                $skipServer             = $false

                if ( $ServerConfig.CounterConfig ) {
                    foreach ( $CounterConfig in $ServerConfig.CounterConfig ) {

                        $param = @{}

                        if ( $null -eq $setCredential ) { $param['Credential'] = $setCredential }

                        $serverCounterMap = Get-CounterMap @param

                        $config = Get-CounterConfiguration -ConfigName $CounterConfig -computername $ServerConfig.computername -credential $setCredential -counterMap $serverCounterMap

                        if ( $config.SkipServer ) {
                            $skipServer = $true
                            break
                        }

                        $performanceCounters += $config.Counters
                    }
                }

                if ( $skipServer ) {
                    Write-Warning "Skipping server '$($ServerConfig.computername)' - marked as unreachable during counter configuration."
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