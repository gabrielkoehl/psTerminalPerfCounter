# updates the header label with session information

function Update-TuiHeader {
    [OutputType([void])]
    param(
        [Terminal.Gui.Label] $HeaderLabel,
        [string]   $ConfigName,
        [datetime] $StartTime,
        [int]      $CounterCount,
        [int]      $SampleCount,
        [bool]     $IsPaused,
        [int]      $Interval
    )

    $now    = Get-Date -Format "HH:mm:ss"
    $paused = if ($IsPaused) { "  [PAUSED]" } else { "" }

    $HeaderLabel.Text = " Session: $($StartTime.ToString('dd.MM.yyyy HH:mm:ss'))  |  Intervall: ${Interval}s  |  Counter: $CounterCount  |  Samples: $SampleCount  |  Update: $now$paused"
}
