function Add-tpcConfigPath {
    <#
    .SYNOPSIS
        Adds a custom configuration path to the TPC_CONFIGPATH user environment variable.

    .PARAMETER Path
        Absolute local or UNC path to add. Will be validated and optionally created.

    .PARAMETER Force
        Creates the path without prompting if it doesn't exist.

    .EXAMPLE
        Add-tpcConfigPath -Path "C:\MyConfigs"

    .EXAMPLE
        Add-tpcConfigPath -Path "\\server\share\configs" -Force
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