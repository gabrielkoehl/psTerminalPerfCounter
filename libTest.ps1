Add-Type -Path "src\lib\psTPCCLASSES\bin\Debug\net9.0\psTPCCLASSES.dll"

$json = Get-Content "src\psTerminalPerCounter\psTerminalPerfCounter\Config\tpc_CPU.json" -Raw | ConvertFrom-Json

# Erstelle ALLE Counter-Instanzen VORHER
$instances = [System.Collections.Generic.List[psTPCCLASSES.CounterConfiguration]]::new()

foreach ($cfg in $json.counters) {
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

    $instances.Add($counter)
}

function run {
    # Parallel alle auf einmal abfragen - gibt Dictionary zurück
    $results = [psTPCCLASSES.CounterConfiguration]::GetValuesParallel($instances)

    # Timestamp für alle Counter gleich
    $timestamp = Get-Date

    # Ergebnisse ausgeben
    foreach ($counter in $instances) {
        Write-Host "`n--- $($counter.Title) ---" -ForegroundColor Cyan
        Write-Host "Path: $($counter.CounterPath)"
        Write-Host "Available: $($counter.IsAvailable)"

        if ($counter.IsAvailable) {
            $result = $results[$counter.CounterID]
            Write-Host "Value: $($result['counterValue']) $($counter.Unit)" -ForegroundColor Green

            if ($null -ne $result['duration']) {
                Write-Host "Duration: $($result['duration']) ms" -ForegroundColor Gray
            }
        }
    }
}

run