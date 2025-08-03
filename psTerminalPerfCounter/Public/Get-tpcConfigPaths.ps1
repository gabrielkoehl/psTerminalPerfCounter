function Get-tpcConfigPaths {
    <#
    .SYNOPSIS
        Retrieves all configured paths from the TPC_CONFIGPATH environment variable.

    .DESCRIPTION
        This function returns an array of all paths currently configured in the
        TPC_CONFIGPATH environment variable.

    .PARAMETER noDefault
        If specified, excludes the module's default config directory from the returned paths.

    .EXAMPLE
        Get-tpcConfigPaths

        Returns all configured paths.

    .EXAMPLE
        Get-tpcConfigPaths -noDefault

        Returns all configured paths excluding the module's default config directory.

    .OUTPUTS
        String[]. Array of configuration paths.
    #>

    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [switch] $noDefault
    )

    $paths = @()

    if ( -not $noDefault ) {

        if ( Test-Path -Path $script:DEFAULT_CONFIG_PATH ) {
            $paths += $script:DEFAULT_CONFIG_PATH
        } else {
            Write-Warning "Default config path '$script:DEFAULT_CONFIG_PATH' does not exist."
        }

    }

    $envPaths = [Environment]::GetEnvironmentVariable($script:TPC_CONFIG_PATH_VAR, [EnvironmentVariableTarget]::User)

    if ( -not [string]::IsNullOrWhiteSpace($envPaths) ) {
        $envPathList = $envPaths.Split(',', [StringSplitOptions]::RemoveEmptyEntries) |
                            ForEach-Object { $_.Trim() } |
                            Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

        $paths += $envPathList
    }

    return ( $paths | Sort-Object -Unique )

}
