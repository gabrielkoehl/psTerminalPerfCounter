
class ServerConfiguration {
     [string]  $serverName
     [string]  $serverComment
     [array]   $PerformanceCounters

     ServerConfiguration([string]$serverName, [string]$serverComment, [array]$PerformanceCounters) {
          $this.serverName           = $serverName
          $this.serverComment        = $serverComment
          $this.PerformanceCounters  = $PerformanceCounters
     }

}