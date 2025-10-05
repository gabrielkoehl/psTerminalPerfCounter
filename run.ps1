import-module -fullyqualifiedname .\psTerminalPerfCounter\psTerminalPerfCounter.psd1 -force


#start-tpcmonitor -RemoteServerConfig ".\_remoteconfigs\AD_SERVER_001.json" -showconsoletable

start-tpcmonitor -ComputerName dev-dc -ConfigName CPU

#start-tpcMonitor -ConfigName CPU

# BEI REMOTE GESAMTHEITLICHES INTERVALL SETZEN