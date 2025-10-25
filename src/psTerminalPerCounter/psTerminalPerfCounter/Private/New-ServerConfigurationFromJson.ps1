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

                $performanceCounters = @()

                if ( $ServerConfig.CounterConfig ) {
                    foreach ( $CounterConfig in $ServerConfig.CounterConfig ) {
                        $config = Get-CounterConfiguration -ConfigName $CounterConfig -isRemote -computername $ServerConfig.computername -credential $setCredential
                        $performanceCounters += $config.Counters
                    }
                }

                $serverConfiguration = [psTPCCLASSES.ServerConfiguration]::new(
                    $script:logger,
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