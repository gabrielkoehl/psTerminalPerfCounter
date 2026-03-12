# orchestrator: wires all TUI components together and starts the application

function Show-TuiMainApplication {
    [CmdletBinding()]
    param(
        [System.Collections.Generic.List[psTPCCLASSES.CounterConfiguration]] $Counters,
        [string] $ConfigName,
        [int]    $Interval  = 2,
        [switch] $ExportCsv,
        [string] $CsvPath   = [Environment]::GetFolderPath('Desktop')
    )

    # 1. initialize Terminal.Gui
    [Terminal.Gui.Application]::Init()

    # 2. create spark block characters
    $sparkBlocks = New-TuiSparkBlocks

    # 3. create centered column names
    $columnNames = New-TuiColumnNames

    # 4. create data table with column definitions
    $dataTable = New-TuiDataTable -ColumnNames $columnNames

    # 5. build the full UI layout
    $layout = New-TuiLayout -DataTable $dataTable -ColumnNames $columnNames

    # 6. initialize mutable state object (hashtable = reference type)
    $tuiState = @{
        IsPaused       = $false
        ShowSparklines = $true
        StartTime      = Get-Date
        SampleCount    = 0
        ConfigName     = $ConfigName
        ExportCsv      = [bool]$ExportCsv
        CsvPath        = $CsvPath
    }

    # 7. register button handlers and timer callback (includes data collection)
    Register-TuiEventHandlers -Layout $layout -TuiState $tuiState -Counters $Counters `
                              -ColumnNames $columnNames -DataTable $dataTable `
                              -SparkBlocks $sparkBlocks -Interval $Interval `
                              -ExportCsv:$ExportCsv -CsvPath $CsvPath

    # 8. collect initial data batch
    [psTPCCLASSES.CounterConfiguration]::GetValuesBatched($Counters)

    # 9. initial UI render
    Update-TuiHeader -HeaderLabel $layout.HeaderLabel -ConfigName $ConfigName `
                     -StartTime $tuiState.StartTime -CounterCount $Counters.Count `
                     -SampleCount 0 -IsPaused $false -Interval $Interval

    Update-TuiTable -DataTable $dataTable -TableView $layout.TableView `
                    -Counters $Counters -ColumnNames $columnNames

    Update-TuiSparklines -SparkLabel $layout.SparkLabel -Counters $Counters `
                         -SparkBlocks $sparkBlocks -ShowSparklines $true

    # 10. add window to application and run (blocks until quit)
    [Terminal.Gui.Application]::Top.Add($layout.Window)
    [Terminal.Gui.Application]::Run()

    # 11. restore terminal
    [Terminal.Gui.Application]::Shutdown()
}
