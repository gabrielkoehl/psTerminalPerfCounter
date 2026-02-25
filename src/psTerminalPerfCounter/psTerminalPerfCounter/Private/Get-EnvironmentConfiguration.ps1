function Get-EnvironmentConfiguration {
    <#
    .SYNOPSIS
        Loads an environment configuration from JSON file containing multiple servers

    .DESCRIPTION
        Parses a JSON configuration file that defines an environment with multiple servers.
        Each server can have multiple counter configurations (e.g., CPU, Memory).
        Creates EnvironmentConfiguration object with all ServerConfiguration objects.

    .PARAMETER ConfigPath
        Path to the JSON configuration file (e.g., _remoteconfigs\AD_SERVER_001.json)

    .EXAMPLE
        $env = Get-EnvironmentConfiguration -ConfigPath "_remoteconfigs\AD_SERVER_001.json"
        $env.GetAllValuesParallelAsync().GetAwaiter().GetResult()

    .OUTPUTS
        EnvironmentConfiguration object

    .NOTES
        Requires PowerShellLogger to be initialized in $script:logger
        JSON file must contain: name, description, interval, servers array
    #>

    [CmdletBinding()]
    [OutputType([psTPCCLASSES.EnvironmentConfiguration])]
    param(
        [Parameter(Mandatory=$true)]
        [string] $ConfigPath
    )

    try {

        if ( [string]::IsNullOrWhiteSpace($ConfigPath) ) {
            throw "Environment configuration path parameter cannot be null or empty"
        }

        if ( -not (Test-Path $ConfigPath) ) {
            throw "Environment configuration file not found: $ConfigPath"
        }

        $configContent = Get-Content $ConfigPath -Raw

        if ( -not [string]::IsNullOrWhiteSpace($configContent) ) {

            try {
                $jsonContent = $configContent | ConvertFrom-Json
            } catch {
                Write-Warning "Failed to parse JSON from environment configuration file: $ConfigPath"
                Return
            }

        } else {
            Write-Warning "Environment configuration file is empty: $ConfigPath"
            Return
        }

        # JSON Schema Validation
        # ------------------------------------

        $skipSchemaValidation = $false

        if ( -not (Test-Path $script:JSON_SCHEMA_ENVIRONMENT_FILE) ) {
            Write-Warning "Environment schema file not found at: $script:JSON_SCHEMA_ENVIRONMENT_FILE. Skipping schema validation."
            $skipSchemaValidation = $true
        }

        # Perform schema validation if module and schema are available
        if ( -not $skipSchemaValidation ) {
            try {
                $ValidationResult = Test-JsonSchema -SchemaPath $script:JSON_SCHEMA_ENVIRONMENT_FILE -JsonPath $ConfigPath -ErrorAction Stop 6>$null

                if ( -not $ValidationResult.Valid ) {
                    $errorMessages = $ValidationResult.Errors | ForEach-Object {
                        "  - $($_.Message) | Path: $($_.Path) | Line: $($_.LineNumber)"
                    }
                    $errorDetails = $errorMessages -join "`n"
                    throw "Environment configuration JSON schema validation failed:`n$errorDetails"
                }

                Write-Verbose "Environment configuration passed JSON schema validation"

            } catch {
                throw "Schema validation error for environment configuration '$ConfigPath': $($_.Exception.Message)"
            }
        }

        # Create server configurations from JSON
        $servers = New-ServerConfigurationFromJson -JsonConfig $jsonContent

        if ( $servers.Count -eq 0 ) {
            Write-Warning "No valid servers found in environment configuration '$ConfigPath'"
            Return
        }

        # Create EnvironmentConfiguration object
        $environment = [psTPCCLASSES.EnvironmentConfiguration]::new(
            $jsonContent.name,
            $jsonContent.description,
            $jsonContent.interval,
            $servers
        )

        Write-Host "[Get-EnvironmentConfiguration] Environment '$($jsonContent.name)' loaded with $($servers.Count) server(s)" -ForegroundColor Cyan

        return $environment

    } catch {

        $errorMessage = "Error loading environment configuration from '$ConfigPath': $($_.Exception.Message)"
        throw $errorMessage

    }

}
