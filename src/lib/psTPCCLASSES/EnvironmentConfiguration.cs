using System.Management.Automation;
using System.Collections.Generic;
using System.Threading.Tasks;
using System.Linq;
using System;

namespace psTPCCLASSES;

/// <summary>
/// Repräsentiert eine komplette Umgebung mit mehreren Servern
/// Beispiel: "SQL_ENVIRONMENT_001" mit 3 SQL Servern + 1 Domain Controller
/// Hauptaufgabe: Koordiniert die parallele Abfrage über ALLE Server hinweg
/// </summary>
public class EnvironmentConfiguration
{
    private readonly PowerShellLogger _logger;
    private readonly string _source;
    public string Name { get; set; }                                // Name z.B. "SQL_ENVIRONMENT_001"
    public string Description { get; set; }                         // Beschreibung z.B. "SQL Production Environment"
    public int Interval { get; set; }                               // Update-Intervall in Sekunden
    public List<ServerConfiguration> Servers { get; set; }          // Liste aller Server in dieser Umgebung

    /// <summary>
    /// Constructor - erstellt neue Umgebungskonfiguration
    /// </summary>
    public EnvironmentConfiguration(
        PowerShellLogger logger,
        string name,
        string description,
        int interval,
        List<ServerConfiguration> servers)
    {
        _logger     = logger;
        _source     = "EnvironmentConfiguration";
        Name        = name;
        Description = description;
        Interval    = interval;
        Servers     = servers ?? new List<ServerConfiguration>();   // Falls null, leere Liste
    }

    /// <summary>
    /// STATIC Methode = gehört zur Klasse, nicht zur Instanz
    /// Kann aufgerufen werden ohne Objekt: EnvironmentConfiguration.GetAllValuesParallel(...)
    ///
    /// MAXIMALE PARALLELITÄT:
    /// Fragt ALLE Counter von ALLEN Servern GLEICHZEITIG ab
    ///
    /// Beispiel mit 3 Servern:
    /// Server 1: CPU + Memory Counter    (2 Counter)
    /// Server 2: CPU + Memory Counter    (2 Counter)
    /// Server 3: CPU + Memory Counter    (2 Counter)
    /// = 6 parallele Tasks laufen GLEICHZEITIG
    ///
    /// Vorher (seriell): Server1.Counter1 → Server1.Counter2 → Server2.Counter1 → ...
    /// Jetzt (parallel): Alle 6 Counter starten gleichzeitig und laufen parallel
    ///
    /// Wichtig: Network I/O bound (nicht CPU bound)
    /// Tasks warten auf Netzwerk-Antwort, blockieren aber keine CPU-Threads
    /// → Kann 100+ parallel Requests handeln ohne Performance-Probleme
    /// </summary>
    /// <param name="servers">Liste aller Server die abgefragt werden sollen</param>
    /// <param name="maxHistoryPoints">Max. historische Datenpunkte pro Counter</param>
    public static void GetAllValuesParallel(
        List<ServerConfiguration> servers,
        int maxHistoryPoints)
    {
        // LINQ Query Aufbau (wird erst bei ToList() ausgeführt):
        // 1. Where(s => s.IsAvailable)              = Nur erreichbare Server
        // 2. SelectMany(server => server.Counters)  = Flatten: Alle Counter von allen Servern in eine Liste
        // 3. Where(c => c.IsAvailable)              = Nur verfügbare Counter

        var allCounters = servers
            .Where(s => s.IsAvailable)                              // Filtere nur erreichbare Server
            .SelectMany(server => server.Counters                   // SelectMany = Flatten, wie ForEach dann +
                .Where(c => c.IsAvailable))                         // Nur verfügbare Counter pro Server
            .ToList();                                              // Query ausführen und zu List konvertieren

        // Wenn keine Counter verfügbar, abbrechen
        if (allCounters.Count == 0)
        {
            Console.WriteLine("Warning: No available counters to query");
            return;
        }

        // Debug-Info: Zeige wie viele Counter parallel abgefragt werden
        Console.WriteLine($"Querying {allCounters.Count} counters in parallel across {servers.Count(s => s.IsAvailable)} servers...");

        // Für JEDEN Counter einen separaten Task erstellen
        // Select() = Transformation (wie ForEach-Object in PowerShell)
        // Task.Run(() => {...}) = Starte asynchrone Ausführung in eigenem Thread
        var tasks = allCounters.Select(counter =>
            Task.Run(() =>          // Lambda: () => {} ist anonyme Funktion
            {
                try
                {
                    // Tuple Deconstruction: Methode gibt (value, duration) zurück
                    // var (x, y) = ... weist beide Werte direkt zu
                    var (counterValue, duration) = counter.GetCurrentValue();

                    // Datenpunkt hinzufügen und älteste Punkte ggf. löschen
                    counter.AddDataPoint(counterValue, maxHistoryPoints);

                    // Ausführungszeit speichern (Coalescing: ?? gibt 0 zurück falls duration null ist)
                    counter.ExecutionDuration = duration ?? 0;
                }
                catch (Exception ex)
                {
                    // Fehler abfangen aber andere Counter weiterlaufen lassen
                    // Wichtig: Nicht die ganze Abfrage abbrechen bei einzelnem Fehler
                    counter.LastError = ex.Message;
                    Console.WriteLine($"Error: {counter.Title} on {counter.ComputerName}: {ex.Message}");
                }
            })
        ).ToArray();        // Query ausführen und zu Array konvertieren

        // KRITISCHER PUNKT:
        // Task.WaitAll() blockiert den aktuellen Thread bis ALLE Tasks fertig sind
        // Erst wenn alle 6 (oder 100) Counter abgefragt wurden, geht es weiter
        // = Synchroner Snapshot über alle Server hinweg
        Task.WaitAll(tasks);

        // Nach erfolgreicher Abfrage: Zeitstempel für alle Server aktualisieren
        // Und Server-Statistiken neu berechnen
        foreach (var server in servers.Where(s => s.IsAvailable))
        {
            server.LastUpdate = DateTime.Now;           // Gleicher Timestamp für alle Server
            server.UpdateStatistics();                  // Counter-Statistiken pro Server aktualisieren
        }
    }

