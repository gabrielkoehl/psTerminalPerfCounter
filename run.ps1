import-module -fullyqualifiedname .\psTerminalPerfCounter\psTerminalPerfCounter.psd1 -force


# start-tpcmonitor -RemoteServerConfig ".\_remoteconfigs\AD_SERVER_001.json"

start-tpcmonitor -ComputerName dev-dc -ConfigName Disk