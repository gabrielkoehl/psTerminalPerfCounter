Function Show-Graph {
    [cmdletbinding()]
    Param(
        [int[]]     $Datapoints,
        [String]    $GraphTitle,
        [ValidateScript({ if( $_ -le 5 ){ Throw "Can not set XAxisStep less than or equals to 5" } else { return $true } })] [Int] $XAxisStep = 10,
        [Int]       $YAxisStep      = 10,
        [Int]       $yAxisMaxRows   = 10,
        [ValidateSet("Bar","Scatter","Line")]
        [String]    $Type           = 'Bar',
        [Hashtable] $ColorMap
    )

    # graph boundary marks
    $TopLeft                = [char]9484 # ┌
    $BottomLeft             = [char]9492 # └
    $TopRight               = [char]9488 # ┐
    $BottomRight            = [char]9496 # ┘
    $VerticalEdge           = [char]9474 # │
    $TopEdge = $BottomEdge  = [char]9472 # ─

    # Calculate Max, Min and Range of Y axis
    $NumOfDatapoints        = $Datapoints.Count
    $Metric                 = $Datapoints | Measure-Object -Maximum -Minimum
    $EndofRange             = $Metric.Maximum + ($YAxisStep - $Metric.Maximum % $YAxisStep)
    $StartOfRange           = $Metric.Minimum - ($Metric.Minimum % $YAxisStep)
    $difference             = $EndofRange - $StartOfRange
    $NumOfRows              = $difference/($YAxisStep)

    # Calculate label lengths
    $LengthOfMaxYAxisLabel  = [Math]::Max(1, (($Datapoints | Measure-Object -Maximum).Maximum).tostring().length)

    # Cap number of rows to yAxisMaxRows for better readability
    if ( $NumOfRows -gt $yAxisMaxRows ) {
        $NumOfRows = $yAxisMaxRows
    }

    # Create a 2D Array to save datapoints  in a 2D format
    switch( $Type ){
        'Bar'       { $Array = Get-BarPlot       -Datapoints $Datapoints -Step $YAxisStep -StartOfRange $StartOfRange -EndofRange $EndofRange -yAxisMaxRows $yAxisMaxRows }
        'Scatter'   { $Array = Get-ScatterPlot   -Datapoints $Datapoints -Step $YAxisStep -StartOfRange $StartOfRange -EndofRange $EndofRange -yAxisMaxRows $yAxisMaxRows }
        'Line'      { $Array = Get-LinePlot      -Datapoints $Datapoints -Step $YAxisStep -StartOfRange $StartOfRange -EndofRange $EndofRange -yAxisMaxRows $yAxisMaxRows }
    }

    # Preparing the step markings on the X-Axis (reversed for time series)
    $Increment  = $XAxisStep
    $XAxisLabel = " " * ($LengthOfMaxYAxisLabel + 4)
    $XAxis      = " " * ($LengthOfMaxYAxisLabel + 3) + [char]9492 # └

    For ( $Label = 1; $Label -le $NumOfDatapoints; $Label++ ) {

        if ( [math]::floor($Label/$XAxisStep) ){
            $TimeLabel      = $NumOfDatapoints - $Label + 1
            $XAxisLabel    += $TimeLabel.tostring().PadLeft($Increment)
            $XAxis         += ([char]9516).ToString()
            $XAxisStep     += $Increment
        } else {
            $XAxis += [Char]9472 # ─
        }
    }

    # calculate boundaries of the graph
    $TopBoundaryLength      = [Math]::Max(0, $XAxis.Length - $GraphTitle.Length)
    $BottomBoundaryLength   = $XAxis.Length + 2

    # draw top boundary
    Write-Host ([string]::Concat($TopLeft," ",$GraphTitle," ",$([string]$TopEdge * $TopBoundaryLength),$TopRight))
    Write-Host ([String]::Concat($VerticalEdge,$(" "*$($XAxis.length+2)),$VerticalEdge)) # extra line to add space between top-boundary and the graph

    # draw the graph
    For( $i = $NumOfRows; $i -gt 0; $i-- ) {

        $Row = ''

        For( $j = 0; $j -lt $NumOfDatapoints; $j++ ) {

            $Cell = $Array[$i,$j]

            if( [String]::IsNullOrWhiteSpace($Cell) ){
                if( $AddHorizontalLines ) {
                    $String = [Char]9472 # ─
                } else {
                    $String = ' '
                }
            } else {
                $String = $Cell
            }
            $Row = [string]::Concat($Row, $String)

        }

        $YAxisLabel = $StartOfRange + $i * $YAxisStep

        If( $ColorMap ) {

            $Keys       = $ColorMap.Keys | Sort-Object
            $LowerBound = $StartOfRange
            $Map        = @()

            $Map += For( $k = 0; $k -lt $Keys.count; $k++ ) {
                [PSCustomObject]@{
                    LowerBound  = $LowerBound
                    UpperBound  = $Keys[$k]
                    Color       = $ColorMap[$Keys[$k]]
                }
                $LowerBound = $Keys[$k] + 1
            }

            $Color = $Map.ForEach({
                if( $YAxisLabel -ge $_.LowerBound -and $YAxisLabel -le $_.UpperBound ) {
                    $_.Color
                }
            })

            # if out of bounds, use the last color
            if ( [String]::IsNullOrEmpty($Color) ) {
                $Map    = $Map | sort-object -Property UpperBound -Descending
                $Color  = $Map[0].Color
            }

            Write-Graph ' ' $YAxisLabel $Row $Color 'DarkYellow' $LengthOfMaxYAxisLabel

        } else {
            THROW "ColorMap is not defined. Please provide a valid ColorMap hashtable."
        }

    }

    # draw bottom boundary
    $XAxisLabel +=" "*([Math]::Max(0, $XAxis.Length-$XAxisLabel.Length)) # to match x-axis label length with x-axis length
    Write-Host([String]::Concat($VerticalEdge,$XAxis,"  ",$VerticalEdge)) # Prints X-Axis horizontal line
    Write-Host([string]::Concat($VerticalEdge,$XAxisLabel,"  ",$VerticalEdge)) # Prints X-Axis step labels

    # bottom boundary
    Write-Host([string]::Concat($BottomLeft,$([string]$BottomEdge * $BottomBoundaryLength),$BottomRight))

}
