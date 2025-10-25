using System.Management.Automation;
using System.Collections.Generic;
using System.Threading.Tasks;
using System.Linq;
using System;

namespace psTPCCLASSES;


// represents a server with all counter

public class ServerConfiguration
{
     private readonly PowerShellLogger _logger;
     private readonly string _source;
     public string ComputerName { get; set; }
     public string Comment { get; set; }
     public List<CounterConfiguration> Counters { get; set; }
     public Dictionary<string, object> Statistics { get; set; }
     public bool IsAvailable { get; set; }
     public string LastError { get; set; }
     public DateTime? LastUpdate { get; set; }

     public ServerConfiguration(
          PowerShellLogger logger,
          string computerName,
          string comment,
          List<CounterConfiguration> counters)
     {
          _logger        = logger;
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
               using var ps = PowerShell.Create();

               ps.AddCommand("Test-Connection")
               .AddParameter("ComputerName", ComputerName)
               .AddParameter("Count", 1)
               .AddParameter("Quiet");

               var result = ps.Invoke();

               IsAvailable = result.Count > 0 && (bool)result[0].BaseObject;

               if (!IsAvailable)
               {
                    LastError = "Server not reachable";
                    _logger.warning(_source, $"Warning: Server '{ComputerName}' is not reachable");
               }
          }
          catch (Exception ex)
          {
               IsAvailable    = false;
               LastError      = ex.Message;
               _logger.error(_source, $"Warning: Cannot reach server '{ComputerName}': {ex.Message}");
          }
     }

     // Fragt alle Counter dieses Servers PARALLEL ab
     // Public Methode - kann von außen aufgerufen werden
     // Beispiel: myServer.GetValuesParallel()

     public void GetValuesParallel()
     {
          if (!IsAvailable)
          {
               _logger.warning(_source, $"Skipping server '{ComputerName}': {LastError}");
               return;
          }

          // LINQ: Für jeden Counter einen Task erstellen
          // Select() = wie ForEach-Object in PowerShell
          // Task.Run(() => {...}) = Führe Code in separatem Thread aus
          var tasks = Counters.Select(counter =>
               Task.Run(() =>      // Lambda-Ausdruck: () => {} ist wie { param() ... } in PS
               {
                    try
                    {
                    var (counterValue, duration) = counter.GetCurrentValue(); // Tuple counterValue und duration

                    // Datenpunkt zur Historie hinzufügen
                    counter.AddDataPoint(counterValue, maxHistoryPoints);

                    // Ausführungszeit speichern (falls null, dann 0)
                    counter.ExecutionDuration = duration ?? 0;
                    }
                    catch (Exception ex)
                    {
                    // Fehler für diesen Counter speichern, aber andere Counter weiterlaufen lassen
                    counter.LastError = ex.Message;
                    Console.WriteLine($"Error reading {counter.Title} on {ComputerName}: {ex.Message}");
                    }
               })
          ).ToArray();    // LINQ-Query in Array konvertieren

          // Warten bis ALLE Tasks fertig sind
          // Erst wenn alle Counter abgefragt wurden, geht es weiter
          Task.WaitAll(tasks);

          // Timestamp setzen für letztes erfolgreiches Update
          LastUpdate = DateTime.Now;
     }

     /// <summary>
     /// Aktualisiert Server-Level Statistiken
     /// Zeigt wie viele Counter verfügbar sind, wann letztes Update war etc.
     /// </summary>
     public void UpdateStatistics()
     {
          if (Counters.Count == 0) return;        // Keine Counter = nichts zu tun

          // LINQ: Filtere nur verfügbare Counter
          // Where() = wie Where-Object in PowerShell
          var availableCounters = Counters.Where(c => c.IsAvailable).ToList();

          // Dictionary befüllen (Key-Value Paare wie Hashtable in PowerShell)
          Statistics = new Dictionary<string, object>
          {
               { "TotalCounters", Counters.Count },
               { "AvailableCounters", availableCounters.Count },
               { "LastUpdate", LastUpdate?.ToString("HH:mm:ss") ?? "Never" }      // ? = falls null, dann "Never"
          };
     }

     /// <summary>
     /// ToString Override für schönere Ausgabe beim Debuggen
     /// Wird automatisch aufgerufen bei Console.WriteLine(serverObject)
     /// </summary>
     public override string ToString()
     {
          return $"Server: {ComputerName} - Available: {IsAvailable} - Counters: {Counters.Count}";
     }
}