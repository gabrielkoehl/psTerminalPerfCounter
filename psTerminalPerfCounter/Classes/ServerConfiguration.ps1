
class ServerConfiguration {
     [string]  $serverName
     [string]  $serverComment
     [array]   $PerformanceCounters

     ServerConfiguration([string]$serverName, [string]$serverComment, [array]$PerformanceCounters) {
          $this.serverName           = $serverName
          $this.serverComment        = $serverComment
          $this.PerformanceCounters  = $PerformanceCounters
     }

     [void] SetCounterRemoteProperties([string]$ComputerName, [pscredential]$credential) {
          foreach ( $config in $this.PerformanceCounters ) {

               foreach ( $counter in $config.counters ) {
                   $counter.isRemote        = $true
                   $counter.computername    = $ComputerName
                   $counter.Credential      = $credential

                   $counter.SetRemoteConnectionParameter()
               }

          }
     }

}