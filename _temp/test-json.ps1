$schemaContent = Get-Content 'C:\syncthing\gabi_development\repositories\psTerminalPerfCounter\src\psTerminalPerfCounter\psTerminalPerfCounter\Config\schema_config.json' -Raw
$jsonContent_raw   = Get-Content 'C:\syncthing\gabi_development\repositories\psTerminalPerfCounter\src\psTerminalPerfCounter\psTerminalPerfCounter\Config\tpc_CPU.json' -raw

$jsonContent = $jsonContent_raw | Convertfrom-Json
$jsonContent = $JsonContent | Convertto-Json -depth 10
$validationErrors = @()
$isValid = Test-Json -Json $jsonContent -Schema $schemaContent -ErrorAction SilentlyContinue -ErrorVariable validationErrors

$isValid
$validationErrors | ForEach-Object { $_.Exception.Message }
