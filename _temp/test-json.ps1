$schemaContent = Get-Content 'C:\syncthing\gabi_development\repositories\psTerminalPerfCounter\src\psTerminalPerfCounter\psTerminalPerfCounter\Config\schema_config.json' -Raw
$jsonContent   = Get-Content 'C:\syncthing\gabi_development\repositories\psTerminalPerfCounter\src\psTerminalPerfCounter\psTerminalPerfCounter\Config\tpc_CPU.json' -Raw

$validationErrors = @()
$isValid = Test-Json -Json $jsonContent -Schema $schemaContent -ErrorAction SilentlyContinue -ErrorVariable validationErrors

$isValid
$validationErrors | ForEach-Object { $_.Exception.Message }
