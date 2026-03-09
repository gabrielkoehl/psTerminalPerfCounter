<#
    center TableHeader
#>

function Format-TuiCenter {
    [OutputType([string])]
    param(
        [string]    $Text,
        [int]       $Width
    )

    if ($Text.Length -ge $Width) { return $Text.Substring(0, $Width) }  # trim if too long

    $leftPad    = [int][Math]::Floor(($Width - $Text.Length) / 2.0)     # calculate left padding
    $rightPad   = $Width - $Text.Length - $leftPad                      # right padding

    return (" " * $leftPad) + $Text + (" " * $rightPad)

}