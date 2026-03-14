# rebuilds all table rows from counter data

function Update-TuiTable {
    [OutputType([void])]
    param(
        [System.Data.DataTable]  $DataTable,
        [Terminal.Gui.TableView] $TableView,
        [System.Collections.Generic.List[psTPCCLASSES.CounterConfiguration]] $Counters,
        [hashtable] $ColumnNames
    )

    $DataTable.Rows.Clear()

    foreach ($c in $Counters) {
        $stats = $c.Statistics

        $row = $DataTable.NewRow()
        $row[$ColumnNames.Computer] = Format-TuiCell $c.ComputerName 12 -Left
        $row[$ColumnNames.Counter]  = Format-TuiCell $c.Title 18 -Left
        $row[$ColumnNames.Unit]     = Format-TuiCell $c.Unit 6
        $row[$ColumnNames.Current]  = Format-TuiCell $(if ($stats.ContainsKey('Current')) { $stats['Current'].ToString("F$($c.DecimalPlaces)") } else { "-" }) 10
        $row[$ColumnNames.Min]      = Format-TuiCell $(if ($stats.ContainsKey('Minimum')) { $stats['Minimum'].ToString("F1") } else { "-" }) 10
        $row[$ColumnNames.Max]      = Format-TuiCell $(if ($stats.ContainsKey('Maximum')) { $stats['Maximum'].ToString("F1") } else { "-" }) 10
        $row[$ColumnNames.Avg]      = Format-TuiCell $(if ($stats.ContainsKey('Average')) { $stats['Average'].ToString("F1") } else { "-" }) 10
        $row[$ColumnNames.Samples]  = Format-TuiCell $(if ($stats.ContainsKey('Count'))   { $stats['Count'].ToString() } else { "0" }) 8
        $row[$ColumnNames.Duration] = Format-TuiCell "$($c.ExecutionDuration.ToString()) ms" 11

        # last 5 values formatted side by side
        if ($stats.ContainsKey('Last5')) {
            $formattedLast5 = @($stats['Last5'] | ForEach-Object { $_.ToString().PadLeft(6) }) -join " | "
            $row[$ColumnNames.Last5] = " $formattedLast5 "
        } else {
            $row[$ColumnNames.Last5] = " - "
        }

        [void]$DataTable.Rows.Add($row)
    }

    $TableView.Update()
}
