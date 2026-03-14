# creates hashtable with centered column header names

function New-TuiColumnNames {
    [OutputType([hashtable])]
    param()

    return @{
        Computer = Format-TuiCenter "Computer"  14
        Counter  = Format-TuiCenter "Counter"   20
        Unit     = Format-TuiCenter "Unit"       8
        Current  = Format-TuiCenter "Current"   12
        Last5    = Format-TuiCenter "Last 5"    44
        Min      = Format-TuiCenter "Min"       12
        Max      = Format-TuiCenter "Max"       12
        Avg      = Format-TuiCenter "Avg"       12
        Samples  = Format-TuiCenter "Samples"   10
        Duration = Format-TuiCenter "Duration"  13
    }
}
