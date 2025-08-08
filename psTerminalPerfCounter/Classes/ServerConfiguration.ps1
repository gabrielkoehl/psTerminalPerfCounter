using namespace System.Collections.Generic

class ServerConfiguration {
    [string]                $serverName

    ServerConfiguration([string]$serverName) {
        $this.serverName     = $serverName
    }

}