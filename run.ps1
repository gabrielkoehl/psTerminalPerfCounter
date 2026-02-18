import-module -fullyqualifiedname ".\src\psTerminalPerfCounter\psTerminalPerfCounter\psTerminalPerfCounter.psd1" -force


#start-tpcmonitor -ComputerName lab-node1 -ConfigName CPU

Start-tpcMonitor -ConfigName disk

#start-tpcMonitor -ConfigName CPU

#Start-tpcEnvironmentMonitor -ConfigPath "src\psTerminalPerfCounter\psTerminalPerfCounter\Config\ENV_SERVER_EXAMPLE.json"