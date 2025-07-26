Function Get-ScatterPlot {
    [cmdletbinding()]
    [OutputType([System.Object[,]])]
    Param(
        [Parameter(Mandatory=$true)]
        [int[]] $Datapoints,
        [int]   $StartOfRange,
        [int]   $EndOfRange,
        [int]   $Step = 10,
        [int]   $yAxisMaxRows
    )

    # Create a 2D Array to save datapoints  in a 2D format
    $Difference         = $EndOfRange - $StartOfRange
    $NumOfRows          = $Difference/($Step) + 1
    $NumOfDatapoints    = $Datapoints.Count
    $HalfStep           = [Math]::Ceiling($Step/2)
    $Array              = New-Object -TypeName 'object[,]' -ArgumentList ($NumOfRows),$NumOfDatapoints


    For( $i = 0;$i -lt $Datapoints.count;$i++ ){
        # Fit datapoint in a row, where, a row's data range = Total Datapoints / Step
        $RowIndex = [Math]::Ceiling($($Datapoints[$i]-$StartOfRange)/$Step)

        # cap y-axis for better readability
        if ( $RowIndex -gt $yAxisMaxRows ) {
            $RowIndex = $yAxisMaxRows
        }

        # use a half marker is datapoint falls in less than equals half of the step
        $LowerHalf = $Datapoints[$i]%$Step -in $(1..$HalfStep)

        if ( $LowerHalf ) {
            $Array[$RowIndex,$i] = [char] 9604
        } else {
            $Array[$RowIndex,$i] = [char] 9600
        }

    }

    # return the 2D array of plots
    return ,$Array
}
