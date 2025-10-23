Add-Type -Path "src\lib\psTPCCLASSES\bin\Debug\net9.0\psTPCCLASSES.dll"

$json = Get-Content "src\psTerminalPerCounter\psTerminalPerfCounter\Config\tpc_CPU.json" -Raw | ConvertFrom-Json

$cfg = $json.counters[0]

$counter = [psTPCCLASSES.CounterConfiguration]::new(
    $cfg.counterID,
    $cfg.counterSetType,
    $cfg.counterInstance,
    $cfg.title,
    $cfg.type,
    $cfg.format,
    $cfg.unit,
    $cfg.conversionFactor,
    $cfg.conversionExponent,
    $cfg.colorMap,
    $cfg.graphConfiguration,
    $false,
    $env:COMPUTERNAME,
    $null
)

Write-Host "Title: $($counter.Title)" -ForegroundColor Cyan
Write-Host "Path: $($counter.CounterPath)"
Write-Host "Available: $($counter.IsAvailable)"

if ($counter.IsAvailable) {
    $result = $counter.GetCurrentValue()
    Write-Host "Value: $($result[0]) $($counter.Unit)"
}

$(get-counter -Counter "\Processor(_Total)\% Processor Time").CounterSamples.CookedValue