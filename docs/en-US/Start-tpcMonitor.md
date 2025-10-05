---
external help file: psTerminalPerfCounter-help.xml
Module Name: psTerminalPerfCounter
online version:
schema: 2.0.0
---

# Start-tpcMonitor

## SYNOPSIS
Starts real-time performance counter monitoring using predefined configuration templates with language-independent counter IDs.

## SYNTAX

### SingleRemoteServer
```
Start-tpcMonitor -ConfigName <String> -ComputerName <String> [-Credential <PSCredential>]
 [-UpdateInterval <Int32>] [-MaxHistoryPoints <Int32>] [-visHTML] [-exportJson]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### ConfigName
```
Start-tpcMonitor -ConfigName <String> [-UpdateInterval <Int32>] [-MaxHistoryPoints <Int32>] [-visHTML]
 [-exportJson] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### ConfigPath
```
Start-tpcMonitor -ConfigPath <String> [-UpdateInterval <Int32>] [-MaxHistoryPoints <Int32>] [-visHTML]
 [-exportJson] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### RemoteServerConfig
```
Start-tpcMonitor -RemoteServerConfig <String> [-showConsoleTable] [-UpdateInterval <Int32>]
 [-MaxHistoryPoints <Int32>] [-visHTML] [-exportJson] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
This function launches the main monitoring interface of the psTerminalPerfCounter module.
It loads performance
counter configurations from JSON templates, validates counter availability, and starts continuous real-time
monitoring with configurable update intervals and data retention.

The function uses the module's language-independent ID system to ensure configurations work across different
system locales.
It automatically filters unavailable counters and provides detailed feedback about monitoring status.
Supports interactive monitoring with graphical displays, tables, and statistics based on configuration settings.

## EXAMPLES

### EXAMPLE 1
```
Start-tpcMonitor
```

Starts monitoring using the default CPU configuration with 1-second updates and 100 historical data points.
Graph displays 70 samples covering 70 seconds (70 samples × 1 second interval).

### EXAMPLE 2
```
Start-tpcMonitor -ConfigPath "C:\MyConfigs\tpc_CustomCPU.json"
```

Starts monitoring using a custom configuration file from an absolute path.

### EXAMPLE 3
```
Start-tpcMonitor -ConfigName "Memory" -UpdateInterval 2
```

Starts memory monitoring with 2-second update intervals using the 'tpc_Memory.json' configuration.

### EXAMPLE 4
```
Start-tpcMonitor -ConfigName "Disk" -UpdateInterval 1 -MaxHistoryPoints 200
```

Starts disk monitoring with 1-second updates and extended data retention of 200 points.

## PARAMETERS

### -ConfigName
Name of the configuration template to load (without 'tpc_' prefix and '.json' extension).
Must correspond to a JSON file in the config directory (e.g., 'CPU' loads 'tpc_CPU.json').
Default: 'CPU'
Cannot be used together with ConfigPath parameter.

```yaml
Type: String
Parameter Sets: SingleRemoteServer, ConfigName
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ConfigPath
Absolute path to a specific JSON configuration file.
The file must follow the naming convention 'tpc_*.json' and exist at the specified location.
Cannot be used together with ConfigName parameter.

```yaml
Type: String
Parameter Sets: ConfigPath
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -RemoteServerConfig
{{ Fill RemoteServerConfig Description }}

```yaml
Type: String
Parameter Sets: RemoteServerConfig
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -showConsoleTable
{{ Fill showConsoleTable Description }}

```yaml
Type: SwitchParameter
Parameter Sets: RemoteServerConfig
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -ComputerName
{{ Fill ComputerName Description }}

```yaml
Type: String
Parameter Sets: SingleRemoteServer
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Credential
{{ Fill Credential Description }}

```yaml
Type: PSCredential
Parameter Sets: SingleRemoteServer
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UpdateInterval
Interval in seconds between performance counter updates and display refreshes.
Lower values provide more responsive monitoring but increase system load.
Graph time span = Samples (from JSON config) × UpdateInterval seconds.
Default: 1 second

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 1
Accept pipeline input: False
Accept wildcard characters: False
```

### -MaxHistoryPoints
Maximum number of historical data points to retain in memory for each counter.
This is the complete historical data used for statistics and future export.
Independent of graph display width.
Time span covered by graph display = Samples × UpdateInterval seconds.
Default: 100 historical data points

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 100
Accept pipeline input: False
Accept wildcard characters: False
```

### -visHTML
{{ Fill visHTML Description }}

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -exportJson
{{ Fill exportJson Description }}

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProgressAction
{{ Fill ProgressAction Description }}

```yaml
Type: ActionPreference
Parameter Sets: (All)
Aliases: proga

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### Interactive real-time monitoring display with configurable output formats:
### - Graphical plots (line, bar, scatter based on configuration)
### - Statistical summaries (min, max, average, current values)
### - Tabular data with formatted values and units
### - Session summary upon completion
## NOTES
Main entry point for the psTerminalPerfCounter monitoring system.
Requires JSON configuration files in the module's config directory.
Press Ctrl+C to stop monitoring and display session summary.

## RELATED LINKS
