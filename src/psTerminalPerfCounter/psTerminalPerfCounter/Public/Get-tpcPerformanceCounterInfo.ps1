
function Get-tpcPerformanceCounterInfo {
<#
    .SYNOPSIS
        Resolves performance counter IDs (SetID-PathID) from names or validates existing composite IDs.

    .DESCRIPTION
        Discovers and validates language-independent composite counter IDs for JSON configuration templates.
        Supports local and remote execution via Invoke-Command.

        Input modes:
        - Composite ID ("238-6"): Resolves to localized counter names and metadata
        - Name/pattern ("Processor"): Searches all counter sets and returns matching composite IDs

    .PARAMETER SearchTerm
        Composite ID (format "SetID-PathID") or localized counter name/pattern (wildcards supported).

    .PARAMETER ComputerName
        Target remote machine. Triggers connectivity check and remote execution.

    .PARAMETER Credential
        Alternate credentials for remote execution.

    .EXAMPLE
        Get-tpcPerformanceCounterInfo -SearchTerm "238-6"

    .EXAMPLE
        Get-tpcPerformanceCounterInfo -SearchTerm "Processor"

    .EXAMPLE
        Get-tpcPerformanceCounterInfo -SearchTerm "Processor" -ComputerName 'lab-node1'

    .OUTPUTS
        PSCustomObject: ID, CounterSet, Path, SetType, Instances
    #>

    [CmdletBinding()]
    param(
        [Parameter(ParameterSetName = 'Remote',  Mandatory)]
        [string]        $ComputerName,

        [Parameter(ParameterSetName = 'Remote')]
        [pscredential]  $Credential = $null,

        [Parameter(Mandatory)]
        [string] $SearchTerm
    )

    $Result = @()
    $param  = @{}

    if ( $PSCmdlet.ParameterSetName -eq 'Remote' ) {

        $param.Computername = $computername

        if ( $null -ne $Credential ) {
            $param.Credential = $Credential
        }
    }

    try {

        if ( $PSCmdlet.ParameterSetName -eq 'Remote' -and -not $(Test-Connection -ComputerName $ComputerName -Count 1 -Quiet) ) {
            THROW "Remote computer $computername not reachable. Aborting"
        }

        # is ID
        if ( $SearchTerm -match '^\d+-\d+$' ) {

            $IdParts  = $SearchTerm -split '-'
            $SetId    = [int]$IdParts[0]
            $PathId   = [int]$IdParts[1]

            try {

                # Lookup IDs -> Names
                $SetName  = Get-PerformanceCounterLookup -ID $SetId  @param -ErrorAction SilentlyContinue
                $PathName = Get-PerformanceCounterLookup -ID $PathId @param -ErrorAction SilentlyContinue

                if ( $SetName -and $PathName ) {

                    $scriptblock = { param([string]$arg1) Get-Counter -ListSet $arg1 -ErrorAction SilentlyContinue }
                    $ListSetObj  = invoke-command -ScriptBlock $scriptblock @param -ArgumentList $setname

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
            $scriptblock    = { Get-Counter -ListSet * -ErrorAction SilentlyContinue }
            $AllSets        = invoke-command -ScriptBlock $scriptblock @param

            foreach ( $CounterSet in $AllSets ) {

                $MatchingPaths = $CounterSet.Paths | Where-Object {
                    ($_ -like "*$SearchTerm*") -or ($CounterSet.CounterSetName -like "*$SearchTerm*")
                }

                foreach ( $CounterPath in $MatchingPaths ) {

                    try {
                        # 1. Get SET ID
                        $SetId = Get-PerformanceCounterLookup -Name $CounterSet.CounterSetName @param -ErrorAction SilentlyContinue

                        # 2. Clean PATH NAME
                        $RawName = ($CounterPath -split '\\')[-1]

                        # Only remove '(*)' if strictly necessary (wildcard placeholder)
                        $PathName = $RawName -replace '\(\*\)', ''

                        # 3. Get PATH ID
                        $PathId = Get-PerformanceCounterLookup -Name $PathName @param -ErrorAction SilentlyContinue | Select-Object -First 1

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

                        } elseif ( $SetType -ne 'SingleInstance' ) {

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