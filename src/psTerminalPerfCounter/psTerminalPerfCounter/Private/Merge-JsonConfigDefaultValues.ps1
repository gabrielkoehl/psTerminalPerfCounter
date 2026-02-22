function Merge-JsonConfigDefaultValues {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [pscustomobject] $CounterConfig
    )

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

    if ( -not (Test-Path -Path $script:JSON_DEFAULT_TEMPLATE_FILE -PathType Leaf) ) {

        throw "Default value template not found in $script:JSON_DEFAULT_TEMPLATE_FILE"

    }

    # Hashtable comparison is much easier than objects
    $counterConfigHashtable     = $CounterConfig | ConvertTo-Json -Depth 10 | ConvertFrom-Json -AsHashtable
    $counterConfigDefaultValues = (Get-Content $script:JSON_DEFAULT_TEMPLATE_FILE | ConvertFrom-Json -AsHashtable).counters[0]

    try {

        foreach ( $current_counter in $counterConfigHashtable.counters ) {

            Merge-PropertiesRecursive -Target $current_counter -Template $counterConfigDefaultValues

        }

    } catch {

        throw "Error merging default counter values into $($CounterConfig.name) / $($current_counter.title) ($($_.Exception.Message))"

    }

    $result = $counterConfigHashtable | ConvertTo-Json -Depth 10 | ConvertFrom-Json
    return $result


}