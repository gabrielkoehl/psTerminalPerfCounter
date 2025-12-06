function Get-tpcConfigPaths {
    <#
    .SYNOPSIS
        Retrieves all configured paths from the TPC_CONFIGPATH environment variable and module defaults.

    .DESCRIPTION
        This function returns an array of all paths where the module searches for configuration files.
        By default, it includes the module's default config directory and any custom paths defined
        in the TPC_CONFIGPATH user environment variable.

        The function validates that each path exists and returns only valid paths. Non-existent
        paths generate warnings but do not cause the function to fail.

        Paths are automatically deduplicated and sorted in the output.

    .PARAMETER noDefault
        If specified, excludes the module's default config directory from the returned paths.
        Only custom paths from the TPC_CONFIGPATH environment variable will be returned.

    .EXAMPLE
        Get-tpcConfigPaths

        Returns all configured paths including the module's default config directory and
        any custom paths from the TPC_CONFIGPATH environment variable.

    .EXAMPLE
        Get-tpcConfigPaths -noDefault

        Returns only custom paths from the TPC_CONFIGPATH environment variable, excluding
        the module's default config directory.

    .OUTPUTS
        String[]. Array of validated, unique configuration paths sorted alphabetically.

    .NOTES
        Custom paths are stored in the user-level TPC_CONFIGPATH environment variable.
        The module's default config directory is always included unless -noDefault is specified.

        Related commands:
        - Add-tpcConfigPath: Add new paths to configuration
        - Remove-tpcConfigPath: Remove paths from configuration
        - Get-tpcAvailableCounterConfig: View available configurations from all paths
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


        foreach ( $envPath in $envPathList ) {
            if ( Test-Path -Path $envPath ) {
                $paths += $envPath
            } else {
                Write-Warning "Configured path '$envPath' does not exist."
            }
        }

    }

    return ( $paths | Sort-Object -Unique )

}
