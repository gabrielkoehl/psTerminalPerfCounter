# registers button click handlers and the timer callback

function Register-TuiEventHandlers {
    [OutputType([void])]
    param(
        [hashtable]             $Layout,
        [hashtable]             $TuiState,
        [System.Collections.Generic.List[psTPCCLASSES.CounterConfiguration]] $Counters,
        [hashtable]             $ColumnNames,
        [System.Data.DataTable] $DataTable,
        [char[]]                $SparkBlocks,
        [int]                   $Interval,
        [switch]                $ExportCsv,
        [string]                $CsvPath
    )

    # pause/resume button
    $Layout.BtnPause.add_Clicked({
        $TuiState.IsPaused = -not $TuiState.IsPaused
        $Layout.BtnPause.Text = if ($TuiState.IsPaused) { ">> Resume" } else { "|| Pause" }
        Update-TuiHeader -HeaderLabel $Layout.HeaderLabel -ConfigName $TuiState.ConfigName `
                         -StartTime $TuiState.StartTime -CounterCount $Counters.Count `
                         -SampleCount $TuiState.SampleCount -IsPaused $TuiState.IsPaused `
                         -Interval $Interval
    })

    # toggle sparkline visibility
    $Layout.BtnToggle.add_Clicked({
        $TuiState.ShowSparklines = -not $TuiState.ShowSparklines
        Update-TuiSparklines -SparkLabel $Layout.SparkLabel -Counters $Counters `
                             -SparkBlocks $SparkBlocks -ShowSparklines $TuiState.ShowSparklines
    })

    # quit button
    $Layout.BtnQuit.add_Clicked({
        [Terminal.Gui.Application]::RequestStop()
    })

    # periodic timer for data collection and UI refresh
    $timerCallback = [Func[Terminal.Gui.MainLoop, bool]]{
        param($mainLoop)

        if ($TuiState.IsPaused) { return $true }

        # collect real performance counter data
        [psTPCCLASSES.CounterConfiguration]::GetValuesBatched($Counters)

        $TuiState.SampleCount++

        # optional CSV export
        if ($TuiState.ExportCsv) {
            $csvFilePath = Join-Path $TuiState.CsvPath "psTPC_$($TuiState.ConfigName)_$(Get-Date -Format 'ddMMyy').csv"
            [psTPCCLASSES.CounterConfiguration]::ExportCsv($Counters, $csvFilePath)
        }

        # refresh all UI elements
        Update-TuiHeader -HeaderLabel $Layout.HeaderLabel -ConfigName $TuiState.ConfigName `
                         -StartTime $TuiState.StartTime -CounterCount $Counters.Count `
                         -SampleCount $TuiState.SampleCount -IsPaused $false -Interval $Interval

        Update-TuiTable -DataTable $DataTable -TableView $Layout.TableView `
                        -Counters $Counters -ColumnNames $ColumnNames

        Update-TuiSparklines -SparkLabel $Layout.SparkLabel -Counters $Counters `
                             -SparkBlocks $SparkBlocks -ShowSparklines $TuiState.ShowSparklines

        return $true  # keep timer running
    }

    $null = [Terminal.Gui.Application]::MainLoop.AddTimeout(
        [TimeSpan]::FromSeconds($Interval), $timerCallback
    )
}
