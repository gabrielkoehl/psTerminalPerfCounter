function Get-tpcAvailableCounterConfig {
<#
.SYNOPSIS
    Lists available performance counter configurations from all configured paths.

.DESCRIPTION
    Scans configured paths for 'tpc_*.json' files, validates them against the JSON schema,
    and displays counter details grouped by path. Detects duplicates across paths.
    Template files are excluded.

.PARAMETER Raw
    Returns raw PSCustomObject[] instead of formatted output.

.PARAMETER TestCounters
    Tests each counter for availability on the current system. May be slow.

.EXAMPLE
    Get-tpcAvailableCounterConfig

.EXAMPLE
    Get-tpcAvailableCounterConfig -TestCounters

.EXAMPLE
    Get-tpcAvailableCounterConfig -Raw

.OUTPUTS
    Formatted console output (default) or PSCustomObject[] (-Raw).

.NOTES
    Requires GripDevJsonSchemaValidator module for schema validation.
#>

[CmdletBinding()]
param (
    [Parameter()]
    [string] $configPath,

    [Parameter()]
    [switch] $TestCounters
)

    try {

        $skipSchemaValidation = $false

        # Check if central schema file exists
        if ( -not (Test-Path $script:JSON_SCHEMA_CONFIG_FILE) ) {
            Write-Warning "Central schema file not found at: $script:JSON_SCHEMA_CONFIG_FILE. Skipping schema validation."
            $skipSchemaValidation = $true
        } else {
            $configSchema = Get-Content $script:JSON_SCHEMA_CONFIG_FILE -Raw
        }

        # Get all configured paths using Get-tpcConfigPaths
        $ConfigPaths = Get-tpcConfigPaths

        if ( $ConfigPaths.Count -eq 0 ) {
            Write-Warning "No configuration paths found. Use Add-tpcConfigPath to add configuration directories."
            return @()
        }

        if ( $PSBoundParameters.ContainsKey('configPath') ) {

        } else {

        }

        $AllResults         = @()
        $ConfigNamesFound   = @{}

        foreach ( $ConfigPath in $ConfigPaths ) {

            if ( -not (Test-Path $ConfigPath) ) {
                Write-Warning "Configuration directory not found: $ConfigPath"
                continue
            }

            $ConfigFiles = Get-ChildItem -Path $ConfigPath -Filter "tpc_*.json" -File | Where-Object { $_.BaseName -notlike "*template*" }

            if ( $ConfigFiles.Count -eq 0 ) {
                Write-Verbose "No configuration files found with 'tpc_' prefix in: $ConfigPath"
                continue
            }

            $PathResults = @()

            foreach ( $ConfigFile in $ConfigFiles ) {

                try {

                    $ConfigName    = $ConfigFile.BaseName -replace '^tpc_', ''

                    # Track duplicate configurations, 1st action for all files

                    $ConfigNameLower = $ConfigName.ToLower()

                    if ( $ConfigNamesFound.ContainsKey($ConfigNameLower) ) {
                        $ConfigNamesFound[$ConfigNameLower] += 1
                    } else {
                        $ConfigNamesFound[$ConfigNameLower] = 1
                    }

                    $JsonContent   = Get-Content -Path $ConfigFile.FullName -Raw -ErrorAction Stop

                    # Check for empty file
                    $isEmpty = [string]::IsNullOrWhiteSpace($JsonContent)

                    if ( -not $isEmpty ) {
                        $JsonConfig    = $JsonContent | ConvertFrom-Json -ErrorAction Stop
                    }

                    # Determine if this is a duplicate
                    $IsDuplicate = $ConfigNamesFound[$ConfigNameLower] -gt 1

                    $SchemaValidation = @{IsValid = $true; Errors = @()}

                    if ( -not $isEmpty -and -not $skipSchemaValidation ) {

                        try {

                            $ValidationResult = Test-JsonSchema -SchemaPath $script:JSON_SCHEMA_CONFIG_FILE -JsonPath $ConfigFile.FullName -ErrorAction Stop 6>$null
                            $SchemaValidation.IsValid = $ValidationResult.Valid
                            if ( -not $ValidationResult.Valid ) {
                                $SchemaValidation.Errors = @($ValidationResult.Errors | ForEach-Object { "$($_.Message) | Path: $($_.Path) | Line: $($_.LineNumber)" })
                            }

                        } catch {

                            $SchemaValidation.IsValid     = $false
                            $SchemaValidation.Errors      = @("Schema validation failed: $($_.Exception.Message)")
                        }

                    } else {

                        Write-Verbose "Skipping schema validation for $ConfigName in path $ConfigPath due to missing module or schema file."

                    }

                    $CounterDetails = @()

                    if ( -not $isEmpty ) {

                        foreach ( $CounterConfig in $JsonConfig.counters ) {

                        try {

                            $Counter = [psTPCCLASSES.CounterConfiguration]::new(
                                $CounterConfig.counterID,
                                $CounterConfig.counterSetType,
                                $CounterConfig.counterInstance,
                                $CounterConfig.title,
                                $CounterConfig.format,
                                $CounterConfig.unit,
                                $CounterConfig.conversionFactor,
                                $CounterConfig.conversionExponent,
                                $CounterConfig.conversionType,
                                $CounterConfig.decimalPlaces,
                                $CounterConfig.colorMap,
                                $CounterConfig.graphConfiguration,
                                $false,
                                "",
                                $NULL,
                                $(get-CounterMap)
                            )

                            $IsAvailable = if ($TestCounters) { $Counter.TestAvailability() } else { $null }

                            $CounterDetail = [PSCustomObject]@{
                                Title          = $Counter.Title
                                CounterId      = $Counter.counterID
                                CounterPath    = $Counter.CounterPath
                                Unit           = $Counter.Unit
                                Format         = $Counter.Format
                                Valid          = $IsAvailable
                                ErrorMessage   = if ($TestCounters -and -not $IsAvailable) { $Counter.LastError } else { $null }
                                InstancePath   = $Counter.CounterPath
                            }

                            $CounterDetails += $CounterDetail

                        } catch {

                            $CounterDetail = [PSCustomObject]@{
                                Title          = $CounterConfig.title
                                CounterId      = $CounterConfig.counterID
                                CounterPath    = "Invalid"
                                Unit           = $CounterConfig.unit
                                Format         = $CounterConfig.format
                                Valid          = $false
                                ErrorMessage   = $_.Exception.Message
                                InstancePath   = $($_.Exception.Message)
                            }

                            $CounterDetails += $CounterDetail
                        }

                    }
                }

                    $ConfigOverview = [PSCustomObject]@{
                            ConfigName               = $ConfigName
                            ConfigPath               = $ConfigPath
                            Description              = if ($isEmpty) { "Error: Empty configuration file" } else { $JsonConfig.description }
                            ConfigFile               = $ConfigFile.FullName
                            JsonValid                = if ($isEmpty) { $false } else { $SchemaValidation.IsValid }
                            JsonValidationErrors     = if ($isEmpty) { @("Configuration file is empty or contains only whitespace") } else { $SchemaValidation.Errors }
                            CounterCount             = $CounterDetails.Count
                            ValidCounters            = if ($TestCounters) { ($CounterDetails | Where-Object { $_.Valid -eq $true }).Count }  else { "Not tested" }
                            InvalidCounters          = if ($TestCounters) { ($CounterDetails | Where-Object { $_.Valid -eq $false }).Count } else { "Not tested" }
                            Counters                 = $CounterDetails
                            IsDuplicate              = $IsDuplicate
                    }

                    $PathResults += $ConfigOverview

                } catch {

                    Write-Error "Error processing configuration file '$($ConfigFile.Name)': $($_.Exception.Message)"

                    # Determine if this is a duplicate (also for error configs)
                    $ConfigNameLower = ($ConfigFile.BaseName -replace '^tpc_', '').ToLower()
                    $IsDuplicate = $ConfigNamesFound[$ConfigNameLower] -gt 1

                    $ErrorConfig = [PSCustomObject]@{
                            ConfigName               = $ConfigFile.BaseName -replace '^tpc_', ''
                            ConfigPath               = $ConfigPath
                            Description              = "Error loading configuration"
                            ConfigFile               = $ConfigFile.FullName
                            JsonValid                = $false
                            JsonValidationErrors     = @($_.Exception.Message)
                            CounterCount             = 0
                            ValidCounters            = if ($TestCounters) { 0 } else { "Not tested" }
                            InvalidCounters          = if ($TestCounters) { 0 } else { "Not tested" }
                            Counters                 = @()
                            IsDuplicate              = $IsDuplicate
                    }

                    $PathResults += $ErrorConfig

                }

            }

        # Add path results to overall results
        if ( $PathResults.Count -gt 0 ) {
            $AllResults += $PathResults
        }
    }

    # Identify duplicates for summary
    $duplicateNames = $ConfigNamesFound.Keys | Where-Object { $ConfigNamesFound[$_] -gt 1 }

        if ( $Raw ) {

            return $AllResults

        } else {

            # Group by path
            $groupedResults = $AllResults | Group-Object -Property ConfigPath

            foreach ( $pathGroup in $groupedResults ) {
                Write-Host "`nConfiguration Path: $($pathGroup.Name)" -ForegroundColor Cyan
                $separatorLine = "=" * $( $pathGroup.Name.Length + 22 )
                Write-Host $separatorLine -ForegroundColor Cyan

                foreach ( $result in $pathGroup.Group ) {

                        $configDisplay = $result.ConfigName
                        if ( $result.IsDuplicate ) {
                            $configDisplay += " [DUPLICATE]"
                        }
                        $configDisplay += " ($([System.IO.Path]::GetFileName($result.ConfigFile)))"

                        $separatorLine2 = "." * $( $pathGroup.Name.Length + 22 )
                        Write-Host ""
                        Write-Host $separatorLine2 -ForegroundColor Gray
                        Write-Host "`n$configDisplay" -ForegroundColor $(if ($result.IsDuplicate) { "Yellow" } else { "Green" })
                        Write-Host "Description: $($result.Description)" -ForegroundColor Gray

                        $JsonStatus    = if ( $result.JsonValid )    { "Valid JSON Schema" } else { "Invalid JSON Schema" }
                        $CounterStatus = if ( $TestCounters )        { "Counters: $($result.ValidCounters)/$($result.CounterCount)" } else { "Counters: $($result.CounterCount) (not tested)" }

                        if ( $result.JsonValid ) {
                            Write-Host "$JsonStatus, $CounterStatus" -ForegroundColor Green
                        } else {
                            Write-Host "$JsonStatus, $CounterStatus" -ForegroundColor Red
                            Write-Host "Schema Validation Errors:" -ForegroundColor Yellow
                            ForEach ( $errorMessage in $result.JsonValidationErrors ) {
                                Write-Host "  - $errorMessage" -ForegroundColor Red
                            }
                        }

                        if ( $result.IsDuplicate ) {
                            Write-Warning "This configuration exists in multiple paths. Consider removing duplicates."
                        }

                        if ( $result.Counters.Count -gt 0)  {
                            Write-Host "Counters:" -ForegroundColor Gray
                            if ( $TestCounters ) {
                                $result.Counters | Format-Table Title, CounterId, Unit, Format, Valid, InstancePath -AutoSize -Wrap
                            } else {
                                $result.Counters | Format-Table Title, CounterId, Unit, Format, InstancePath -AutoSize -Wrap
                            }

                        } else {

                            Write-Host "No counters found" -ForegroundColor Yellow

                        }
                }
            }

            # Show summary of duplicates if any found
            if ( $duplicateNames.Count -gt 0 ) {
                Write-Host "`nDUPLICATE CONFIGURATIONS DETECTED:" -ForegroundColor Red
                $separatorLine = "=" * 35
                Write-Host $separatorLine -ForegroundColor Red
                foreach ( $dupName in $duplicateNames ) {
                        $dupConfigs = $AllResults | Where-Object { $_.ConfigName.ToLower() -eq $dupName }
                        Write-Host "`n'$dupName' found in:" -ForegroundColor Yellow
                        foreach ( $dupConfig in $dupConfigs ) {
                            Write-Host "- $($dupConfig.ConfigPath) ($([System.IO.Path]::GetFileName($dupConfig.ConfigFile)))" -ForegroundColor Gray
                        }
                }
                Write-Host "`nConsider removing duplicate configurations to avoid conflicts." -ForegroundColor Yellow
            }

        }

    } catch {

        Write-Error "Error in Get-tpcAvailableCounterConfig: $($_.Exception.Message)"

    }

}
