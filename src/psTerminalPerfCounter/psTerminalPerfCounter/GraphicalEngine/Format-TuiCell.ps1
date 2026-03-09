# padding 1 space, text left, int right

function Format-TuiCell {
    [OutputType([string])]
    param(
        [string]    $Text,
        [int]       $Width,
        [switch]    $Left
    )

    $inner = if ($Left) { $Text.PadRight($Width) } else { $Text.PadLeft($Width) }
    return " $inner "

}