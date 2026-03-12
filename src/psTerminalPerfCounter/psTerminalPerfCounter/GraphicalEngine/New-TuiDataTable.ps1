# creates a System.Data.DataTable with all 9 string columns

function New-TuiDataTable {
    [OutputType([System.Data.DataTable])]
    param(
        [hashtable] $ColumnNames
    )

    $dataTable = [System.Data.DataTable]::new()

    # add all columns as string type
    [void]$dataTable.Columns.Add($ColumnNames.Computer, [string])
    [void]$dataTable.Columns.Add($ColumnNames.Counter,  [string])
    [void]$dataTable.Columns.Add($ColumnNames.Unit,     [string])
    [void]$dataTable.Columns.Add($ColumnNames.Current,  [string])
    [void]$dataTable.Columns.Add($ColumnNames.Last5,    [string])
    [void]$dataTable.Columns.Add($ColumnNames.Min,      [string])
    [void]$dataTable.Columns.Add($ColumnNames.Max,      [string])
    [void]$dataTable.Columns.Add($ColumnNames.Avg,      [string])
    [void]$dataTable.Columns.Add($ColumnNames.Samples,  [string])

    return , $dataTable  # comma prevents PowerShell from enumerating the empty DataTable
}
