function Get-SparklineThreeLines {
    param(
        [Parameter(Mandatory=$true)]
        [double[]]$Values
    )

    $blocks = @(
        [char]0x00A0, [char]0x2581, [char]0x2582, [char]0x2583,
        [char]0x2584, [char]0x2585, [char]0x2586, [char]0x2587, [char]0x2588
    )

    $min = ($Values | Measure-Object -Minimum).Minimum
    $max = ($Values | Measure-Object -Maximum).Maximum
    $range = $max - $min

    $line1 = "" # Oben (17-24)
    $line2 = "" # Mitte (9-16)
    $line3 = "" # Unten (0-8)

    foreach ($v in $Values) {
        # Normierung auf 0 bis 24
        $totalIndex = if ($range -eq 0) { 12 } else {
            [int][Math]::Round((($v - $min) / $range) * 24)
        }

        # Untere Zeile (0-8)
        $l3Index = [Math]::Min($totalIndex, 8)
        $line3 += $blocks[$l3Index]

        # Mittlere Zeile (9-16)
        $l2Index = [Math]::Max(0, [Math]::Min($totalIndex - 8, 8))
        $line2 += $blocks[$l2Index]

        # Obere Zeile (17-24)
        $l1Index = [Math]::Max(0, $totalIndex - 16)
        $line1 += $blocks[$l1Index]
    }

    return @($line1, $line2, $line3)
}

# --- Demonstration mit einer komplexeren Kurve ---
$data = 0..60 | ForEach-Object {
    [Math]::Sin($_ / 10) * 20 + [Math]::Cos($_ / 3) * 5 + 25
}
$lines = Get-SparklineThreeLines -Values $data

Write-Host "Dreizeilige Sparkline (Hohe Auflösung):" -ForegroundColor Yellow
$lines[0]
$lines[1]
$lines[2]