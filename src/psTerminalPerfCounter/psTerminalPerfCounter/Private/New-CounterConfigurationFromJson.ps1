function New-CounterConfigurationFromJson {
    [CmdletBinding()]
    [OutputType([System.Object[]])]
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]    $JsonConfig,
        [Parameter(Mandatory=$true)]
        [System.Collections.Generic.Dictionary[int, string]] $counterMap,

        # Remote params
        [Parameter()]
        [bool]              $isRemote,
        [Parameter()]
        [string]            $ComputerName,
        [Parameter()]
        [pscredential]      $Credential
    )

    $PerformanceCounters = [System.Collections.Generic.List[psTPCCLASSES.CounterConfiguration]]::new()

    foreach ( $CounterConfig in $JsonConfig.counters ) {

        # Create CounterConfiguration Instance
        $CounterConfiguration = [psTPCCLASSES.CounterConfiguration]::new(
            $CounterConfig.counterID,
            $CounterConfig.counterSetType,
            $CounterConfig.counterInstance,
            $CounterConfig.title,
            $CounterConfig.format,
            $CounterConfig.unit,
            $CounterConfig.conversionFactor,
            $CounterConfig.conversionExponent,
            $CounterConfig.conversionType,
            $CounterConfig.decimalPlaces,
            $CounterConfig.colorMap,
            $CounterConfig.graphConfiguration,
            $isRemote,
            $ComputerName,
            $Credential,
            $counterMap
        )

        $PerformanceCounters.Add($CounterConfiguration)
    }

    return , $PerformanceCounters

}