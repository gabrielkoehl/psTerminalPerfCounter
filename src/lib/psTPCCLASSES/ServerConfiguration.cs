using System.Collections.Generic;
using System.Linq;
using System;

namespace psTPCCLASSES;


// represents a server with all counter

public class ServerConfiguration
{
     public string ComputerName { get; set; }
     public string Comment { get; set; }
     public List<CounterConfiguration> Counters { get; set; }
     public Dictionary<string, object> Statistics { get; set; }
     public bool IsAvailable { get; set; }
     public string LastError { get; set; }
     public DateTime? LastUpdate { get; set; }

     public ServerConfiguration(
          string computerName,
          string comment,
          List<CounterConfiguration> counters)
     {
          ComputerName   = computerName;
          Comment        = comment;
          Counters       = counters ?? new List<CounterConfiguration>();
          Statistics     = new Dictionary<string, object>();
          LastError      = string.Empty;

          // Reachability is owned by Get-CounterMap (WinRM): a ServerConfiguration is only constructed
          // after the host has already answered a remote call, so by definition it is online here.
          // No separate ICMP/TCP probe - that was a redundant second source of truth.
          IsAvailable    = true;
     }

     public void UpdateStatistics()
     {
          if (Counters.Count == 0) return;

          // LINQ: Filtere nur verfügbare Counter
          // Where() = wie Where-Object in PowerShell
          var availableCounters = Counters.Where(c => c.IsAvailable).ToList();

          Statistics = new Dictionary<string, object>
          {
               { "TotalCounters", Counters.Count },
               { "AvailableCounters", availableCounters.Count },
               { "LastUpdate", LastUpdate?.ToString("HH:mm:ss") ?? "Never" }
          };
     }

}