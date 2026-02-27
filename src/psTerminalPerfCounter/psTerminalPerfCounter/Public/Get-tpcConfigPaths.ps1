function Get-tpcConfigPaths {
    <#
    .SYNOPSIS

    .DESCRIPTION
        Returns all registered configuration paths (module default + TPC_CONFIGPATH).

    .PARAMETER noDefault
        Excludes the module's default config directory from results.

    .EXAMPLE
        Get-tpcConfigPaths

    .EXAMPLE
        Get-tpcConfigPaths -noDefault
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
