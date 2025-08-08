function Get-ServerConfiguration {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter()]
        [string] $pathServerConfiguration
    )

    try {

        if ( [string]::IsNullOrWhiteSpace($pathServerConfiguration) ) {
            throw "Server configuration path parameter cannot be null or empty"
        }

        $configContent = Get-Content $pathServerConfiguration -Raw

        if ( -not [string]::IsNullOrWhiteSpace($configContent) ) {

            try {
                $jsonContent = $configContent | ConvertFrom-Json
            } catch {
                Write-Warning "Failed to parse JSON from server configuration file: $pathServerConfiguration"
                Return
            }

        } else {
            Write-Warning "Server configuration file is empty: $pathServerConfiguration"
            Return
        }


        $servers = New-ServerConfigurationFromJson -JsonConfig $jsonContent


        return @{
            Name        = $jsonContent.name
            Description = $jsonContent.description
            Interval    = $jsonContent.interval
            Servers     = $servers
            ConfigPath  = Split-Path $pathServerConfiguration -Parent
        }

    } catch {

        $errorMessage = "Error loading server configuration from '$pathServerConfiguration': $($_.Exception.Message)"
        throw $errorMessage

    }

}