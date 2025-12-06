
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

        # is ID
        if ( $SearchTerm -match '^\d+-\d+$' ) {

            $IdParts  = $SearchTerm -split '-'
            $SetId    = [int]$IdParts[0]
            $PathId   = [int]$IdParts[1]

            try {
                # Lookup IDs -> Names
                $SetName  = Get-PerformanceCounterLookup -ID $SetId  -ErrorAction SilentlyContinue
                $PathName = Get-PerformanceCounterLookup -ID $PathId -ErrorAction SilentlyContinue

                if ( $SetName -and $PathName ) {

                    $ListSetObj = Get-Counter -ListSet $SetName -ErrorAction SilentlyContinue
                    if (-not $ListSetObj) { throw "CounterSet '$SetName' found by ID but not accessible via Get-Counter." }

                    $SetType = $ListSetObj.CounterSetType.ToString()
                    $counterInstancesValues = @("-")

                    # Handle MultiInstance counters
                    if ( $SetType -eq 'MultiInstance' ) {
                        $counterInstances = $ListSetObj.PathsWithInstances
                        # Regex to extract instance name between parenthesis
                        $searchPattern = '\(([^)]+)\)\\'

                        $counterInstancesValues = $counterInstances | ForEach-Object {
                             if ( $_ -match $searchPattern ) { $matches[1] }
                        } | Select-Object -Unique
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

        # Input is a Name (Search Term)
        } else {

            # Retrieve ALL sets... takes time
            $AllSets = Get-Counter -ListSet *

            foreach ( $CounterSet in $AllSets ) {

                # Performance Optimization: Only process this set if the Set Name OR one of its paths matches the search term.
                if ( -not $CounterSet.Paths ) { continue }

                $MatchingPaths = $CounterSet.Paths | Where-Object {
                    ($_ -like "*$SearchTerm*") -or ($CounterSet.CounterSetName -like "*$SearchTerm*")
                }

                foreach ($CounterPath in $MatchingPaths) {

                    try {
                        # 1. Get SET ID
                        $SetId = Get-PerformanceCounterLookup -Name $CounterSet.CounterSetName -ErrorAction SilentlyContinue

                        # 2. Clean PATH NAME
                        $RawName = ($CounterPath -split '\\')[-1]

                        # Only remove '(*)' if strictly necessary (wildcard placeholder)
                        $PathName = $RawName -replace '\(\*\)', ''

                        # 3. Get PATH ID
                        $PathId = Get-PerformanceCounterLookup -Name $PathName -ErrorAction SilentlyContinue | Select-Object -First 1

                        # 4. Build Composite ID
                        $CompositeId = if ( $SetId -and $PathId ) { "$SetId-$PathId" } else { "N/A" }

                        # Gather Metadata
                        $SetType = $CounterSet.CounterSetType.ToString()
                        $counterInstancesValues = @("-")

                        if ( $SetType -eq 'MultiInstance' ) {
                            $counterInstances = $CounterSet.PathsWithInstances
                            # Regex: Matches content inside parenthesis before a backslash
                            $searchPattern = '\(([^)]+)\)\\'

                            $counterInstancesValues = $counterInstances | ForEach-Object {
                                if ( $_ -match $searchPattern ) { $matches[1] }
                            } | Select-Object -Unique
                        }
                        elseif ( $SetType -ne 'SingleInstance' ) {
                            $SetType = "Unknown ($SetType)"
                        }

                        $Result += [PSCustomObject]@{
                            ID          = $CompositeId
                            CounterSet  = $CounterSet.CounterSetName
                            Path        = $CounterPath
                            SetType     = $SetType
                            Instances   = $($counterInstancesValues -join ', ')
                        }

                    } catch {
                        # Warning instead of Error to avoid stopping the entire loop for one bad counter
                        Write-Warning "Skipping path '$CounterPath': $($_.Exception.Message)"
                    }
                }
            }
        }

        if ( $Result.Count -gt 0)  {
            $Result | Sort-Object -Property CounterSet, Path | Format-Table -AutoSize -Wrap
        } else {
            Write-Host "No matching performance counters found for search term: $SearchTerm" -ForegroundColor Yellow
        }

    } catch {
        Write-Error "Critical error in Get-tpcPerformanceCounterInfo: $($_.Exception.Message)"
    }
}