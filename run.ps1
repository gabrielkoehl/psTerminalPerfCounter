import-module -fullyqualifiedname .\psTerminalPerfCounter\psTerminalPerfCounter.psd1 -force
#start-tpcMonitor -config disk
#Get-tpcAvailableCounterConfig

Get-tpcConfigPaths

# Add-tpcConfigPath C:\Test1 -force
# Add-tpcConfigPath C:\Test2 -force

# start-tpcMonitor -configpath "C:\test1\tpc_asdfvsdaf.json"
Get-tpcAvailableCounterConfig

Remove-tpcConfigPath

# start-tpcMonitor


#Remove-tpcConfigPath -all