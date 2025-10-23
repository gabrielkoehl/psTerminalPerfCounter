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
          PSObject colorMap,
          PSObject graphConfiguration,
          bool isRemote,
          string computerName,
          PSCredential? credential)
     {
          CounterID           = counterID;
          CounterSetType      = counterSetType;
          CounterInstance     = counterInstance;
          Title               = title;
          Type                = type;
          Format              = format;
          Unit                = unit;
          ConversionFactor    = conversionFactor;
          ConversionExponent  = conversionExponent;
          HistoricalData      = new List<DataPoint>();
          Statistics          = new Dictionary<string, object>();
          IsAvailable         = false;
          LastError           = "";
          IsRemote            = isRemote;
          ComputerName        = computerName;
          Credential          = credential;

          SetRemoteConnectionParameter();

          CounterPath         = GetCounterPath(counterID, counterSetType, counterInstance);
          ColorMap            = SetColorMap(colorMap);
          GraphConfiguration  = SetGraphConfig(graphConfiguration);

          TestAvailability();
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

     private Dictionary<int, string> SetColorMap(PSObject  colorMap)
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

                    case "Samples" when (int)property.Value! < 70:
                         returnObject[property.Name] = 70;
                         break;

                    case "yAxisMaxRows" when (int)property.Value! < 10:
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

     }

     private string GetCounterPath(string counterID, string counterSetType, string counterInstance)
     {

          return "";
     }

}