using System.Management.Automation;
using System.Collections.Generic;
using System.Threading.Tasks;
using System.Linq;
using System;

namespace psTPCCLASSES;


// represents a server with all counter

public class ServerConfiguration
{
     private static readonly PowerShellLogger _logger = PowerShellLogger.Instance;
     private readonly string _source;
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
          _source        = "ServerConfiguration";
          ComputerName   = computerName;
          Comment        = comment;
          Counters       = counters ?? new List<CounterConfiguration>();
          Statistics     = new Dictionary<string, object>();
          IsAvailable    = false;
          LastError      = string.Empty;

          TestServerAvailability();
     }

     private void TestServerAvailability()
     {
          try
          {
               using var ps = PowerShell.Create(RunspaceMode.NewRunspace);

               ps.AddCommand("Test-Connection")
               .AddParameter("ComputerName", ComputerName)
               .AddParameter("Count", 1)
               .AddParameter("Quiet");

               var result = ps.Invoke();

               IsAvailable = result.Count > 0 && (bool)result[0].BaseObject;

               if (!IsAvailable)
               {
                    LastError = "Server not reachable";
                    _logger.Warning(_source, $"Server '{ComputerName}' is not reachable");
               }
          }
          catch (Exception ex)
          {
               IsAvailable    = false;
               LastError      = ex.Message;
               _logger.Error(_source, $"Cannot reach server '{ComputerName}': {ex.Message}");
          }
     }

     public async Task GetValuesParallelAsync()
     {
          if (!IsAvailable)
          {
               _logger.Warning(_source, $"Skipping server '{ComputerName}': {LastError}");
               return;
          }

          var tasks = Counters
               .Where(counter => counter.IsAvailable)
               .Select(counter =>
                    Task.Run(() =>
                    {
                         try
                         {
                              var (counterValue, duration) = counter.GetCurrentValue();

                              // Datenpunkt zur Historie hinzufügen
                              counter.AddDataPoint(counterValue);

                              // Ausführungszeit speichern (falls null, dann 0)
                              counter.ExecutionDuration = duration ?? 0;
                         }
                         catch (Exception ex)
                         {
                              // Fehler für diesen Counter speichern, aber andere Counter weiterlaufen lassen
                              counter.LastError = ex.Message;
                              _logger.Error(_source, $"Error reading {counter.Title} on {ComputerName}: {ex.Message}");
                         }
                    })
               ).ToArray();

          await Task.WhenAll(tasks);

          LastUpdate = DateTime.Now;
     }

     public void UpdateStatistics()
     {
          if (Counters.Count == 0) return;        // Keine Counter = nichts zu tun

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