function Test-tpcAvailableCounterConfig {
<#
.SYNOPSIS
    Validates and displays available tpc counter configurations.

.DESCRIPTION
    Scans configured paths (or a single file) for 'tpc_*.json' files.
    Validates against JSON schema using Test-Json (PowerShell 7.4+),
    merges default values, resolves counter paths, and detects duplicates.
    Template files are excluded.

.PARAMETER configFilePath
    Path to a single configuration file. If omitted, all configured paths are scanned.

.PARAMETER Raw
    Returns PSCustomObject[] instead of formatted console output.

.EXAMPLE
    Test-tpcAvailableCounterConfig

.EXAMPLE
    Test-tpcAvailableCounterConfig -configFilePath "C:\configs\tpc_CPU.json"

.EXAMPLE
    Test-tpcAvailableCounterConfig -Raw | Where-Object { -not $_.JsonValid }

.OUTPUTS
    Formatted console output (default) or PSCustomObject[] (-Raw).
#>

[CmdletBinding()]
param (
    [Parameter()]
    [string] $configFilePath,

    [Parameter()]
    [switch] $Raw
)

    try {

        $skipSchemaValidation   = $false
        $isSingleFile           = $false
        $AllResults             = [System.Collections.Generic.List[PSCustomObject]]::new() # wenn irgendwann mal 100te Configs da sind, ist besser
        $ConfigNamesFound       = @{}
        $localCounterMap        = Get-CounterMap


        if ( -not (Test-Path $script:JSON_SCHEMA_CONFIG_FILE) ) {
            Write-Warning "Central schema file not found at: $script:JSON_SCHEMA_CONFIG_FILE. Skipping schema validation."
            $skipSchemaValidation = $true
        } else {
            $configSchema = Get-Content $script:JSON_SCHEMA_CONFIG_FILE -Raw
        }

        if ( $PSBoundParameters.ContainsKey('configFilePath') ) {
            $ConfigPaths    = @($configFilePath)
            $isSingleFile   = $true
        } else {
            $ConfigPaths    = Get-tpcConfigPaths
        }

        if ( $ConfigPaths.Count -eq 0 -and -not $isSingleFile ) {
            Write-Warning "No configuration paths found. Use Add-tpcConfigPath to add configuration directories."
            return @()
        }


        foreach ( $ConfigPath in $ConfigPaths ) {

            $PathResults = [System.Collections.Generic.List[PSCustomObject]]::new()

            if ( -not (Test-Path $ConfigPath) ) {
                Write-Warning "Configuration directory / file not found: $ConfigPath"
                continue
            }

            if ( -not $isSingleFile ) {

                $ConfigFiles = Get-ChildItem -Path $ConfigPath -Filter "tpc_*.json" -File | Where-Object { $_.BaseName -notlike "*template*" }

                if ( $ConfigFiles.Count -eq 0 ) {
                    Write-Verbose "No configuration files found with 'tpc_' prefix in: $ConfigPath"
                    continue
                }

            } else {

                $ConfigFiles = Get-Item $ConfigPath

            }

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

                    $JsonContent        = Get-Content -Path $ConfigFile.FullName -Raw -ErrorAction Stop | ConvertFrom-Json -AsHashtable
                    $mergedJsonContent  = Merge-JsonConfigDefaultValues -CounterConfig $JsonContent
                    $rawJson            = $mergedJsonContent | ConvertTo-Json -Depth 10
                    $isEmpty            = [string]::IsNullOrWhiteSpace($rawJson)

                    # Determine if this is a duplicate
                    $IsDuplicate = $ConfigNamesFound[$ConfigNameLower] -gt 1

                    $SchemaValidation = @{IsValid = $true; Errors = @()}
                    $validationErrors = @()

                    if ( -not $isEmpty -and -not $skipSchemaValidation) {

                        try {

                            $isValid = Test-Json -Json $rawJson -Schema $configSchema -ErrorAction SilentlyContinue -ErrorVariable validationErrors

                            $SchemaValidation['IsValid']    = $isValid
                            $SchemaValidation['Errors'] = @($validationErrors.Exception.Message | ForEach-Object { $_ -replace '^.*?:\s', '' })

                        } catch {

                            $SchemaValidation.IsValid     = $false
                            $SchemaValidation.Errors      = @("Schema validation failed: $($_.Exception.Message)")
                        }

                    } else {

                        Write-Verbose "Skipping schema validation for $ConfigName in path $ConfigPath due to missing module or schema file."

                    }

                    $CounterDetails = [System.Collections.Generic.List[PSCustomObject]]::new()

                    if ( -not $isEmpty ) {

                        foreach ( $CounterConfig in $mergedJsonContent.counters ) {

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
                                $localCounterMap
                            )

                            $CounterDetail = [PSCustomObject]@{
                                Title           = $Counter.Title
                                CounterId       = $Counter.counterID
                                CounterPath     = $Counter.CounterPath
                                Unit            = $Counter.Unit
                                Format          = $Counter.Format
                                InstancePath    = $Counter.CounterPath
                                Valid           = $true
                                ErrorMessage    = $null
                            }

                            $CounterDetails.Add($CounterDetail)

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

                            $CounterDetails.Add($CounterDetail)
                        }

                    }
                }

                    $ConfigOverview = [PSCustomObject]@{
                        ConfigName               = $ConfigName
                        ConfigPath               = $ConfigPath
                        Description              = if ($isEmpty) { "Error: Empty configuration file" } else { $mergedJsonContent.description }
                        ConfigFile               = $ConfigFile.FullName
                        JsonValid                = if ($isEmpty) { $false } else { $SchemaValidation.IsValid }
                        JsonValidationErrors     = if ($isEmpty) { @("Configuration file is empty or contains only whitespace") } else { $SchemaValidation.Errors }
                        CounterCount             = $CounterDetails.Count
                        Counters                 = $CounterDetails
                        IsDuplicate              = $IsDuplicate
                    }

                    $PathResults.Add($ConfigOverview)

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
                        Counters                 = @()
                        IsDuplicate              = $IsDuplicate
                    }

                    $PathResults.Add($ErrorConfig)

                }

            }

        # Add path results to overall results
        if ( $PathResults.Count -gt 0 ) {
            $AllResults.AddRange($PathResults)
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

                        if ( $result.JsonValid ) {
                            Write-Host "$JsonStatus" -ForegroundColor Green
                        } else {
                            Write-Host "$JsonStatus" -ForegroundColor Red
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
                            $result.Counters | Format-Table Title, CounterId, Unit, Format, InstancePath -AutoSize -Wrap
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
