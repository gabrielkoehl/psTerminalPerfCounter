function New-ServerConfigurationFromJson {
    [CmdletBinding()]
    [OutputType([ServerConfiguration[]])]
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]    $JsonConfig
    )

        $servers = @()

        # Credential
        if ( $JsonConfig.Credential -and $JsonConfig.Credential -eq 'integrated') {
            $setCredential = $null
        } elseif ( $JsonConfig.Credential -eq 'get' ) {
            $setCredential = Get-Credential
        } else {
            $setCredential = Get-CredentialFromVault -VaultName $JsonConfig.SecretVaultName -CredentialName $JsonConfig.CredentialName
        }

        foreach ( $ServerConfig in $JsonConfig.servers ) {

            try {

                $performanceCounters = @()

                #Counters
                if ( $ServerConfig.CounterConfig ) {
                    foreach ( $CounterConfig in $ServerConfig.CounterConfig ) {
                        $performanceCounters += Get-CounterConfiguration -ConfigName $CounterConfig
                    }
                }

                $serverConfiguration = [ServerConfiguration]::new(
                    $ServerConfig.computername,
                    $ServerConfig.comment,
                    $setCredential,
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