function Merge-JsonConfigDefaultValues {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [hashtable] $CounterConfig
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

    $counterConfigDefaultValues = (Get-Content $script:JSON_DEFAULT_TEMPLATE_FILE | ConvertFrom-Json -AsHashtable).counters[0]

    try {

        foreach ( $current_counter in $CounterConfig.counters ) {

            Merge-PropertiesRecursive -Target $current_counter -Template $counterConfigDefaultValues

            # Hier auf MultiInstance prüfen und Instanzen auflösen und klonen
            # Indexmäßig dazwischen schieben

            if ( $current_counter.counterSetType -eq 'MultiInstance' -and $current_counter.counterInstance -like "|" ) {

                # BUG - get-tpcPerformanceCounterInfo needs Computername -- määhh really

            }

        }

    } catch {

        throw "Error merging default counter values into $($CounterConfig.name) / $($current_counter.title) ($($_.Exception.Message))"

    }

    $result = $CounterConfig | ConvertTo-Json -Depth 10 | ConvertFrom-Json
    return $result


}