
function Get-tpcPerformanceCounterInfo {
     <#
     .SYNOPSIS
          Evaluates and resolves language-independent performance counter IDs for configuration template creation.

     .DESCRIPTION
          This function serves as the primary tool for evaluating correct counter IDs used in configuration templates.
          It operates with a language-independent approach by using numeric IDs instead of localized counter names,
          providing two evaluation methods:
          - ID-based resolution: Validates and resolves composite ID format (SetID-PathID) to counter information
          - Name-based discovery: Searches counter sets and paths to identify correct IDs for template configuration

          The function translates between localized counter names and universal IDs, ensuring configuration templates
          work across different system languages. Results include the composite IDs needed for config templates.

     .PARAMETER SearchTerm
          The search term for counter ID evaluation. Can be either:
          - Composite ID in format "SetID-PathID" (e.g., "238-6") for validation and resolution
          - Localized counter name or path pattern for ID discovery and template preparation

     .EXAMPLE
          Get-tpcPerformanceCounterInfo -SearchTerm "238-6"

          Validates and resolves the composite ID "238-6" to verify counter availability and get localized names.

     .EXAMPLE
          Get-tpcPerformanceCounterInfo -SearchTerm "Processor"

          Discovers all processor-related counters and their corresponding IDs for template configuration.

     .EXAMPLE
          Get-tpcPerformanceCounterInfo -SearchTerm "% Processor Time"

          Finds the specific counter and returns its composite ID for use in configuration templates.

     .OUTPUTS
          Formatted table displaying counter information for template configuration:
          - ID: Composite counter ID (SetID-PathID) for use in config templates, or "N/A" if not resolvable
          - CounterSet: Localized performance counter set name
          - Path: Full localized counter path
          - SetType: SingleInstance or MultiInstance (important for template instance configuration)
          - Instances: Available counter instances for multi-instance counters

     .NOTES
          Primary function for config template ID creation in the psTerminalPerfCounter module.
          Language-independent approach ensures templates work across different system locales.
          Composite IDs returned by this function are used directly in JSON configuration files.
          Requires Get-PerformanceCounterId and Get-PerformanceCounterLocalName helper functions.
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