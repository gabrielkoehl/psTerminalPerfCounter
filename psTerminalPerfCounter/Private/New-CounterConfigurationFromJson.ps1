function New-CounterConfigurationFromJson {
    [CmdletBinding()]
    [OutputType([CounterConfiguration[]])]
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]    $JsonConfig
    )

    $PerformanceCounters = @()

    foreach ( $CounterConfig in $JsonConfig.counters ) {

        # Create CounterConfiguration Instance
        $CounterConfiguration = [CounterConfiguration]::new(
            $CounterConfig.counterID,
            $CounterConfig.counterSetType,
            $CounterConfig.counterInstance,
            $CounterConfig.title,
            $CounterConfig.type,
            $CounterConfig.format,
            $CounterConfig.unit,
            $CounterConfig.conversionFactor,
            $CounterConfig.conversionExponent,
            $CounterConfig.colorMap,
            $CounterConfig.graphConfiguration
        )

        $PerformanceCounters += $CounterConfiguration
    }

    return $PerformanceCounters

}