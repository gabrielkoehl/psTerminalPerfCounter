using System.Management.Automation;
using System.Collections.Generic;
using System.Threading.Tasks;
using System.Linq;
using System;
using System.Threading;
using Microsoft.PowerShell.MarkdownRender;

namespace psTPCCLASSES;

public class CounterConfiguration
{
    private static readonly PowerShellLogger _logger = PowerShellLogger.Instance;
    private readonly string _source;

    public string CounterID { get; set; }
    public string CounterSetType { get; set; }
    public string CounterInstance { get; set; }
    public string CounterPath { get; set; }
    public string Title { get; set; }
    public string Format { get; set; }
    public int MaxHistoryPoints { get; set; }
    public int ConversionFactor { get; set; }
    public int ConversionExponent { get; set; }
    public char ConversionType { get; set; }
    public int DecimalPlaces { get; set; }
    public string Unit { get; set; }

    public Dictionary<string, object> GraphConfiguration { get; set; }
    public record DataPoint(DateTime Timestamp, double Value);
    public List<DataPoint> HistoricalData { get; set; }

    public int ExecutionDuration { get; set; }
    public KeyValuePair<int, string>[] ColorMap { get; private set; }
    public Dictionary<string, object> Statistics { get; set; }
    public bool IsAvailable { get; set; }
    public bool IsRemote { get; set; }
    public string ComputerName { get; set; }
    public PSCredential? Credential { get; set; }
    public Dictionary<string, object> ParamRemote { get; set; } = new();
    public string LastError { get; set; }
    public DateTime? LastUpdate { get; set; }

    public CounterConfiguration(
        string counterID,
        string counterSetType,
        string counterInstance,
        string title,
        string format,
        string unit,
        int conversionFactor,
        int conversionExponent,
        char conversionType,
        int decimalPlaces,
        PSObject colorMap,
        PSObject graphConfiguration,
        bool isRemote,
        string computerName,
        PSCredential? credential,
        Dictionary<int, string> counterMap)
    {
        _source             = "CounterConfiguration";
        CounterID           = counterID;
        CounterSetType      = counterSetType;
        CounterInstance     = counterInstance;
        Title               = title;
        Format              = format;
        Unit                = unit;
        MaxHistoryPoints    = 100;
        ConversionFactor    = conversionFactor;
        ConversionExponent  = conversionExponent;
        ConversionType      = conversionType;
        DecimalPlaces       = decimalPlaces;
        HistoricalData      = new List<DataPoint>();
        Statistics          = new Dictionary<string, object>();
        IsAvailable         = false;
        LastError           = string.Empty;
        IsRemote            = isRemote;
        ComputerName        = computerName;
        Credential          = credential;

        SetRemoteConnectionParameter();

        CounterPath         = GetCounterPath(counterID, counterSetType, counterInstance, counterMap);

        ColorMap            = SetColorMap(colorMap);
        GraphConfiguration  = SetGraphConfig(graphConfiguration);

        IsAvailable         = true;
        LastError           = string.Empty;
    }

