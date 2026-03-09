function Show-TuiMainApplication {
    [CmdletBinding()]
    param (
        [Parameter()]
        [TypeName]
        $ParameterName
    )

    [Terminal.Gui.Application]::Init()

    # Main Windows properties
    $window = [Terminal.Gui.Window]@{
        Title   = "psTerminalPerfCounter Monitor";
        Width   = [Terminal.Gui.Dim]::Fill();
        Height  = [Terminal.Gui.Dim]::Fill()
    }

    # Header-Label: Shows session information, 2 rows height
    $headerLabel = [Terminal.Gui.Label]@{
        X       = 1;
        Y       = 0;
        Width   = [Terminal.Gui.Dim]::Fill(1); # 1 = margin 1 left & right
        Height  = 2
    }

    $window.Add($headerLabel)

#region Table Area

    # FrameView = container with visible frame and title

    $tableFrame = [Terminal.Gui.FrameView]@{
        Title   = "Counter Summary";
        X       = 0;
        Y       = 2;
        Width   = [Terminal.Gui.Dim]::Fill();
        Height  = [Terminal.Gui.Dim]::Percent(40) # use 40% of available screen
    }

    # Spaltennamen mit zentrierten Headern definieren
    # Diese werden sowohl als DataTable-Spaltennamen als auch als sichtbare Header benutzt
    $columNames = @{
        Computer = Format-TuiCenter "Computer"  14
        Counter  = Format-TuiCenter "Counter"   20
        Unit     = Format-TuiCenter "Unit"      8
        Aktuell  = Format-TuiCenter "Current"   12
        Last5    = Format-TuiCenter "Last 5"    44
        Min      = Format-TuiCenter "Min"       12
        Max      = Format-TuiCenter "Max"       12
        Avg      = Format-TuiCenter "Avg"       12
        Samples  = Format-TuiCenter "Samples"   10
    }

    # System.Data.DataTable = .NET-Datenstruktur, Terminal.Gui can display table directly

    $dataTable = [System.Data.DataTable]::new()
    [void]$dataTable.Columns.Add($columNames.Computer, [string])
    [void]$dataTable.Columns.Add($columNames.Counter,  [string])
    [void]$dataTable.Columns.Add($columNames.Unit,     [string])
    [void]$dataTable.Columns.Add($columNames.Current,  [string])
    [void]$dataTable.Columns.Add($columNames.Last5,    [string])
    [void]$dataTable.Columns.Add($columNames.Min,      [string])
    [void]$dataTable.Columns.Add($columNames.Max,      [string])
    [void]$dataTable.Columns.Add($columNames.Avg,      [string])
    [void]$dataTable.Columns.Add($columNames.Samples,  [string])

    # TableView: Terminal.Gui-Widget, that display DataTable
    $tableView = [Terminal.Gui.TableView]@{
        X               = 0;
        Y               = 0;
        Width           = [Terminal.Gui.Dim]::Fill();
        Height          = [Terminal.Gui.Dim]::Fill();
        FullRowSelect   = $true;
        Table           = $dataTable
    }

    # Fixed Colum Width
    $columnStyles = @{
        $columNames.Computer = [Terminal.Gui.TableView+ColumnStyle]@{ MinWidth = 14; MaxWidth = 14 }
        $columNames.Counter  = [Terminal.Gui.TableView+ColumnStyle]@{ MinWidth = 20; MaxWidth = 20 }
        $columNames.Unit     = [Terminal.Gui.TableView+ColumnStyle]@{ MinWidth = 8;  MaxWidth = 8  }
        $columNames.Aktuell  = [Terminal.Gui.TableView+ColumnStyle]@{ MinWidth = 12; MaxWidth = 12 }
        $columNames.Last5    = [Terminal.Gui.TableView+ColumnStyle]@{ MinWidth = 44; MaxWidth = 44 }
        $columNames.Min      = [Terminal.Gui.TableView+ColumnStyle]@{ MinWidth = 12; MaxWidth = 12 }
        $columNames.Max      = [Terminal.Gui.TableView+ColumnStyle]@{ MinWidth = 12; MaxWidth = 12 }
        $columNames.Avg      = [Terminal.Gui.TableView+ColumnStyle]@{ MinWidth = 12; MaxWidth = 12 }
        $columNames.Samples  = [Terminal.Gui.TableView+ColumnStyle]@{ MinWidth = 10; MaxWidth = 10 }
    }

    # Match ColumnStyles with TableView vial colum index
    foreach ($colName in $columnStyles.Keys) {
        $colIdx = $dataTable.Columns[$colName].Ordinal
        $tableView.Style.ColumnStyles[$colIdx] = $columnStyles[$colName]
    }

    # Load table in frame and frame ind windows
    $tableFrame.Add($tableView)
    $window.Add($tableFrame)

#endregion

#region Sparkline Area

    # (Pos::Bottom) -> under table, (Fill(3) = Place for buttons
    $chartFrame = [Terminal.Gui.FrameView]@{
        Title   = "Sparklines (Live-View)";
        X       = 0;
        Y       = [Terminal.Gui.Pos]::Bottom($tableFrame);
        Width   = [Terminal.Gui.Dim]::Fill();
        Height  = [Terminal.Gui.Dim]::Fill(3)
    }

    # simple Label for holding Sparkline-Chars as text
    $sparkLabel = [Terminal.Gui.Label]@{
        X = 1;
        Y = 0;
        Width = [Terminal.Gui.Dim]::Fill(1);
        Height = [Terminal.Gui.Dim]::Fill()
    }

    $chartFrame.Add($sparkLabel)
    $window.Add($chartFrame)

#endregion

#region Button Area

    # Pos::Bottom($chartFrame) = under Sparkline-Bereich
    # Pos::Right($btnPause) + 2 = right position of previous button + 2 chars blanks
    $btnPause  = [Terminal.Gui.Button]@{
        Text    = "|| Pause";
        X       = 1;
        Y       = [Terminal.Gui.Pos]::Bottom($chartFrame)
    }

    $btnToggle = [Terminal.Gui.Button]@{
        Text    = "Sparklines on/off";
        X       = [Terminal.Gui.Pos]::Right($btnPause) + 2;
        Y       = [Terminal.Gui.Pos]::Bottom($chartFrame)
    }

    $btnQuit   = [Terminal.Gui.Button]@{
        Text    = "Quit";
        X       = [Terminal.Gui.Pos]::Right($btnToggle) + 2;
        Y       = [Terminal.Gui.Pos]::Bottom($chartFrame)
    }

    $window.Add($btnPause);
    $window.Add($btnToggle);
    $window.Add($btnQuit)

#endregion

}