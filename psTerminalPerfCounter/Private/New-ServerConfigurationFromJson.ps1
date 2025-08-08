function New-ServerConfigurationFromJson {
    [CmdletBinding()]
    [OutputType([ServerConfiguration[]])]
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]    $JsonConfig,

        [Parameter()]
        [bool]              $isRemote = $false
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
                        $performanceCounters += Get-CounterConfiguration -isRemote $isRemote -ConfigName $CounterConfig
                    }
                }

# in development, the selection of 1st one is in start-tpcMonitor, server count validation
if ( $performanceCounters.count -gt 1 ) {
    Write-Warning "Currently only one performance counter is supported for each server. Monitoring only $($performanceCounters.title)"
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