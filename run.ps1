# dotnet build "src\lib\psTPCLIB.sln"
# Copy-Item "src\lib\psTPCCLASSES\bin\Debug\net8.0\psTPCCLASSES.dll" "src\psTerminalPerfCounter\psTerminalPerfCounter\Lib"
# Copy-Item "src\lib\psTPCCLASSES\bin\Debug\net8.0\psTPCCLASSES.deps.json" "src\psTerminalPerfCounter\psTerminalPerfCounter\Lib"

import-module -fullyqualifiedname ".\src\psTerminalPerfCounter\psTerminalPerfCounter\psTerminalPerfCounter.psd1" -force


start-tpcmonitor -ComputerName lab-node2 -ConfigName CPU

#start-tpcMonitor -ConfigName CPU

#Start-tpcEnvironmentMonitor -ConfigPath "src\psTerminalPerfCounter\psTerminalPerfCounter\Config\ENV_SERVER_EXAMPLE.json"