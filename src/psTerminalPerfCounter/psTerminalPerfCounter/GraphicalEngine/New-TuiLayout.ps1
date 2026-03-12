# builds the full UI layout (window, frames, labels, buttons) and returns a state hashtable

function New-TuiLayout {
    [OutputType([hashtable])]
    param(
        [System.Data.DataTable] $DataTable,
        [hashtable]             $ColumnNames
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

    #region Table Area

    $tableFrame = [Terminal.Gui.FrameView]@{
        Title  = "Counter Summary"
        X      = 0
        Y      = 2
        Width  = [Terminal.Gui.Dim]::Fill()
        Height = [Terminal.Gui.Dim]::Percent(40)
    }

    # TableView widget to display DataTable
    $tableView = [Terminal.Gui.TableView]@{
        X             = 0
        Y             = 0
        Width         = [Terminal.Gui.Dim]::Fill()
        Height        = [Terminal.Gui.Dim]::Fill()
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
    }

    # apply column styles by ordinal index
    foreach ($colName in $columnStyles.Keys) {
        $colIdx = $DataTable.Columns[$colName].Ordinal
        $tableView.Style.ColumnStyles[$colIdx] = $columnStyles[$colName]
    }

    $tableFrame.Add($tableView)
    $window.Add($tableFrame)

    #endregion

    #region Sparkline Area

    $chartFrame = [Terminal.Gui.FrameView]@{
        Title  = "Sparklines (Live-View)"
        X      = 0
        Y      = [Terminal.Gui.Pos]::Bottom($tableFrame)
        Width  = [Terminal.Gui.Dim]::Fill()
        Height = [Terminal.Gui.Dim]::Fill(3)
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

    #endregion

    #region Button Area

    $btnPause = [Terminal.Gui.Button]@{
        Text = "|| Pause"
        X    = 1
        Y    = [Terminal.Gui.Pos]::Bottom($chartFrame)
    }

    $btnToggle = [Terminal.Gui.Button]@{
        Text = "Sparklines on/off"
        X    = [Terminal.Gui.Pos]::Right($btnPause) + 2
        Y    = [Terminal.Gui.Pos]::Bottom($chartFrame)
    }

    $btnQuit = [Terminal.Gui.Button]@{
        Text = "Quit"
        X    = [Terminal.Gui.Pos]::Right($btnToggle) + 2
        Y    = [Terminal.Gui.Pos]::Bottom($chartFrame)
    }

    $window.Add($btnPause)
    $window.Add($btnToggle)
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
