using System.Management.Automation;
using System.Collections.Generic;
using System.Threading.Tasks;
using System.Linq;
using System;
using System.Threading;

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
    public string Type { get; set; }
    public string Format { get; set; }
    public int MaxHistoryPoints { get; set; }
    public int ConversionFactor { get; set; }
    public int ConversionExponent { get; set; }
    public string Unit { get; set; }
    public Dictionary<string, object> GraphConfiguration { get; set; }

    public record DataPoint(DateTime Timestamp, double Value);
    public List<DataPoint> HistoricalData { get; set; }

    public int ExecutionDuration { get; set; }
    public Dictionary<int, string> ColorMap { get; set; }
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
        string type,
        string format,
        string unit,
        int conversionFactor,
        int conversionExponent,
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
        Type                = type;
        Format              = format;
        Unit                = unit;
        MaxHistoryPoints    = 100;
        ConversionFactor    = conversionFactor;
        ConversionExponent  = conversionExponent;
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

        // TestAvailability(); // is already checked when loading becaufe of loading countermap before
        // overrides, delete method later
        IsAvailable         = true;
        LastError           = string.Empty;
    }

    public static void GetValuesParallel(List<CounterConfiguration> instances)
    {
        var tasks = instances
            .Where(instance => instance.IsAvailable)
            .Select(instance =>
                Task.Run(() =>
                {
                        var (counterValue, duration) = instance.GetCurrentValue();
                        instance.AddDataPoint(counterValue);
                        instance.ExecutionDuration = duration ?? 0;
                })
            ).ToArray();

        Task.WaitAll(tasks);
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

    private Dictionary<int, string> SetColorMap(PSObject colorMap)
    {
        var returnObject = new Dictionary<int, string>();
        foreach (PSPropertyInfo property in colorMap.Properties)
        {
            returnObject[int.Parse(property.Name)] = property.Value.ToString()!;
        }
        return returnObject;
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

    private void TestAvailability()
    {
        try
        {
            _logger.Info(_source, $"Testing {CounterPath}");
            _ = GetCurrentValue();
            IsAvailable = true;
            LastError = string.Empty;
        }
        catch (Exception ex)
        {
            IsAvailable = false;
            LastError = ex.Message;
            _logger.Warning(_source, $"Counter '{Title}' is not available: {LastError}");
        }
    }

    public (double counterValue, int? duration) GetCurrentValue()
    {
        var scriptBlock = ScriptBlock.Create(@"
            param($CounterPath, $MaxSamples)
            $counter = Get-Counter -Counter $CounterPath -MaxSamples $MaxSamples
            $counter.CounterSamples.CookedValue
        ");

        try
        {
            var dateStart = DateTime.Now;

            using var ps = PowerShell.Create(RunspaceMode.NewRunspace);
            ps.AddCommand("Invoke-Command");

            if (IsRemote)
            {
                    foreach (var kvp in ParamRemote)
                    {
                        ps.AddParameter(kvp.Key, kvp.Value);
                    }
            }

            ps.AddParameter("ScriptBlock", scriptBlock);
            ps.AddParameter("ArgumentList", new object[] { CounterPath, 1 });

            var result = ps.Invoke();
            var dateEnd = DateTime.Now;
            var duration = (int)(dateEnd - dateStart).TotalMilliseconds;

            if (result.Count == 0) throw new Exception("No value returned from Get-Counter");

            var rawValue = Convert.ToDouble(result[0].BaseObject);
            var counterValue = Math.Round(rawValue / Math.Pow(ConversionFactor, ConversionExponent));

            return (counterValue, duration);
        }
        catch (Exception ex)
        {
            LastError = ex.Message;
            throw new Exception($"Error reading counter '{Title}': {ex.Message}", ex);
        }
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