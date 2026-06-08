# returns the 9 unicode block characters used for sparkline rendering

function New-TuiSparkBlocks {
    [OutputType([char[]])]
    param()

    # Space + U+2581 (lower one eighth) through U+2588 (full block)
    return @(' ', [char]0x2581, [char]0x2582, [char]0x2583, [char]0x2584,
             [char]0x2585, [char]0x2586, [char]0x2587, [char]0x2588)
}
