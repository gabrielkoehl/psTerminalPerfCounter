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
                    $ColorMap
    )

    Function Format-YAxisValue {
        param([int]$Value)

        if ($Value -ge 1000000) {
            return "{0:0.0}M" -f ($Value / 1000000)
        }
        elseif ($Value -ge 1000) {
            return "{0:0.0}k" -f ($Value / 1000)
        }
        else {
            return $Value.ToString()
        }
    }

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

    # Calculate maximum Y value width for formatting
    $MaxYValueWidth = 1
    for ($i = 1; $i -le $NumOfRows; $i++) {
        $YValue = $StartOfRange + $i * $YAxisStep
        $FormattedLength = (Format-YAxisValue -Value $YValue).Length
        if ($FormattedLength -gt $MaxYValueWidth) {
            $MaxYValueWidth = $FormattedLength
        }
    }

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
    $XAxisText  = " " * ($MaxYValueWidth + 4)
    $XAxis      = " " * ($MaxYValueWidth + 3) + [char]9492 # └

    For ( $Index = 1; $Index -le $NumOfDatapoints; $Index++ ) {

        if ( [math]::floor($Index/$XAxisStep) ){
            $TimeValue      = $NumOfDatapoints - $Index + 1
            $XAxisText     += $TimeValue.tostring().PadLeft($Increment)
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

        $CurrentYValue      = $StartOfRange + $i * $YAxisStep
        $FormattedYValue    = Format-YAxisValue -Value $CurrentYValue

        If( $ColorMap ) {

            $Color = $null

            foreach ( $entry in $ColorMap ) {
                if ( $CurrentYValue -lt $entry.Key ) {
                    $Color = $entry.Value
                    break
                }
            }

            # if out of bounds, use the last color
            if ( [string]::IsNullOrEmpty($Color) ) {
                $Color = $ColorMap[-1].Value
            }

            Write-Graph ' ' $FormattedYValue $Row $Color 'DarkYellow' $MaxYValueWidth

        } else {
            THROW "ColorMap is not defined. Please provide a valid ColorMap."
        }

    }

    # draw bottom boundary
    $XAxisText +=" "*([Math]::Max(0, $XAxis.Length-$XAxisText.Length)) # to match x-axis label length with x-axis length
    Write-Host([String]::Concat($VerticalEdge,$XAxis,"  ",$VerticalEdge)) # Prints X-Axis horizontal line
    Write-Host([string]::Concat($VerticalEdge,$XAxisText,"  ",$VerticalEdge)) # Prints X-Axis step labels

    # bottom boundary
    Write-Host([string]::Concat($BottomLeft,$([string]$BottomEdge * $BottomBoundaryLength),$BottomRight))

}
