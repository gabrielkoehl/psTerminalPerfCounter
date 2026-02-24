function Merge-JsonConfigDefaultValues {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [hashtable] $CounterConfig
    )

#region Helper
    function Merge-PropertiesRecursive {
        param(
            [hashtable] $Target,
            [hashtable] $Template
        )

        foreach ( $current_property in $Template.Keys ) {

            if ( -not $Target.ContainsKey($current_property) ) {

                # Take from template if missing
                $Target[$current_property] = $Template[$current_property]

            } elseif ( $Target[$current_property] -is [hashtable] -and $Template[$current_property] -is [hashtable] ) {

                # Recurse into nested hashtables
                Merge-PropertiesRecursive -Target $Target[$current_property] -Template $Template[$current_property]

            }

        }

    }

    function Get-DeepCopy { # Avoiding referenz and shallow clone for hashtable
        param( [hashtable] $Source )

        $xml = [System.Management.Automation.PSSerializer]::Serialize($Source, [int32]::MaxValue)
        return [System.Management.Automation.PSSerializer]::Deserialize($xml)

    }

#endregion

    if ( -not (Test-Path -Path $script:JSON_DEFAULT_TEMPLATE_FILE -PathType Leaf) ) {

        throw "Default value template not found in $script:JSON_DEFAULT_TEMPLATE_FILE"

    }

    $counterConfigDefaultValues = (Get-Content $script:JSON_DEFAULT_TEMPLATE_FILE | ConvertFrom-Json -AsHashtable).counters[0]
    $newCounters                = [System.Collections.Generic.List[object]]::new()

    for ($i = 0; $i -lt $CounterConfig.counters.Count; $i++) {

        $current_counter = $CounterConfig.counters[$i]

        try {

            Merge-PropertiesRecursive -Target $current_counter -Template $counterConfigDefaultValues

        } catch {
            throw "Error merging default counter values into $($CounterConfig.name) / $($current_counter.title) ($($_.Exception.Message))"
        }

        try {

            if ( $current_counter.counterSetType -eq 'MultiInstance' -and $current_counter.counterInstance -like "*|*" ) {

                $counterInstances   = $current_counter.counterInstance -split "\|"
                $clonedCounter      = Get-DeepCopy -Source $current_counter

                foreach ( $current_instance in $counterInstances) {
                    $clonedCounter.counterInstance = $current_instance.trim()
                }

                $newCounters.Add($clonedCounter)

            }

        } catch {
            throw "Error expanding MultiInstance Counter $($CounterConfig.name) / $($current_counter.title) ($($_.Exception.Message))"
        }

    }

    $CounterConfig['counters'] = $newCounters.ToArray()
    return $CounterConfig | ConvertTo-Json -Depth 10 | ConvertFrom-Json

}