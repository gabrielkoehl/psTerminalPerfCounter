  # dotnet build "src\lib\psTPCLIB.sln"





  #  Copy-Item "src\lib\psTPCCLASSES\bin\Debug\net9.0\psTPCCLASSES.dll" "src\psTerminalPerCounter\psTerminalPerfCounter\Lib"
  #  Copy-Item "src\lib\psTPCCLASSES\bin\Debug\net9.0\psTPCCLASSES.deps.json" "src\psTerminalPerCounter\psTerminalPerfCounter\Lib"

  import-module -fullyqualifiedname ".\src\psTerminalPerCounter\psTerminalPerfCounter\psTerminalPerfCounter.psd1" -force


#start-tpcmonitor -RemoteServerConfig ".\_remoteconfigs\AD_SERVER_001.json" -showconsoletable

#start-tpcmonitor -ComputerName DEV-NODE3 -ConfigName CPU

start-tpcMonitor -ConfigName CPU

#Start-tpcEnvironmentMonitor -ConfigPath ".\_remoteconfigs\AD_SERVER_001.json"