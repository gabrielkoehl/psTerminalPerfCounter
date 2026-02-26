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
        [string] $EnvConfigPath
    )

    try {

        if ( [string]::IsNullOrWhiteSpace($EnvConfigPath) ) {
            throw "Environment configuration path parameter cannot be null or empty"
        }

        if ( -not (Test-Path $EnvConfigPath) ) {
            throw "Environment configuration file not found: $EnvConfigPath"
        } else {
            $configContentRaw = Get-Content $EnvConfigPath -Raw
        }

        if ( -not (Test-Path $script:JSON_SCHEMA_ENVIRONMENT_FILE) ) {
            throw "Environment JSON Schema not found: $script:JSON_SCHEMA_ENVIRONMENT_FILE"
        } else {
            $configSchema = Get-Content -Path $script:JSON_SCHEMA_ENVIRONMENT_FILE -Raw
        }


        if ( -not [string]::IsNullOrWhiteSpace($configContentRaw) ) {

            try {
                $jsonContent = $configContentRaw | ConvertFrom-Json
            } catch {
                Write-Warning "Failed to parse JSON from environment configuration file: $EnvConfigPath"
                Return
            }

        } else {

            Write-Warning "Environment configuration file is empty: $EnvConfigPath"
            Return

        }

        # JSON Schema Validation
        # ------------------------------------

        $skipSchemaValidation = $false

        if ( -not (Test-Path $script:JSON_SCHEMA_ENVIRONMENT_FILE) ) {
            Write-Warning "Environment schema file not found at: $script:JSON_SCHEMA_ENVIRONMENT_FILE. Skipping schema validation."
            $skipSchemaValidation = $true
        }

        if ( -not $skipSchemaValidation ) {
            try {

                $isValid = Test-Json -Json $configContentRaw -Schema $configSchema -ErrorAction SilentlyContinue -ErrorVariable validationErrors

                if ( -not $isValid ) {

                    Write-Host "JSON validation error found" -ForegroundColor Red

                    $validationErrors.Exception.Message | ForEach-Object {
                        Write-Host "  - $($_ -replace '^.*?:\s', '')" -ForegroundColor Yellow
                    }

                    throw "Environment configuration JSON schema validation failed"
                }

                Write-Host "Environment configuration passed JSON schema validation"

            } catch {
                throw "Schema validation error for environment configuration '$EnvConfigPath': $($_.Exception.Message)"
            }
        }

        # Create server configurations from JSON
        $servers = New-ServerConfigurationFromJson -JsonConfig $jsonContent

        if ( $servers.Count -eq 0 ) {
            Write-Warning "No valid servers found in environment configuration '$EnvConfigPath'"
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

        $errorMessage = "Error loading environment configuration from '$EnvConfigPath': $($_.Exception.Message)"
        throw $errorMessage

    }

}
