<#

     currently only powershell vault is supported

     2do
     - Module verification
     - implement dynamic support for (all) other existing vaults (e.g., Azure Key Vault, HashiCorp Vault)

#>

function Get-CredentialFromVault {
    [CmdletBinding()]
    [OutputType([PSCredential])]
    param(
        [Parameter(Mandatory=$true)]
        [string] $VaultName,

        [Parameter(Mandatory=$true)]
        [string] $CredentialName
    )

    $currentVault       = $VaultName
    $currentCredential  = $CredentialName

    $secretStore_isAvailable      = Get-Module -ListAvailable -Name "Microsoft.PowerShell.SecretStore"
    $secretManagement_isAvailable = Get-Module -ListAvailable -Name "Microsoft.PowerShell.SecretManagement"

    try {

        if ( -not $secretStore_isAvailable -or -not $secretManagement_isAvailable ) {

            [pscredential] $credential = Get-Credential -Message "Required modules 'Microsoft.PowerShell.SecretStore' and 'Microsoft.PowerShell.SecretManagement' are not available. Please install them first. Enter credentials manually"
            return $credential

        }

        [pscredential] $credential = Get-Secret -Vault $currentVault -Name $currentCredential

        if ( $credential ) {

            return $credential

        } else {

            Write-Warning "No credential found in vault '$currentVault' with name '$currentCredential'."

            do {
                    $useGetCredential = Read-Host "Do you want to enter the credential manually? (y/n)"
                    $useGetCredential = $useGetCredential.ToLower()
            } while ( $useGetCredential -notin @('y', 'n') )

            if ( $useGetCredential -eq 'y' ) {
                    return Get-Credential -Message "Enter credentials'"
            } else {

                    # Loop for trying different vault/credential combinations
                    while ( $true ) {
                        do {
                            $changeVault = Read-Host "Do you want to specify a different Vault name or Credential name? (y/n)"
                            $changeVault = $changeVault.ToLower()
                        } while ( $changeVault -notin @('y', 'n') )

                        if ( $changeVault -eq 'y' ) {
                            $newVault           = Read-Host "Enter new Vault name (leave blank to keep '$currentVault')"
                            $newCredential      = Read-Host "Enter new Credential name (leave blank to keep '$currentCredential')"
                            $currentVault       = if ( $newVault.Trim() )          { $newVault.Trim() }          else { $currentVault }
                            $currentCredential  = if ( $newCredential.Trim() )     { $newCredential.Trim() }     else { $currentCredential }

                            Write-Host "Trying vault '$currentVault' with credential '$currentCredential'..."

                            try {

                                [pscredential] $credential = Get-Secret -Vault $currentVault -Name $currentCredential

                                if ( $credential ) {
                                        return $credential
                                } else {

                                        Write-Warning "No credential found in vault '$currentVault' with name '$currentCredential'."

                                        do {
                                            $useGetCredentialLoop = Read-Host "Do you want to enter the credential manually? (y/n)"
                                            $useGetCredentialLoop = $useGetCredentialLoop.ToLower()
                                        } while ( $useGetCredentialLoop -notin @('y', 'n') )

                                        if ( $useGetCredentialLoop -eq 'y' ) {
                                            return Get-Credential -Message "Enter credentials for '$currentVault\$currentCredential'"
                                        }
                                        # Continue loop
                                }

                            } catch {

                                Write-Error "Failed to retrieve credential from vault '$currentVault': $_"

                                do {
                                        $useGetCredentialAfterError = Read-Host "An error occurred. Do you want to enter the credential manually? (y/n)"
                                        $useGetCredentialAfterError = $useGetCredentialAfterError.ToLower()
                                } while ($useGetCredentialAfterError -notin @('y', 'n'))

                                if ( $useGetCredentialAfterError -eq 'y' ) {
                                        return Get-Credential -Message "Enter credentials manually (vault access failed)"
                                }

                                # Continue loop
                            }

                        } else {
                            Write-Warning "Aborted by user."
                            return $null
                        }
                    }
            }
        }

    } catch {

        Write-Error "Failed to retrieve credential from vault '$VaultName': $_"

        do {
            $useGetCredentialAfterError = Read-Host "An error occurred. Do you want to enter the credential manually? (y/n)"
            $useGetCredentialAfterError = $useGetCredentialAfterError.ToLower()
        } while ($useGetCredentialAfterError -notin @('y', 'n'))

        if ( $useGetCredentialAfterError -eq 'y' ) {
            return Get-Credential -Message "Enter credentials manually (vault access failed)"
        } else {
            return $null
        }
    }

}
