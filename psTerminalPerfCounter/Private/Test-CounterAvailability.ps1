function Test-CounterAvailability {
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param(
        [Parameter(Mandatory=$true)]
        [PerformanceCounter[]]$Counters
    )

    $Results = @()

    foreach ( $Counter in $Counters ) {

        $IsAvailable = $Counter.TestAvailability()

        $Results += [PSCustomObject]@{
            Title       = $Counter.Title
            CounterName = $Counter.CounterPath
            Available   = $IsAvailable
            Error       = $Counter.LastError
        }

    }

    return $Results

}
