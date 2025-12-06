# ============================================================================
# TEST-SKRIPT: Einzelner Server mit ServerConfiguration.GetValuesParallelAsync()
# ============================================================================
#
# Dieses Skript testet die neue async-Methode der ServerConfiguration-Klasse
# OHNE die komplette Environment-Infrastruktur zu benötigen.
#
# Verwendung:
#   .\TEST_SINGLE_SERVER.ps1
#   .\TEST_SINGLE_SERVER.ps1 -ComputerName "DEV-DC"
#

[CmdletBinding()]
param(
    [string] $ComputerName = 'DEV-NODE3',
    [string] $ConfigName = "CPU",
    [int] $Iterations = 5
)

# Modul importieren
Import-Module .\src\psTerminalPerCounter\psTerminalPerfCounter\psTerminalPerfCounter.psm1 -Force

Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║        ServerConfiguration Async Test                        ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Test-Funktion aufrufen
Test-tpcServerConfiguration -ComputerName $ComputerName -ConfigName $ConfigName -Iterations $Iterations

Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
