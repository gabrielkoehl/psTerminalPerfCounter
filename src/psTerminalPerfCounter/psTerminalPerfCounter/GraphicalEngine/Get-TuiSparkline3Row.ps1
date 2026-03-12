# generates 3 rows (top/mid/bottom) of sparkline characters from historical data

function Get-TuiSparkline3Row {
    [OutputType([string[]])]
    param(
        [System.Collections.Generic.List[psTPCCLASSES.CounterConfiguration+DataPoint]] $Data,
        [int]    $MaxWidth = 60,
        [char[]] $SparkBlocks
    )

    # empty data -> 3 empty lines padded to MaxWidth
    if ($Data.Count -eq 0) {
        $empty = " " * $MaxWidth
        return @($empty, $empty, $empty)
    }

    # take only the last $MaxWidth data points (newest on the right)
    $values = $Data | Select-Object -Last $MaxWidth | ForEach-Object { $_.Value }
    $min   = ($values | Measure-Object -Minimum).Minimum
    $max   = ($values | Measure-Object -Maximum).Maximum
    $range = $max - $min

    $topLine = ""; $midLine = ""; $bottomLine = ""

    # left-pad with spaces if fewer data points than width (graph grows from right)
    $padCount = $MaxWidth - @($values).Count
    if ($padCount -gt 0) {
        $padStr      = " " * $padCount
        $topLine    += $padStr
        $midLine    += $padStr
        $bottomLine += $padStr
    }

    foreach ($val in $values) {
        # normalize value to level 0..23 (3 rows x 8 block levels)
        $level = if ($range -gt 0) {
            [int][Math]::Floor((($val - $min) / $range) * 23.999)
        } else {
            0   # constant value -> minimal height (thin flat line)
        }
        $level = [Math]::Clamp($level, 0, 23)

        # distribute level across 3 rows
        if ($level -ge 16) {
            $bottomIdx = 8                  # full block
            $midIdx    = 8                  # full block
            $topIdx    = $level - 16 + 1    # partial block 1-8
        } elseif ($level -ge 8) {
            $bottomIdx = 8                  # full block
            $midIdx    = $level - 8 + 1     # partial block 1-8
            $topIdx    = 0                  # empty
        } else {
            $bottomIdx = $level + 1         # partial block 1-8
            $midIdx    = 0                  # empty
            $topIdx    = 0                  # empty
        }

        $bottomLine += $SparkBlocks[$bottomIdx]
        $midLine    += $SparkBlocks[$midIdx]
        $topLine    += $SparkBlocks[$topIdx]
    }

    return @($topLine, $midLine, $bottomLine)
}