    public static void GetValuesBatched(List<CounterConfiguration> allCounters)
    {

        var activeCounters = allCounters.Where(c => c.IsAvailable).ToList();

        if (activeCounters.Count == 0) return;

        // Group by computerName and credentials
        var serverGroups = activeCounters.GroupBy(c => new { c.ComputerName, c.IsRemote, c.Credential });

        // parallel per server
        Parallel.ForEach(serverGroups, group =>
        {
            var serverConfig        = group.Key;
            var countersOnServer    = group.ToList();

            var pathMap = countersOnServer
                            .GroupBy(c => c.CounterPath.ToLowerInvariant())
                            .ToDictionary(g => g.Key, g => g.First());

            // All counter path in one array
            string[] pathsToQuery = countersOnServer.Select(c => c.CounterPath).ToArray();

            // Script queries all counter at once
            var scriptBlock = ScriptBlock.Create(@"
                param([string[]]$Paths)

                # ErrorAction SilentlyContinue falls ein einzelner Counter spackt

                $result = Get-Counter -Counter $Paths -MaxSamples 1 -ErrorAction SilentlyContinue

                if ($result) {
                    return $result.CounterSamples
                }
            ");

            try
            {
                var dateStart = DateTime.Now;

                // one runspace per server
                using (var ps = PowerShell.Create(RunspaceMode.NewRunspace))
                {
                    ps.AddCommand("Invoke-Command");

                    if (serverConfig.IsRemote)
                    {
                        ps.AddParameter("ComputerName", serverConfig.ComputerName);
                        if (serverConfig.Credential != null)
                        {
                            ps.AddParameter("Credential", serverConfig.Credential);
                        }
                    }

                    ps.AddParameter("ScriptBlock", scriptBlock);
                    ps.AddParameter("ArgumentList", new object[] { pathsToQuery });

                    var psResults = ps.Invoke();

                    var duration = (int)(DateTime.Now - dateStart).TotalMilliseconds;

                    foreach (PSObject sample in psResults)
                    {
                        // Pread dynamic
                        var path            = sample.Properties["Path"]?.Value?.ToString();
                        var cookedValueObj  = sample.Properties["CookedValue"]?.Value;

                        // Find counter in map

                        // Strip computer prefix: "\\SERVER\Memory\X" -> "\Memory\X"
                        var normalizedPath = path ?? "";
                        if (normalizedPath.StartsWith("\\\\", StringComparison.Ordinal))
                        {
                            var idx = normalizedPath.IndexOf('\\', 2);
                            if (idx >= 0) normalizedPath = normalizedPath.Substring(idx);
                        }

                        // O(1) lookup via pathMap
                        pathMap.TryGetValue(normalizedPath.ToLowerInvariant(), out var matchedCounter);

                        if (matchedCounter != null && cookedValueObj != null)
                        {
                            try
                            {
                                var rawValue = Convert.ToDouble(cookedValueObj);
                                double calculatedValue = 0;

                                // factorize

                                if (matchedCounter.ConversionType == 'M')
                                {
                                    calculatedValue = Math.Round(rawValue * Math.Pow(matchedCounter.ConversionFactor, matchedCounter.ConversionExponent), matchedCounter.DecimalPlaces);
                                }
                                else if (matchedCounter.ConversionType == 'D')
                                {
                                    calculatedValue = Math.Round(rawValue / Math.Pow(matchedCounter.ConversionFactor, matchedCounter.ConversionExponent), matchedCounter.DecimalPlaces);
                                } else
                                {
                                    calculatedValue = Math.Round(rawValue, matchedCounter.DecimalPlaces);
                                }



                                matchedCounter.AddDataPoint(calculatedValue);
                                matchedCounter.ExecutionDuration = duration;
                                matchedCounter.LastError = string.Empty;
                            }
                            catch
                            {
                                matchedCounter.LastError = "NaN (Conversion Error)";
                            }
                        }
                    }

                    // check for failed counter
                    foreach (var counter in countersOnServer)
                    {
                        if (counter.LastUpdate < dateStart)
                        {
                            counter.LastError = "No Data returned in Batch";
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                foreach (var counter in countersOnServer)
                {
                    counter.LastError = $"Batch Error: {ex.Message}";
                    counter.IsAvailable = false;
                }
            }
        });
    }

    private void SetRemoteConnectionParameter()
    {
        ParamRemote = new Dictionary<string, object>
        {
            { "ComputerName", ComputerName }
        };
        if (Credential is not null)
        {
            ParamRemote.Add("Credential", Credential);
        }
    }

    private KeyValuePair<int, string>[] SetColorMap(PSObject colorMap)
    {
        var map = new Dictionary<int, string>();

        foreach (PSPropertyInfo property in colorMap.Properties)
        {
            map[int.Parse(property.Name)] = property.Value.ToString()!;
        }

        return map.OrderBy(kv => kv.Key).ToArray();

    }

    private Dictionary<string, object> SetGraphConfig(PSObject graphConfiguration)
    {
        var returnObject = new Dictionary<string, object>();
        foreach (PSPropertyInfo property in graphConfiguration.Properties)
        {
            switch (property.Name)
            {
                    case "colors" when property.Value is not null:
                        var colorObject = (PSObject)property.Value;
                        var colors = new Dictionary<string, string>();
                        foreach (PSPropertyInfo colorProperty in colorObject.Properties)
                        {
                            colors[colorProperty.Name] = colorProperty.Value?.ToString() ?? string.Empty;
                        }
                        returnObject["Colors"] = colors;
                        break;

                    case "Samples" when Convert.ToInt32(property.Value!) < 70:
                        returnObject[property.Name] = 70;
                        break;

                    case "yAxisMaxRows" when Convert.ToInt32(property.Value!) < 10:
                        returnObject[property.Name] = 10;
                        break;

                    default:
                        returnObject[property.Name] = property.Value!;
                        break;
            }
        }
        return returnObject;
    }

    private string GetCounterPath(string counterID, string counterSetType, string counterInstance, Dictionary<int, string> counterMap)
    {
        if (string.IsNullOrEmpty(counterID))
        {
            throw new ArgumentException("Counter ID cannot be null or empty.");
        }

        try
        {
            // Split ID "238-6" -> 238 (Set), 6 (Path)
            var parts = counterID.Split('-');
            if (parts.Length != 2) throw new ArgumentException($"Invalid CounterID format: {counterID}");

            var setID = int.Parse(parts[0]);
            var pathID = int.Parse(parts[1]);

            string setName;
            string pathName;

            // O(1) Lookup - speed up
            if (!counterMap.TryGetValue(setID, out setName!))
            {
                throw new KeyNotFoundException($"SetID {setID} not found in provided CounterMap.");
            }

            if (!counterMap.TryGetValue(pathID, out pathName!))
            {
                throw new KeyNotFoundException($"PathID {pathID} not found in provided CounterMap.");
            }

            // String Building
            if (counterSetType == "SingleInstance")
            {
                return $"\\{setName}\\{pathName}";
            }
            else if (counterSetType == "MultiInstance")
            {
                return $"\\{setName}({counterInstance})\\{pathName}";
            }
            else
            {
                throw new ArgumentException($"Unknown counter set type: {counterSetType}");
            }
        }
        catch (Exception ex)
        {
            throw new Exception($"Error building counter path for ID '{counterID}': {ex.Message}", ex);
        }
    }

    public string GetFormattedTitle()
    {
        if (string.IsNullOrEmpty(Unit)) return Title;
        return $"{Title} ({Unit})";
    }

    public double[] GetGraphData(int sampleCount)
    {
        var dataCount = HistoricalData.Count;
        if (dataCount == 0) return [];
        var values = HistoricalData.Select(d => d.Value).ToArray();
        if (dataCount >= sampleCount)
        {
            return values.Skip(dataCount - sampleCount).ToArray();
        }
        else
        {
            var padding = new double[sampleCount - dataCount];
            return padding.Concat(values).ToArray();
        }
    }

    public override string ToString() => $"PerformanceCounter: {Title} - Available: {IsAvailable} - Data Points: {HistoricalData.Count}";

    public void AddDataPoint(double value)
    {
        var dataPoint = new DataPoint(DateTime.Now, value);
        HistoricalData.Add(dataPoint);
        LastUpdate = dataPoint.Timestamp;
        while (HistoricalData.Count > MaxHistoryPoints)
        {
            HistoricalData.RemoveAt(0);
        }
        UpdateStatistics();
    }

    public void UpdateStatistics()
    {
        if (HistoricalData.Count == 0) return;
        var values = HistoricalData.Select(d => d.Value).ToArray();
        Statistics = new Dictionary<string, object>
        {
            { "Current", values[^1] },
            { "Minimum", values.Min() },
            { "Maximum", values.Max() },
            { "Average", Math.Round(values.Average(), 1) },
            { "Count", values.Length },
            { "Last5", values.Length >= 5 ? values[^5..] : values }
        };
    }

    public DataPoint[] GetHistoricalDataWithTimestamps()
    {
        return HistoricalData.ToArray();
    }
}