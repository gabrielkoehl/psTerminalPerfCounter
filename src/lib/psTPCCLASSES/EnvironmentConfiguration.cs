using System.Management.Automation;
using System.Collections.Generic;
using System.Threading.Tasks;
using System.Linq;
using System;

namespace psTPCCLASSES;


// Repräsentiert eine komplette Umgebung mit mehreren Servern

public class EnvironmentConfiguration
{
    private readonly PowerShellLogger _logger;
    private readonly string _source;
    public string Name { get; set; }
    public string Description { get; set; }
    public int Interval { get; set; }
    public List<ServerConfiguration> Servers { get; set; }
    public DateTime? QueryTimestamp { get; set; }
    public int QueryDuration { get; set; }

    public EnvironmentConfiguration(
        PowerShellLogger logger,
        string name,
        string description,
        int interval,
        List<ServerConfiguration> servers)
    {
        _logger           = logger;
        _source           = "EnvironmentConfiguration";
        Name              = name;
        Description       = description;
        Interval          = interval;
        Servers           = servers ?? new List<ServerConfiguration>();

        _logger.Info(_source, $"Environment '{Name}' initialized with {Servers.Count} servers");
    }

    public async Task GetAllValuesParallelAsync()
    {
        // Timestamp VOR der Abfrage setzen
        // Dieser Timestamp gilt für ALLE Server und Counter
        var startTime = DateTime.Now;
        QueryTimestamp = startTime;

        _logger.Info(_source, $"Starting parallel query for environment '{Name}' with {Servers.Count} servers");

        try
        {
            // Für jeden verfügbaren Server einen async Task erstellen
            // Jeder Server fragt intern seine Counter parallel ab
            var serverTasks = Servers
                .Where(s => s.IsAvailable)
                .Select(async server =>
                {
                    try
                    {
                        // Jeder Server fragt seine Counter parallel ab
                        await server.GetValuesParallelAsync();

                        // Server-Statistiken aktualisieren
                        server.UpdateStatistics();
                    }
                    catch (Exception ex)
                    {
                        server.LastError = ex.Message;
                        _logger.Error(_source, $"Error querying server '{server.ComputerName}': {ex.Message}");
                    }
                }).ToArray();

            // Warten bis ALLE Server fertig sind
            await Task.WhenAll(serverTasks);

            // Gesamtdauer berechnen (Ende - Start)
            var endTime = DateTime.Now;
            QueryDuration = (int)(endTime - startTime).TotalMilliseconds;

            _logger.Info(_source, $"Environment '{Name}' query completed in {QueryDuration}ms");
        }
        catch (Exception ex)
        {
            _logger.Error(_source, $"Critical error in environment '{Name}': {ex.Message}");
            throw;
        }
    }


    // Gibt Umgebungs-Statistiken zurück

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
            { "LastQueryTimestamp", QueryTimestamp?.ToString("yyyy-MM-dd HH:mm:ss.fff") ?? "Never" },
            { "LastQueryDuration", $"{QueryDuration}ms" },
            { "Interval", $"{Interval}s" }
        };
    }

}