Function Write-Graph {
    [CmdletBinding()]
    Param(
        [string]    $YAxisLabelAlphabet,
        [string]    $YAxisValue,
        [string]    $Row,
        [string]    $RowColor,
        [string]    $LabelColor,
        [int]       $MaxYValueWidth
    )

    # If MaxYValueWidth is not provided, calculate it
    if ( -not $MaxYValueWidth ) {
        $MaxYValueWidth = $YAxisValue.ToString().Length
    }

    Write-Host -Object $([char]9474) -NoNewline
    Write-Host -Object $YAxisLabelAlphabet -ForegroundColor $LabelColor -NoNewline
    Write-Host -Object "$($YAxisValue.tostring().PadLeft($MaxYValueWidth+2) + [Char]9508)" -NoNewline
    Write-Host -Object $Row -ForegroundColor $RowColor -NoNewline
    Write-Host -Object "  " -NoNewline
    Write-Host -Object $([char]9474)

}

Function Get-AdaptiveYAxisStep {
    [CmdletBinding()]
    [OutputType([int])]
    param(
        [hashtable] $GraphConfiguration = @{}
    )

    # If YAxisStep is explicitly configured in GraphConfiguration, use it
    if ( $GraphConfiguration.ContainsKey('YAxisStep') -and $GraphConfiguration.YAxisStep -gt 0 ) {
        return $GraphConfiguration.YAxisStep
    } else {
        return 1
    }

}
