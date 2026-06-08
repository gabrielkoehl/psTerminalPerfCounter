# builds the full UI layout (window, frames, labels, buttons) and returns a state hashtable

function New-TuiLayout {
    [OutputType([hashtable])]
    param(
        [System.Data.DataTable] $DataTable,
        [hashtable]             $ColumnNames,
        # when $false (e.g. multi-server environment) the sparkline area is omitted and the table fills the window
        [bool]                  $ShowGraphs   = $true,
        # number of counters; used to scale the sparkline area to its content
        [int]                   $CounterCount = 0
    )

    # main window
    $window = [Terminal.Gui.Window]@{
        Title  = "psTerminalPerfCounter Monitor"
        Width  = [Terminal.Gui.Dim]::Fill()
        Height = [Terminal.Gui.Dim]::Fill()
    }

    # header label: session info, 2 rows height
    $headerLabel = [Terminal.Gui.Label]@{
        X      = 1
        Y      = 0
        Width  = [Terminal.Gui.Dim]::Fill(1)
        Height = 2
    }
    $window.Add($headerLabel)

    # sparkline area height scales with the number of counters (3 rows + 1 separator each),
    # clamped to a sane range so few counters do not waste space and many do not eat the screen
    $sparkHeight = [Math]::Min([Math]::Max(($CounterCount * 4 + 1), 6), 20)

    #region Table Area

    # TableView widget to display DataTable.
    # With sparklines: leave room for the sparkline frame + button row below.
    # Without sparklines (multi-server): table fills down to just above the buttons.
    $tableHeight = if ( $ShowGraphs ) {
        [Terminal.Gui.Dim]::Fill($sparkHeight + 3)
    } else {
        [Terminal.Gui.Dim]::Fill(3)
    }

    $tableView = [Terminal.Gui.TableView]@{
        X             = 0
        Y             = 2
        Width         = [Terminal.Gui.Dim]::Fill()
        Height        = $tableHeight
        FullRowSelect = $true
        Table         = $DataTable
    }

    # fixed column widths via ColumnStyle
    $columnStyles = @{
        $ColumnNames.Computer = [Terminal.Gui.TableView+ColumnStyle]@{ MinWidth = 14; MaxWidth = 14 }
        $ColumnNames.Counter  = [Terminal.Gui.TableView+ColumnStyle]@{ MinWidth = 20; MaxWidth = 20 }
        $ColumnNames.Unit     = [Terminal.Gui.TableView+ColumnStyle]@{ MinWidth = 8;  MaxWidth = 8  }
        $ColumnNames.Current  = [Terminal.Gui.TableView+ColumnStyle]@{ MinWidth = 12; MaxWidth = 12 }
        $ColumnNames.Last5    = [Terminal.Gui.TableView+ColumnStyle]@{ MinWidth = 44; MaxWidth = 44 }
        $ColumnNames.Min      = [Terminal.Gui.TableView+ColumnStyle]@{ MinWidth = 12; MaxWidth = 12 }
        $ColumnNames.Max      = [Terminal.Gui.TableView+ColumnStyle]@{ MinWidth = 12; MaxWidth = 12 }
        $ColumnNames.Avg      = [Terminal.Gui.TableView+ColumnStyle]@{ MinWidth = 12; MaxWidth = 12 }
        $ColumnNames.Samples  = [Terminal.Gui.TableView+ColumnStyle]@{ MinWidth = 10; MaxWidth = 10 }
        $ColumnNames.Duration = [Terminal.Gui.TableView+ColumnStyle]@{ MinWidth = 9;  MaxWidth = 9  }
    }

    # apply column styles by ordinal index
    foreach ($colName in $columnStyles.Keys) {
        $colIdx = $DataTable.Columns[$colName].Ordinal
        $tableView.Style.ColumnStyles[$colIdx] = $columnStyles[$colName]
    }

    #$tableFrame.Add($tableView)
    $window.Add($tableView)

    #endregion

    #region Sparkline Area (single-server only)

    $sparkLabel = $null
    $btnToggle  = $null
    # buttons are anchored below the sparkline frame when present, otherwise below the table
    $buttonAnchor = $tableView

    if ( $ShowGraphs ) {

        $chartFrame = [Terminal.Gui.FrameView]@{
            Title  = "Sparklines (Live-View)"
            X      = 0
            Y      = [Terminal.Gui.Pos]::Bottom($tableView)
            Width  = [Terminal.Gui.Dim]::Fill()
            Height = $sparkHeight
        }

        # label holding sparkline unicode characters as text
        $sparkLabel = [Terminal.Gui.Label]@{
            X      = 1
            Y      = 0
            Width  = [Terminal.Gui.Dim]::Fill(1)
            Height = [Terminal.Gui.Dim]::Fill()
        }

        $chartFrame.Add($sparkLabel)
        $window.Add($chartFrame)

        $buttonAnchor = $chartFrame
    }

    #endregion

    #region Button Area

    $btnPause = [Terminal.Gui.Button]@{
        Text = "|| Pause"
        X    = 1
        Y    = [Terminal.Gui.Pos]::Bottom($buttonAnchor)
    }
    $window.Add($btnPause)

    $lastButton = $btnPause

    # sparkline toggle only makes sense when sparklines are shown
    if ( $ShowGraphs ) {
        $btnToggle = [Terminal.Gui.Button]@{
            Text = "Sparklines on/off"
            X    = [Terminal.Gui.Pos]::Right($btnPause) + 2
            Y    = [Terminal.Gui.Pos]::Bottom($buttonAnchor)
        }
        $window.Add($btnToggle)
        $lastButton = $btnToggle
    }

    $btnQuit = [Terminal.Gui.Button]@{
        Text = "Quit"
        X    = [Terminal.Gui.Pos]::Right($lastButton) + 2
        Y    = [Terminal.Gui.Pos]::Bottom($buttonAnchor)
    }
    $window.Add($btnQuit)

    #endregion

    return @{
        Window      = $window
        HeaderLabel = $headerLabel
        TableView   = $tableView
        SparkLabel  = $sparkLabel
        BtnPause    = $btnPause
        BtnToggle   = $btnToggle
        BtnQuit     = $btnQuit
    }
}
