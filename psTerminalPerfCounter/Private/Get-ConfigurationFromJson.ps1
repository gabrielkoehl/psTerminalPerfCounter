function Get-ConfigurationFromJson {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ConfigName,
        [Parameter(Mandatory=$false)]
        [string]$ConfigPath
    )

    $JsonFilePath = Join-Path $ConfigPath "tpc_$ConfigName.json"

    if ( -not (Test-Path $JsonFilePath) ) {
        throw "Configuration file not found: $JsonFilePath"
    }

    try {
        $JsonContent = Get-Content $JsonFilePath -Raw | ConvertFrom-Json
        return $JsonContent
    } catch {
        throw "Error loading configuration from '$JsonFilePath': $($_.Exception.Message)"
    }

}
