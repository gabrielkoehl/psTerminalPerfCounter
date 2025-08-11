function New-ServerConfigurationFromJson {
    [CmdletBinding()]
    [OutputType([ServerConfiguration[]])]
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

                #Counters
                if ( $ServerConfig.CounterConfig ) {
                    foreach ( $CounterConfig in $ServerConfig.CounterConfig ) {
                        $performanceCounters += Get-CounterConfiguration -ConfigName $CounterConfig
                    }
                }

# in development, the selection of 1st one is in start-tpcMonitor, server count validation
if ( $performanceCounters.count -gt 1 ) {
    Write-Warning "Currently only one performance counter is supported for each server. You can add more counter to config itself. Monitoring only $($performanceCounters.title)"
}

                $serverConfiguration = [ServerConfiguration]::new(
                    $ServerConfig.computername,
                    $ServerConfig.comment,
                    $performanceCounters
                )

                $serverConfiguration.SetCounterRemoteProperties($ServerConfig.computername, $setCredential)

                $servers += $serverConfiguration

            } catch {

                Write-Warning "Failed to create ServerConfiguration for $($ServerConfig.computername): $_ . Skipping this server."
                continue

            }

        }

    return $servers


}