    /// <summary>
    /// ALTERNATIVE Methode mit anderer Gruppierung (gleiche Parallelität):
    ///
    /// Statt: Alle Counter flach in einer Liste
    /// Jetzt: Pro Server ein Task, der seine Counter parallel abfragt
    ///
    /// Beispiel:
    /// Task 1: Server1 fragt seine Counter parallel ab
    /// Task 2: Server2 fragt seine Counter parallel ab
    /// Task 3: Server3 fragt seine Counter parallel ab
    /// Alle 3 Tasks laufen parallel
    ///
    /// Ergebnis ist identisch zu GetAllValuesParallel(), nur andere Code-Struktur
    /// Nützlich wenn man pro Server zusätzliche Logik braucht
    /// </summary>
    public void GetValuesByServerParallel(int maxHistoryPoints)
    {
        // Erstelle für jeden verfügbaren Server einen Task
        // Jeder Task ruft die GetValuesParallel() Methode des Servers auf
        var tasks = Servers
            .Where(s => s.IsAvailable)                                          // Nur erreichbare Server
            .Select(server =>
                Task.Run(() => server.GetValuesParallel(maxHistoryPoints))      // Server-Methode in eigenem Task
            )
            .ToArray();

        // Warte bis alle Server fertig sind
        Task.WaitAll(tasks);
    }

    /// <summary>
    /// Gibt Umgebungs-Statistiken zurück
    /// Beispiel: Wieviele Server online, wieviele Counter insgesamt etc.
    /// </summary>
    public Dictionary<string, object> GetEnvironmentStatistics()
    {
        var availableServers = Servers.Where(s => s.IsAvailable).ToList();
        var totalCounters = Servers.Sum(s => s.Counters.Count);                // Sum() = Measure-Object -Sum
        var availableCounters = availableServers.Sum(s => s.Counters.Count(c => c.IsAvailable));

        return new Dictionary<string, object>
        {
            { "TotalServers", Servers.Count },
            { "AvailableServers", availableServers.Count },
            { "TotalCounters", totalCounters },
            { "AvailableCounters", availableCounters },
            { "Interval", Interval }
        };
    }

}