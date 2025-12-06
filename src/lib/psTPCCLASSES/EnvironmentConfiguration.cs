using System.Management.Automation;
using System.Collections.Generic;
using System.Threading.Tasks;
using System.Linq;
using System;

namespace psTPCCLASSES;


// Repräsentiert eine komplette Umgebung mit mehreren Servern

public class EnvironmentConfiguration
{
    private static readonly PowerShellLogger _logger = PowerShellLogger.Instance;
    private readonly string _source;
    public string Name { get; set; }
    public string Description { get; set; }
    public int Interval { get; set; }
    public List<ServerConfiguration> Servers { get; set; }
    public DateTime? QueryTimestamp { get; set; }
    public int QueryDuration { get; set; }

    public EnvironmentConfiguration(
        string name,
        string description,
        int interval,
        List<ServerConfiguration> servers)
    {
        _source           = "EnvironmentConfiguration";
        Name              = name;
        Description       = description;
        Interval          = interval;
        Servers           = servers ?? new List<ServerConfiguration>();

        _logger.Info(_source, $"Environment '{Name}' initialized with {Servers.Count} servers");
    }

    public async Task GetAllValuesParallelAsync()
    {
        var startTime = DateTime.Now;
        QueryTimestamp = startTime;

        try
        {
            var serverTasks = Servers
                .Where(s => s.IsAvailable)
                .Select(async server =>
                {
                    try
                    {
                        await server.GetValuesParallelAsync();
                        server.UpdateStatistics();
                    }
                    catch (Exception ex)
                    {
                        server.LastError = ex.Message;
                        _logger.Error(_source, $"Error querying server '{server.ComputerName}': {ex.Message}");
                    }
                }).ToArray();

            await Task.WhenAll(serverTasks);

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


    public Dictionary<string, object> GetEnvironmentStatistics()
    {
        var availableServers = Servers.Where(s => s.IsAvailable).ToList();
        var totalCounters = Servers.Sum(s => s.Counters.Count);
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