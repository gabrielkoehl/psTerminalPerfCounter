function Add-tpcConfigPath {
    <#
    .SYNOPSIS
        Adds a configuration path to the TPC_CONFIGPATH environment variable.

    .DESCRIPTION
        This function adds a new path to the TPC_CONFIGPATH environment variable which is used
        throughout the module to locate configuration files. The function validates the path
        existence and offers to create it if it doesn't exist. Supports both local and network paths.

        Paths are stored comma-separated in the environment variable.

    .PARAMETER Path
        The path to add to the configuration path list. Can be a local path or UNC network path.
        The path will be validated for proper format and existence.

    .PARAMETER Force
        If specified, creates the path without prompting if it doesn't exist.

    .EXAMPLE
        Add-tpcConfigPath -Path "C:\MyConfigs"

        Adds a local path to the configuration path list.

    .EXAMPLE
        Add-tpcConfigPath -Path "\\server\share\configs" -Force

        Adds a network path to the configuration path list and creates it if necessary without prompting.

    .OUTPUTS
        None. Updates the TPC_CONFIGPATH environment variable.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]    $Path,
        [switch]    $Force
    )

    try {
        # Validate path format
        if ( -not [System.IO.Path]::IsPathRooted($Path) ) {
            throw "Path must be an absolute path (rooted path)."
        }

        # Check if path exists
        if ( -not (Test-Path -Path $Path) ) {
            $createPath = $Force

            if ( -not $Force ) {
                $response     = Read-Host "Path '$Path' does not exist. Do you want to create it? (Y/N)"
                $createPath   = $response -match '^[Yy]'
            }

            if ( $createPath ) {

                try {
                    New-Item -Path $Path -ItemType Directory -Force | Out-Null
                    Write-Host "Created path: $Path" -ForegroundColor Green
                } catch {
                    throw "Failed to create path '$Path': $($_.Exception.Message)"
                }

            } else {

                Write-Warning "Path '$Path' was not created. Skipping addition to configuration paths."
                return

            }
        }

        $currentPaths = [Environment]::GetEnvironmentVariable($script:TPC_CONFIG_PATH_VAR, [EnvironmentVariableTarget]::User)

        if ([string]::IsNullOrWhiteSpace($currentPaths)) {

            $newPaths = $Path

        } else {

            $pathList = @($currentPaths.Split(',') | ForEach-Object { $_.Trim() })

            if ( $pathList -contains $Path ) {

                Write-Warning "Path '$Path' is already in the configuration path list."
                return

            }

            # Add new path to the list
            $pathList += $Path
            $newPaths = ($pathList | Sort-Object) -join ','
        }

        # Update environment variable
        [Environment]::SetEnvironmentVariable($script:TPC_CONFIG_PATH_VAR, $newPaths, [EnvironmentVariableTarget]::User)

        Write-Host "Successfully added path '$Path' to TPC configuration paths." -ForegroundColor Green
        Write-Host "Current TPC_CONFIGPATH: $newPaths" -ForegroundColor Cyan
    }
    catch {
        Write-Error "Failed to add configuration path: $($_.Exception.Message)"
    }
}