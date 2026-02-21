import-module -fullyqualifiedname ".\src\psTerminalPerfCounter\psTerminalPerfCounter\psTerminalPerfCounter.psd1" -force


#start-tpcmonitor -ComputerName lab-node1 -ConfigName CPU

Start-tpcMonitor  -ComputerName 'dev-main' -ConfigPath 'C:\syncthing\gabi_development\repositories\psTerminalPerfCounter\src\psTerminalPerfCounter\psTerminalPerfCounter\Config\tpc_Disk.json'

#start-tpcMonitor -ConfigName CPU

#Start-tpcEnvironmentMonitor -ConfigPath "src\psTerminalPerfCounter\psTerminalPerfCounter\Config\ENV_SERVER_EXAMPLE.json"