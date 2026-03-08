import-module -fullyqualifiedname ".\src\psTerminalPerfCounter\psTerminalPerfCounter\psTerminalPerfCounter.psd1" -force


 # start-tpcmonitor -ConfigName CPU # -exportcsv -csvpath 'C:\Temp'

 # Start-tpcMonitor  -ComputerName 'lab-node1' -ConfigPath 'C:\syncthing\gabi_development\repositories\psTerminalPerfCounter\src\psTerminalPerfCounter\psTerminalPerfCounter\Config\tpc_cpu.json'

  #start-tpcMonitor -ConfigPath 'src\psTerminalPerfCounter\psTerminalPerfCounter\Config\tpc_SystemOverview.json'

 Start-tpcEnvironmentMonitor -EnvConfigPath "example_configs\ENV_SERVER_EXAMPLE.json" -exportcsv -csvpath 'C:\Temp'

# Test-tpcAvailableCounterConfig
