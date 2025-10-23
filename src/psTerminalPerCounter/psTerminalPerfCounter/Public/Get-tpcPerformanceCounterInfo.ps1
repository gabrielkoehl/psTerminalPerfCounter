
function Get-tpcPerformanceCounterInfo {
     <#
     .SYNOPSIS
          Evaluates and resolves language-independent performance counter IDs for creating custom configuration templates.

     .DESCRIPTION
          This function serves as the primary tool for discovering and validating correct counter IDs used in JSON configuration templates.
          It operates with a language-independent approach by using numeric IDs instead of localized counter names, ensuring
          configurations work across different Windows language settings.

          Two evaluation methods are supported:
          - ID-based resolution: Validates and resolves composite ID format (SetID-PathID) to counter information
          - Name-based discovery: Searches counter sets and paths to identify correct IDs for template configuration

          The function translates between localized counter names and universal numeric IDs. Results include the composite IDs
          (format: "SetID-PathID") needed for the counterID field in JSON configuration files.

     .PARAMETER SearchTerm
          The search term for counter ID evaluation. Can be either:
          - Composite ID in format "SetID-PathID" (e.g., "238-6") for validation and resolution
          - Localized counter name or path pattern for ID discovery (supports wildcards)

     .EXAMPLE
          Get-tpcPerformanceCounterInfo -SearchTerm "238-6"

          Validates and resolves the composite ID "238-6" to verify counter availability and display localized names.
          Shows the counter set, path, type, and available instances.

     .EXAMPLE
          Get-tpcPerformanceCounterInfo -SearchTerm "Processor"

          Discovers all processor-related counters and their corresponding composite IDs.
          Use these IDs in the counterID field of JSON configuration files.

     .EXAMPLE
          Get-tpcPerformanceCounterInfo -SearchTerm "% Processor Time"

          Finds the specific counter path and returns its composite ID for use in configuration templates.

     .EXAMPLE
          Get-tpcPerformanceCounterInfo -SearchTerm "Memory"

          Searches for all memory-related counters across all counter sets.

     .OUTPUTS
          Formatted table displaying counter information for template configuration:
          - ID: Composite counter ID (SetID-PathID) for use in JSON config counterID field, or "N/A" if not resolvable
          - CounterSet: Localized performance counter set name
          - Path: Full localized counter path
          - SetType: SingleInstance or MultiInstance (determines counterSetType in JSON config)
          - Instances: Available counter instances for multi-instance counters (use in counterInstance field)

     .NOTES
          Primary function for creating custom JSON configuration templates in the psTerminalPerfCounter module.
          Language-independent approach ensures templates work across different Windows system locales.
          Composite IDs returned by this function are used directly in the counterID field of JSON configuration files.

          Related commands:
          - Get-tpcAvailableCounterConfig: View existing configurations
          - Start-tpcMonitor: Start monitoring with a configuration
          - Add-tpcConfigPath: Add custom configuration paths
     #>

     [CmdletBinding()]
     param(
          [Parameter(Mandatory)]
          [string] $SearchTerm
     )

     $Result = @()

     try {

          # Check if SearchTerm is ID format (number-number)
          if ( $SearchTerm -match '^\d+-\d+$' ) {

               $IdParts  = $SearchTerm -split '-'
               $SetId    = [uint32]$IdParts[0]
               $PathId   = [uint32]$IdParts[1]

               try {
                    $SetName  = Get-PerformanceCounterLocalName -ID $SetId      -ErrorAction SilentlyContinue
                    $PathName = Get-PerformanceCounterLocalName -ID $PathId     -ErrorAction SilentlyContinue

                    if ( $SetName -and $PathName ) {

                         $SetType                 = $(get-counter -ListSet $SetName).CounterSetType.ToString()
                         $counterInstancesValues  = @("-")

                         if ( $SetType -eq 'MultiInstance' ) {

                              $counterInstances = $(get-counter -ListSet $SetName).PathsWithInstances
                              $searchPattern = '\(([^)]+)\)'

                              $counterInstancesValues = $counterInstances | ForEach-Object {
                                                       if ( $_ -match $searchPattern ) {$matches[1] }
                                                  } | Select-Object -Unique

                         } elseif ( $SetType -ne 'SingleInstance' ) {

                              throw "Unknown counter set type: $SetType"

                         }

                         $Result = [PSCustomObject]@{
                              ID          = $SearchTerm
                              CounterSet  = $SetName
                              Path        = $PathName
                              SetType     = $SetType
                              Instances   = $($counterInstancesValues -join ', ')
                         }

                    } else {

                         Write-Host "Could not resolve ID '$SearchTerm' to counter names." -ForegroundColor Red
                         if (-not $SetName)  { Write-Host "  Set ID $SetId not found" -ForegroundColor Yellow }
                         if (-not $PathName) { Write-Host "  Path ID $PathId not found" -ForegroundColor Yellow }

                    }

               } catch {
                    Write-Error "Error resolving ID '$SearchTerm': $($_.Exception.Message)"
               }

          # search by name
          } else {
               Get-Counter -ListSet * | ForEach-Object {
                    $CounterSet = $_

                    if ( $CounterSet.Paths ) {

                         $CounterSet.Paths | ForEach-Object {

                              $CounterPath = $_

                              # path or counter match
                              $PathMatches        = $CounterPath -like "*$SearchTerm*"
                              $CounterSetMatches  = $CounterSet.CounterSetName -like "*$SearchTerm*"

                              if ( $PathMatches -or ( $CounterSetMatches -and $CounterPath -like "*$SearchTerm*" ) ) {

                                   # Create composite ID
                                   try {

                                        $SetId         = Get-PerformanceCounterId -Name $CounterSet.CounterSetName -ErrorAction SilentlyContinue
                                        $PathName      = ($CounterPath -split '\\')[-1] -replace '\(\*\)', '' -replace '[(){}]', ''
                                        $PathId        = Get-PerformanceCounterId -Name $PathName -ErrorAction SilentlyContinue
                                        $CompositeId   = if ( $SetId -and $PathId ) { "$SetId-$PathId" } else { "N/A" }

                                        $SetType       = $CounterSet.CounterSetType.ToString()
                                        $counterInstancesValues = @("-")

                                        if ( $SetType -eq 'MultiInstance' ) {

                                             $counterInstances   = $CounterSet.PathsWithInstances
                                             $searchPattern      = '\(([^)]+)\)'

                                             $counterInstancesValues = $counterInstances | ForEach-Object {
                                                                           if ( $_ -match $searchPattern ) {$matches[1] }
                                                                       } | Select-Object -Unique

                                        } elseif ( $SetType -ne 'SingleInstance' ) {

                                             throw "Unknown counter set type: $SetType"

                                        }

                                   } catch {

                                        $CompositeId   = "N/A"
                                        $SetType       = "Unknown"
                                        $counterInstancesValues = @("-")

                                   }

                                   $Result += [PSCustomObject]@{
                                        ID          = $CompositeId
                                        CounterSet  = $CounterSet.CounterSetName
                                        Path        = $CounterPath
                                        SetType     = $SetType
                                        Instances   = $($counterInstancesValues -join ', ')
                                   }
                              }
                         }
                    }
               }
          }

          if ( $Result.Count -gt 0)  {

               $Result | Sort-Object -Property CounterSet, Path, SetType | Format-Table -AutoSize -Wrap

          } else {

               Write-Host "No matching performance counters found for search term: $SearchTerm" -ForegroundColor Yellow

          }

     } catch {

          Write-Error "Error occurred while retrieving performance counter information: $($_.Exception.Message)"

     }

}