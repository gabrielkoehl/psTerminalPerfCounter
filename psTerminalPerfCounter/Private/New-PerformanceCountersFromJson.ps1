function New-PerformanceCountersFromJson {
    [CmdletBinding()]
    [OutputType([PerformanceCounter[]])]
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]    $JsonConfig
    )

    $PerformanceCounters = @()

    foreach ( $CounterConfig in $JsonConfig.counters ) {

        # Create PerformanceCounter Instance
        $Counter = [PerformanceCounter]::new(
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

        $PerformanceCounters += $Counter
    }

    return $PerformanceCounters

}