     function Get-tpcAvailableCounterConfig {
     <#
     .SYNOPSIS
          Retrieves, validates, and displays detailed information about available performance
          counter configurations including JSON schema validation and optional counter availability testing.

     .DESCRIPTION
          This function scans the config directory for all JSON files with the 'tpc_' prefix
          and provides detailed information about each configuration including counter details,
          validation status, and availability checks.

     .PARAMETER ConfigPath
          Optional custom path to configuration files. If not specified, uses the module's
          config directory.

     .PARAMETER Raw
          If specified, returns raw PSCustomObject array instead of formatted output.

     .PARAMETER TestCounters
          If specified, tests each counter for availability. This can be slow with many counters.

     .EXAMPLE
          Get-tpcAvailableCounterConfig

          Shows formatted overview of all available configurations (without counter testing).

     .EXAMPLE
          Get-tpcAvailableCounterConfig -TestCounters

          Shows formatted overview with counter availability testing.

     .EXAMPLE
          Get-tpcAvailableCounterConfig -ConfigPath "C:\MyConfigs" -TestCounters

          Shows formatted overview of configurations from a custom directory with counter testing.

     .EXAMPLE
          Get-tpcAvailableCounterConfig -Raw

          Returns raw configuration objects for further processing.

     .OUTPUTS
          Formatted output by default, PSCustomObject[] when -Raw is used.
     #>

     [CmdletBinding()]
     [OutputType([PSCustomObject[]])]
     param(
          [string]    $ConfigPath =$(Join-Path $PSScriptRoot "..\Config"),
          [string]    $SchemaPath = $(Join-Path $ConfigPath "schema.json"),
          [switch]    $Raw,
          [switch]    $TestCounters

     )

     try {

          # required module for JSON schema validation
          $skipSchemaValidation = $false

          if ( -not (Get-Module -Name GripDevJsonSchemaValidator -ListAvailable) ) {
               Write-Warning "Module 'GripDevJsonSchemaValidator' not found. Please install it with: Install-Module -Name GripDevJsonSchemaValidator"
               Write-Warning "JSON schema validation will be skipped."
               $skipSchemaValidation = $true
          }

          if ( -not (Test-Path $ConfigPath) ) {
               throw "Configuration directory not found: $ConfigPath"
          }

          if ( -not (Test-Path $SchemaPath) ) {
               Write-Warning "Schema file not found at: $SchemaPath"
               $skipSchemaValidation = $true
          }

          $ConfigFiles = Get-ChildItem -Path $ConfigPath -Filter "tpc_*.json" -File | Where-Object { $_.BaseName -notlike "*template*" }

          if ( $ConfigFiles.Count -eq 0 ) {
               Write-Warning "No configuration files found with 'tpc_' prefix in: $ConfigPath"
               return @()
          }

          $Results = @()

          foreach ( $ConfigFile in $ConfigFiles ) {

               try {

                    $ConfigName    = $ConfigFile.BaseName -replace '^tpc_', ''
                    $JsonContent   = Get-Content -Path $ConfigFile.FullName -Raw -ErrorAction Stop
                    $JsonConfig    = $JsonContent | ConvertFrom-Json -ErrorAction Stop


                    $SchemaValidation = @{IsValid = $true; Errors = @()}

                    if ( -not $skipSchemaValidation ) {

                         try {

                              $ValidationResult = Test-JsonSchema -SchemaPath $SchemaPath -JsonPath $ConfigFile.FullName -ErrorAction Stop 6>$null
                              $SchemaValidation.IsValid = $ValidationResult.Valid
                              if ( -not $ValidationResult.Valid ) {
                                   $SchemaValidation.Errors = @($ValidationResult.Errors | ForEach-Object { "$($_.Message) | Path: $($_.Path) | Line: $($_.LineNumber)" })
                              }

                         } catch {

                              $SchemaValidation.IsValid = $false
                              $SchemaValidation.Errors = @("Schema validation failed: $($_.Exception.Message)")
                         }

                    } else {

                         Write-Warning "Skipping schema validation for $ConfigName due to missing module or Schema file."

                    }

                    $CounterDetails = @()

                    foreach ( $CounterConfig in $JsonConfig.counters ) {

                         try {

                              $Counter = [PerformanceCounter]::new(
                                   $CounterConfig.counterID,
                                   $CounterConfig.counterSetType,
                                   $CounterConfig.counterInstance,
                                   $CounterConfig.title,
                                   $CounterConfig.type,
                                   $CounterConfig.format,
                                   $CounterConfig.unit,
                                   $CounterConfig.colorMap,
                                   $CounterConfig.graphConfiguration
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

                    $ConfigOverview = [PSCustomObject]@{
                         ConfigName               = $ConfigName
                         Description              = $JsonConfig.description
                         ConfigFile               = $ConfigFile.FullName
                         JsonValid                = $SchemaValidation.IsValid
                         JsonValidationErrors     = $SchemaValidation.Errors
                         CounterCount             = $CounterDetails.Count
                         ValidCounters            = if ($TestCounters) { ($CounterDetails | Where-Object { $_.Valid -eq $true }).Count }  else { "Not tested" }
                         InvalidCounters          = if ($TestCounters) { ($CounterDetails | Where-Object { $_.Valid -eq $false }).Count } else { "Not tested" }
                         Counters                 = $CounterDetails
                    }

                    $Results += $ConfigOverview

               } catch {

                    Write-Error "Error processing configuration file '$($ConfigFile.Name)': $($_.Exception.Message)"

                    $ErrorConfig = [PSCustomObject]@{
                         ConfigName               = $ConfigFile.BaseName -replace '^tpc_', ''
                         Description              = "Error loading configuration"
                         ConfigFile               = $ConfigFile.FullName
                         JsonValid                = $false
                         JsonValidationErrors     = @($_.Exception.Message)
                         CounterCount             = 0
                         ValidCounters            = if ($TestCounters) { 0 } else { "Not tested" }
                         InvalidCounters          = if ($TestCounters) { 0 } else { "Not tested" }
                         Counters                 = @()
                    }

                    $Results += $ErrorConfig

               }
          }

          if ( $Raw ) {

               return $Results

          } else {

               foreach ( $result in $Results ) {
                    Write-Host "`n=== $($result.ConfigName) ===" -ForegroundColor Cyan
                    Write-Host "Description: $($result.Description)" -ForegroundColor Gray
                    $JsonStatus    = if ( $result.JsonValid )  { "Valid JSON Schema" } else { "Invalid JSON Schema" }
                    $CounterStatus = if ( $TestCounters ) { "Counters: $($result.ValidCounters)/$($result.CounterCount)" } else { "Counters: $($result.CounterCount) (not tested)" }

                    if ( $result.JsonValid ) {
                         Write-Host "$JsonStatus, $CounterStatus" -ForegroundColor Green
                    } else {
                         Write-Host "$JsonStatus, $CounterStatus" -ForegroundColor Red
                         Write-Host "Schema Validation Errors:" -ForegroundColor Yellow
                         ForEach ( $errorMessage in $result.JsonValidationErrors ) {
                              Write-Host "  - $errorMessage" -ForegroundColor Red
                         }
                    }

                    if ( $result.Counters.Count -gt 0)  {
                         if ( $TestCounters ) {
                              $result.Counters | Format-Table Title, CounterId, Unit, Format, Valid, InstancePath -AutoSize -Wrap
                         } else {
                              $result.Counters | Format-Table Title, CounterId, Unit, Format, InstancePath -AutoSize -Wrap
                         }

                    } else {

                         Write-Host "  No counters found" -ForegroundColor Yellow

                    }
               }

          }

     } catch {

          Write-Error "Error in Get-tpcAvailableCounterConfig: $($_.Exception.Message)"

     }

}
