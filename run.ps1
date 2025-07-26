import-module -fullyqualifiedname .\psTerminalPerfCounter\psTerminalPerfCounter.psd1 -force
start-tpcMonitor -config disk
#Get-tpcAvailableCounterConfig