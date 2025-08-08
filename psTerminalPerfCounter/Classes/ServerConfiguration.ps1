
class ServerConfiguration {
     [string]            $serverName
     [string]            $serverComment
     [pscredential]      $serverCredential
     [array]             $PerformanceCounters

     ServerConfiguration([string]$serverName, [string]$serverComment, [pscredential]$serverCredential, [array]$PerformanceCounters) {
          $this.serverName           = $serverName
          $this.serverComment        = $serverComment
          $this.serverCredential     = $serverCredential
          $this.PerformanceCounters  = $PerformanceCounters
     }



}