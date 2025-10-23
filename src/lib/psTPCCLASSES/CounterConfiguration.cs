using System.Management.Automation;
using System.Collections.Generic;
using System.Threading.Tasks;
using System.Linq;
using System;


namespace psTPCCLASSES;

public class CounterConfiguration
{
    public string CounterID { get; set; }
    public string CounterSetType { get; set; }
    public string CounterInstance { get; set; }
    public string CounterPath { get; set; }
    public string Title { get; set; }
    public string Type { get; set; }
    public string Format { get; set; }
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
    public Dictionary<string, object> ParamRemote { get; set; }
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
        object colorMap,
        object graphConfiguration,
        bool isRemote,
        string computerName,
        PSCredential? credential)
    {
        CounterID             = counterID;
        CounterSetType        = counterSetType;
        CounterInstance       = counterInstance;
        Title                 = title;
        Type                  = type;
        Format                = format;
        Unit                  = unit;
        ConversionFactor      = conversionFactor;
        ConversionExponent    = conversionExponent;
        HistoricalData        = new List<DataPoint>();
        Statistics            = new Dictionary<string, object>();
        IsAvailable           = false;
        LastError             = "";
        IsRemote              = isRemote;
        ComputerName          = computerName;
        Credential            = credential;

        SetRemoteConnectionParameter();

        CounterPath           = GetCounterPath(counterID, counterSetType, counterInstance);
        ColorMap              = SetColorMap(colorMap);
        GraphConfiguration    = SetGraphConfig(graphConfiguration);

        TestAvailability();
    }

    private void SetRemoteConnectionParameter()
    {

    }

    private string GetCounterPath(string counterID, string counterSetType, string counterInstance)
    {

        return "";
    }

    private Dictionary<int, string> SetColorMap(object colorMap)
    {

        return new Dictionary<int, string>();
    }

    private Dictionary<string, object> SetGraphConfig(object graphConfiguration)
    {

        return new Dictionary<string, object>();
    }

    private void TestAvailability()
    {

    }
}