function Test-CounterAvailability {
    [CmdletBinding()]
    [OutputType([psobject])]
    param(
        [Parameter(ParameterSetName = 'LocalConfig')]
        [psobject] $LocalConfig,

        [Parameter(ParameterSetName = 'RemoteServerConfig')]
        [string] $RemoteServerConfig
    )

    try {

        if ( $PSCmdlet.ParameterSetName -eq 'LocalConfig' ) {

            Write-Host "Testing availability of performance counters..." -ForegroundColor Cyan

            $AvailableCounters      = @()
            $UnavailableCounters    = @()

            foreach ( $counter in $LocalConfig.Counters ) {
                $isAvailable = $counter.TestAvailability()

                if ( $isAvailable ) {
                    $AvailableCounters      += $counter
                } else {
                    $UnavailableCounters    += $counter
                }
            }

            # Show unavailable counters
            if ( $UnavailableCounters.Count -gt 0 ) {
                Write-Warning "The following counters are not available:"
                foreach ( $Counter in $UnavailableCounters ) {
                    Write-Warning "    $($Counter.Title): $($Counter.LastError)"
                }
                Write-Host ""
            }

            if ( $AvailableCounters.Count -eq 0 ) {
                Write-Warning "No performance counters are available for monitoring. Aborting."
                return @{
                    Success         = $false
                    CleanedConfig   = $null
                }
            }

            Write-Host "Available counters:" -ForegroundColor Green
            foreach ( $Counter in $AvailableCounters ) {
                Write-Host "    $($Counter.Title)" -ForegroundColor Green
            }

            Write-Host ""

            # Create cleaned config
            $CleanedConfig = [PSCustomObject]@{
                Name        = $LocalConfig.Name
                Description = $LocalConfig.Description
                ConfigPath  = $LocalConfig.ConfigPath
                Counters    = $AvailableCounters
            }

            return @{
                Success       = $true
                CleanedConfig = $CleanedConfig
            }

        } elseif ( $PSCmdlet.ParameterSetName -eq 'RemoteServerConfig' ) {

        }

    } catch {
        Write-Error "Error testing counter availability: $($_.Exception.Message)"
        return @()
    }
}
