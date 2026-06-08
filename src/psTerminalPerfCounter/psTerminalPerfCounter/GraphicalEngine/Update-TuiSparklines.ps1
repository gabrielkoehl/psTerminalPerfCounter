# updates the sparkline label for all counters

function Update-TuiSparklines {
    [OutputType([void])]
    param(
        [Terminal.Gui.Label] $SparkLabel,
        [System.Collections.Generic.List[psTPCCLASSES.CounterConfiguration]] $Counters,
        [char[]]  $SparkBlocks,
        [bool]    $ShowSparklines
    )

    if (-not $ShowSparklines) {
        $SparkLabel.Text = " [Sparklines disabled]"
        return
    }

    # calculate dynamic sparkline width based on available label width
    $availableWidth = $SparkLabel.Bounds.Width
    if ($availableWidth -le 0) { $availableWidth = 115 }  # fallback before first layout pass

    $labelWidth    = 35
    $reservedWidth = 49   # prefix (39 chars) + suffix (10 chars for value)
    $dynamicMaxWidth = $availableWidth - $reservedWidth
    if ($dynamicMaxWidth -lt 10) { $dynamicMaxWidth = 10 }

    $lines       = [System.Collections.Generic.List[string]]::new()
    $prefixEmpty = " " * 39  # empty prefix for top and bottom sparkline rows

    for ($i = 0; $i -lt $Counters.Count; $i++) {
        $c = $Counters[$i]

        # generate 3-row sparkline for this counter
        $sparkRows = Get-TuiSparkline3Row -Data $c.HistoricalData -MaxWidth $dynamicMaxWidth -SparkBlocks $SparkBlocks

        # label: PC name on row 2, counter name on row 3 (bottom)
        $descLine1 = "$($c.ComputerName)".PadRight($labelWidth)
        $descLine2 = "$($c.Title) ($($c.Unit))".PadRight($labelWidth)

        # current value right-aligned
        $valStr = if ($c.Statistics.ContainsKey('Current')) { $c.Statistics['Current'].ToString("F$($c.DecimalPlaces)").PadLeft(8) } else { " - " }

        # row 1 (top): sparkline only, indented
        $lines.Add($prefixEmpty + $sparkRows[0])
        # row 2 (mid): label line 1 + sparkline + current value
        $lines.Add(" # $descLine1 " + $sparkRows[1] + "  " + $valStr)
        # row 3 (bottom): counter name + sparkline
        $lines.Add("   $descLine2 " + $sparkRows[2])

        # blank separator between counters (not after last)
        if ($i -lt $Counters.Count - 1) { $lines.Add("") }
    }

    $SparkLabel.Text = $lines -join "`n"
}
