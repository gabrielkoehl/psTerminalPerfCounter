function Show-SessionHeader {
    [CmdletBinding()]
    param(
        [datetime]  $StartTime,
        [int]       $SampleCount,
        [string]    $ConfigName
    )

    Clear-Host

    $TitleColor = "Cyan"

    Write-Host "=== Terminal Performance Counter ===" -ForegroundColor $TitleColor
    $Runtime = (Get-Date) - $StartTime
    Write-Host "Runtime: $($Runtime.ToString("hh\:mm\:ss")) | Samples: $SampleCount | Config: $ConfigName" -ForegroundColor White
    Write-Host "Press Ctrl+C to exit" -ForegroundColor Yellow
    Write-Host ""

}
