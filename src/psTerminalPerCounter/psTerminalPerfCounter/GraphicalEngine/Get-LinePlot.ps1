Function Get-LinePlot {
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

    $Difference         = $EndOfRange - $StartOfRange
    $NumOfDatapoints    = $Datapoints.Count

    # Create a 2D Array to save datapoints  in a 2D format
    $NumOfRows  = $difference/($Step) + 1
    $Array      = New-Object -TypeName 'object[,]' -ArgumentList $NumOfRows,$NumOfDatapoints

    $Marker = [char] 9608
    $Line   = [char] 9616

    For( $i = 0;$i -lt $Datapoints.count;$i++ ) {
        # Fit datapoint in a row, where, a row's data range = Total Datapoints / Step
        $RowIndex           = [Math]::Ceiling($($Datapoints[$i]-$StartOfRange)/$Step)
        $RowIndexNextItem   = [Math]::Ceiling($($Datapoints[$i+1]-$StartOfRange)/$Step)

        # cap y-axis for better readability
        if ( $RowIndex -gt $yAxisMaxRows ) {
            $RowIndex = $yAxisMaxRows
        }
        if ( $RowIndexNextItem -gt $yAxisMaxRows ) {
            $RowIndexNextItem = $yAxisMaxRows
        }

        # If this is not the last datapoint...
        if ( $i+1 -lt $Datapoints.count ) {
            # to decide the direction of line joining two data points
            if( $RowIndex -gt $RowIndexNextItem ) {
                Foreach( $j in $($RowIndex-1)..$($RowIndexNextItem+1) ){
                    $Array[$j,$i] = $Line # add line
                }
            } elseif ( $RowIndex -lt $RowIndexNextItem ) {
                Foreach( $j in $($RowIndex)..$($RowIndexNextItem-1) ) {
                    $Array[$j,$i] = $Line # add line
                }
            }
        }

        $Array[$RowIndex,$i] = [char] $Marker # data point
    }
    # return the 2D array of plots
    return ,$Array
}
