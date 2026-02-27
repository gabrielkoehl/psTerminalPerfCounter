function Show-CounterGraph {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [psTPCCLASSES.CounterConfiguration] $Counter
    )

    $Config     = $Counter.GraphConfiguration
    $GraphData  = $Counter.GetGraphData($Config.Samples)

    if ( $GraphData.Count -eq 0 ) {
        Write-Host "$($Counter.GetFormattedTitle()): No data available" -ForegroundColor Yellow
        return
    }

    # Show graph
    $GraphParams = @{
        Datapoints      = $GraphData
        GraphTitle      = $Counter.GetFormattedTitle()
        Type            = $Config.graphType
        YAxisStep       = $Config.yAxisStep
        yAxisMaxRows    = $Config.yAxisMaxRows
    }

    if ( $Counter.ColorMap.Count -gt 0 ) {
        $GraphParams.ColorMap = $Counter.ColorMap
    }

    Show-Graph @GraphParams

    # Show statistics if enabled
    if ( $Config.showStatistics -and $Counter.Statistics.Count -gt 0 ) {
        Show-CounterStatistic -Counter $Counter
    }

    # spacing between graphs
    Write-Host ""
    Write-Host ""

}
