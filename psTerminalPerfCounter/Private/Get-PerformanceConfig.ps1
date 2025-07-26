function Get-PerformanceConfig {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory=$true)]
        [string]    $ConfigName,
        [Parameter(Mandatory=$false)]
        [array]     $ConfigPath = @($(Join-Path $PSScriptRoot "..\Config"))
    )

    try {

        $JsonConfig = Get-ConfigurationFromJson -ConfigName $ConfigName -ConfigPath $ConfigPath[0] # prepared for multiple paths in the future
        $Counters   = New-PerformanceCountersFromJson -JsonConfig $JsonConfig
        return @{
            Name        = $JsonConfig.name
            Description = $JsonConfig.description
            Counters    = $Counters
        }

    } catch {
        throw "Error loading performance configuration '$ConfigName': $($_.Exception.Message)"
    }

}