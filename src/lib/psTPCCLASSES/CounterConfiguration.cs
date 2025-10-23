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
          CounterID = counterID;
          CounterSetType = counterSetType;
          CounterInstance = counterInstance;
          Title = title;
          Type = type;
          Format = format;
          Unit = unit;
          ConversionFactor = conversionFactor;
          ConversionExponent = conversionExponent;
          HistoricalData = new List<DataPoint>();
          Statistics = new Dictionary<string, object>();
          IsAvailable = false;
          LastError = "";
          IsRemote = isRemote;
          ComputerName = computerName;
          Credential = credential;

          SetRemoteConnectionParameter();

          CounterPath = GetCounterPath(counterID, counterSetType, counterInstance);
          ColorMap = SetColorMap(colorMap);
          GraphConfiguration = SetGraphConfig(graphConfiguration);

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
          try
          {
               if (IsRemote)
               {
                    GetRemoteValue(1);
               }
               else
               {
                    // Get-Counter equivalent - PowerShell command ausführen
                    using var ps = PowerShell.Create();
                    ps.AddCommand("Get-Counter")
                    .AddParameter("Counter", CounterPath)
                    .AddParameter("MaxSamples", 1);
                    ps.Invoke();
               }

               IsAvailable = true;
               LastError = string.Empty;
          }
          catch (Exception ex)
          {
               IsAvailable = false;
               LastError = ex.Message;

               Console.WriteLine($"Warning: Counter '{Title}' is not available: {LastError}");
               Thread.Sleep(500);
          }
     }

     public (double counterValue, int? duration) GetCurrentValue()
     {
          if (!IsAvailable)
          {
               throw new InvalidOperationException($"Counter '{Title}' is not available: {LastError}");
          }

          try
          {
               double counterValue;
               int?   duration = null;

               if (IsRemote)
               {
                    var result     = GetRemoteValue(1);
                    counterValue   = result.counterValue;
                    duration       = result.duration;
               }
               else
               {
                    using var ps = PowerShell.Create();
                    ps.AddCommand("Get-Counter")
                    .AddParameter("Counter", CounterPath)
                    .AddParameter("MaxSamples", 1);

                    var result     = ps.Invoke();
                    counterValue   = Convert.ToDouble(result[0].BaseObject);
               }

               // Convert Units
               counterValue = Math.Round(counterValue / Math.Pow(ConversionFactor, ConversionExponent));

               return (counterValue, duration);
          }
          catch (Exception ex)
          {
               LastError = ex.Message;
               throw new Exception($"Error reading counter '{Title}': {ex.Message}", ex);
          }
     }

     private (double counterValue, int duration) GetRemoteValue(int maxSamples)
     {
          var scriptBlock = ScriptBlock.Create(@"
               param($CounterPath, $MaxSamples)
               $counter = Get-Counter -Counter $CounterPath -MaxSamples $MaxSamples
               $counter.CounterSamples.CookedValue
          ");

          try
          {
               var dateStart = DateTime.Now;

               using var ps = PowerShell.Create();
               ps.AddCommand("Invoke-Command");

               foreach (var kvp in ParamRemote)
               {
                    ps.AddParameter(kvp.Key, kvp.Value);
               }

               ps.AddParameter("ScriptBlock", scriptBlock);
               ps.AddParameter("ArgumentList", new object[] { CounterPath, maxSamples });

               var result = ps.Invoke();
               var dateEnd = DateTime.Now;
               var duration = (dateEnd - dateStart).Milliseconds;
               var counterValue = Convert.ToDouble(result[0].BaseObject);

               return (counterValue, duration);
          }
          catch (Exception ex)
          {
               throw new Exception($"Error getting remote value for '{Title}': {ex.Message}", ex);
          }
     }

     private string GetCounterPath(string counterID, string counterSetType, string counterInstance)
     {
          if (string.IsNullOrEmpty(counterID))
          {
               throw new ArgumentException("Counter ID cannot be null or empty.");
          }

          try
          {
               var parts      = counterID.Split('-');
               var setID      = parts[0];
               var pathID     = parts[1];

               // https://powershell.one/tricks/performance/performance-counters
               // Licensed under the CC BY 4.0 ( https://creativecommons.org/licenses/by/4.0/ )
               var scriptBlock = ScriptBlock.Create(@"
                    param([UInt32]$Id)
                    $code     = '[DllImport(""pdh.dll"", SetLastError=true, CharSet=CharSet.Unicode)] public static extern UInt32 PdhLookupPerfNameByIndex(string szMachineName, uint dwNameIndex, System.Text.StringBuilder szNameBuffer, ref uint pcchNameBufferSize);'
                    $type     = Add-Type -MemberDefinition $code -PassThru -Name PerfCounter1 -Namespace Utility -ErrorAction SilentlyContinue
                    $Buffer   = [System.Text.StringBuilder]::new(1024)
                    [UInt32]$BufferSize = $Buffer.Capacity
                    $rv       = $type::PdhLookupPerfNameByIndex($env:COMPUTERNAME, $Id, $Buffer, [Ref]$BufferSize)

                    if ($rv -eq 0) {
                         $Buffer.ToString().Substring(0, $BufferSize-1)
                    } else {
                         throw 'Unable to retrieve localized name.'
                    }
               ");
               // ------------------------------------------------------------------------------

               string setName;
               string pathName;

               using var ps = PowerShell.Create();

               if (IsRemote)
               {

                    // SetName
                    ps.AddCommand("Invoke-Command");
                    foreach (var kvp in ParamRemote)
                    {
                         ps.AddParameter(kvp.Key, kvp.Value);
                    }
                    ps.AddParameter("ScriptBlock", scriptBlock);
                    ps.AddParameter("ArgumentList", new object[] { setID });

                    var resultSet = ps.Invoke();
                    setName = resultSet[0].BaseObject.ToString()!;  // <- FIX

                    // -------
                         ps.Commands.Clear();
                    // -------

                    // PathName
                    ps.AddCommand("Invoke-Command");
                    foreach (var kvp in ParamRemote)
                    {
                         ps.AddParameter(kvp.Key, kvp.Value);
                    }
                    ps.AddParameter("ScriptBlock", scriptBlock);
                    ps.AddParameter("ArgumentList", new object[] { pathID });

                    var resultPath = ps.Invoke();
                    pathName = resultPath[0].BaseObject.ToString()!;
               }
               else
               {
                    // SetName
                    ps.AddCommand("Invoke-Command")
                    .AddParameter("ScriptBlock", scriptBlock)
                    .AddParameter("ArgumentList", new object[] { setID });

                    var resultSet = ps.Invoke();
                    setName = resultSet[0].BaseObject.ToString()!;

                    // -------
                         ps.Commands.Clear();
                    // -------

                    // PathName
                    ps.AddCommand("Invoke-Command")
                    .AddParameter("ScriptBlock", scriptBlock)
                    .AddParameter("ArgumentList", new object[] { pathID });

                    var resultPath = ps.Invoke();
                    pathName = resultPath[0].BaseObject.ToString()!;
               }

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
               throw new Exception($"Error getting counter path for ID '{counterID}': {ex.Message}", ex);
          }
     }

}