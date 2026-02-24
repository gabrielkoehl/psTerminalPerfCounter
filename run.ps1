import-module -fullyqualifiedname ".\src\psTerminalPerfCounter\psTerminalPerfCounter\psTerminalPerfCounter.psd1" -force


#start-tpcmonitor -ComputerName lab-node1 -ConfigName CPU

 #Start-tpcMonitor  -ComputerName 'lab-node1' -ConfigPath 'C:\syncthing\gabi_development\repositories\psTerminalPerfCounter\src\psTerminalPerfCounter\psTerminalPerfCounter\Config\tpc_cpu.json'

start-tpcMonitor -ConfigName CPU

#Start-tpcEnvironmentMonitor -ConfigPath "src\psTerminalPerfCounter\psTerminalPerfCounter\Config\ENV_SERVER_EXAMPLE.json"