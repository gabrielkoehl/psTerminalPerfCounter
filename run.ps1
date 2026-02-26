import-module -fullyqualifiedname ".\src\psTerminalPerfCounter\psTerminalPerfCounter\psTerminalPerfCounter.psd1" -force


#start-tpcmonitor -ComputerName lab-node1 -ConfigName CPU

 #Start-tpcMonitor  -ComputerName 'lab-node1' -ConfigPath 'C:\syncthing\gabi_development\repositories\psTerminalPerfCounter\src\psTerminalPerfCounter\psTerminalPerfCounter\Config\tpc_cpu.json'

start-tpcMonitor -ConfigPath 'C:\syncthing\gabi_development\repositories\psTerminalPerfCounter\example_configs\tpc_SystemOverview.json'

#Start-tpcEnvironmentMonitor -EnvConfigPath "src\psTerminalPerfCounter\psTerminalPerfCounter\Config\ENV_SERVER_EXAMPLE.json"

# Test-tpcAvailableCounterConfig
