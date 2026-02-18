function Remove-tpcConfigPath {
    <#
    .SYNOPSIS
        Removes custom configuration paths from the TPC_CONFIGPATH environment variable.

    .DESCRIPTION
        This function provides an interactive menu to remove custom paths from the TPC_CONFIGPATH user
        environment variable. It displays all currently configured paths with their existence status
        and allows the user to select which path(s) to remove.

        The function provides an interactive selection menu where users can choose paths by number.
        Paths are displayed with indicators showing whether they exist (✓) or not (✗).

        Note: This function only affects custom paths stored in the environment variable. The module's
        default config directory cannot be removed through this function.

    .PARAMETER All
        If specified, removes all custom paths from the TPC_CONFIGPATH environment variable without prompting.
        The module's default config directory is not affected.

    .PARAMETER ProgressAction
        Common parameter to control the display of progress bars. (PowerShell 7.4+)

    .EXAMPLE
        Remove-tpcConfigPath

        Shows an interactive menu to select and remove custom configuration paths.
        Displays path existence status and allows sequential removal with confirmation.

    .EXAMPLE
        Remove-tpcConfigPath -All

        Removes all custom configuration paths from TPC_CONFIGPATH without prompting.

    .OUTPUTS
        None. Updates the TPC_CONFIGPATH user environment variable.

    .NOTES
        Related commands:
        - Get-tpcConfigPaths: List all configured paths
        - Add-tpcConfigPath: Add new paths to configuration
        - Get-tpcAvailableCounterConfig: View available configurations from all paths
    #>

    [CmdletBinding()]
    param(
        [switch]$All
    )

    try {
        # Get current TPC_CONFIGPATH value
        $currentPaths = [Environment]::GetEnvironmentVariable($script:TPC_CONFIG_PATH_VAR, [EnvironmentVariableTarget]::User)

        if ( [string]::IsNullOrWhiteSpace($currentPaths) ) {
            Write-Warning "No configuration paths are currently set in TPC_CONFIGPATH."
            return
        }

        if ( $All ) {
            [Environment]::SetEnvironmentVariable($script:TPC_CONFIG_PATH_VAR, $null, [EnvironmentVariableTarget]::User)
            Write-Host "All configuration paths have been removed from TPC_CONFIGPATH." -ForegroundColor Green
            return
        }

        # Split paths into array
        $pathList = @($currentPaths.Split(',', [StringSplitOptions]::RemoveEmptyEntries) | ForEach-Object { $_.Trim() })

        if ( $pathList.Count -eq 0 ) {
            Write-Warning "No valid configuration paths found in TPC_CONFIGPATH."
            return
        }

        # Display current paths with numbers
        Write-Host "`nCurrent TPC Configuration Paths:" -ForegroundColor Cyan
        Write-Host "=================================" -ForegroundColor Cyan

        for ( $i = 0; $i -lt $pathList.Count; $i++ ) {
            $status = if (Test-Path -Path $pathList[$i]) { "✓" } else { "✗" }
            Write-Host "$($i + 1). $status $($pathList[$i])" -ForegroundColor $(if (Test-Path -Path $pathList[$i]) { "Green" } else { "Red" })
        }

        Write-Host "`n✓ = Path exists, ✗ = Path not found" -ForegroundColor Gray
        Write-Host "0. Cancel operation" -ForegroundColor Yellow

        # Get user selection
        do {
            $selection = Read-Host "`nEnter the number of the path to remove (0 to cancel)"

            if ( $selection -eq "0" ) {
                Write-Host "Operation cancelled." -ForegroundColor Yellow
                return
            }

            $selectedIndex = $null
            if ( [int]::TryParse($selection, [ref]$selectedIndex) ) {
                $selectedIndex-- # Convert to 0-based index

                if ( $selectedIndex -ge 0 -and $selectedIndex -lt $pathList.Count ) {
                    $pathToRemove = $pathList[$selectedIndex]

                    # Confirm removal
                    $confirm = Read-Host "Remove path '$pathToRemove'? (Y/N)"

                    if ( $confirm -match '^[Yy]' ) {
                        # Remove the selected path
                        $remainingPaths = $pathList | Where-Object { $_ -ne $pathToRemove }

                        # No paths left, remove the environment variable
                        if ( $remainingPaths.Count -eq 0 ) {
                            [Environment]::SetEnvironmentVariable($script:TPC_CONFIG_PATH_VAR, $null, [EnvironmentVariableTarget]::User)
                            Write-Host "Removed path '$pathToRemove'. TPC_CONFIGPATH is now empty." -ForegroundColor Green

                        # Update with remaining paths
                        } else {
                            $newPaths = ($remainingPaths | Sort-Object) -join ','
                            [Environment]::SetEnvironmentVariable($script:TPC_CONFIG_PATH_VAR, $newPaths, [EnvironmentVariableTarget]::User)
                            Write-Host "Removed path '$pathToRemove'." -ForegroundColor Green
                            Write-Host "Updated TPC_CONFIGPATH: $newPaths" -ForegroundColor Cyan
                        }

                        # Ask if user wants to remove more paths
                        if ( $remainingPaths.Count -gt 0 ) {
                            $continueRemoving = Read-Host "`nDo you want to remove another path? (Y/N)"
                            if ( $continueRemoving -match '^[Yy]' ) {
                                Remove-tpcConfigPath
                            }
                        }

                        return

                    } else {
                        Write-Host "Removal cancelled." -ForegroundColor Yellow
                        return
                    }

                } else {
                    Write-Warning "Invalid selection. Please enter a number between 1 and $($pathList.Count), or 0 to cancel."
                }

            } else {
                Write-Warning "Invalid input. Please enter a valid number."
            }

        } while ( $true )

    } catch {
        Write-Error "Failed to remove configuration path: $($_.Exception.Message)"
    }
}
