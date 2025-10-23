---
external help file: psTerminalPerfCounter-help.xml
Module Name: psTerminalPerfCounter
online version:
schema: 2.0.0
---

# Start-tpcMonitor

## SYNOPSIS
Starts real-time performance counter monitoring for local or remote systems using predefined configuration templates with language-independent counter IDs.

## SYNTAX

### SingleRemoteServer
```
Start-tpcMonitor -ConfigName <String> -ComputerName <String> [-Credential <PSCredential>]
 [-UpdateInterval <Int32>] [-MaxHistoryPoints <Int32>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

### ConfigName
```
Start-tpcMonitor -ConfigName <String> [-UpdateInterval <Int32>] [-MaxHistoryPoints <Int32>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### ConfigPath
```
Start-tpcMonitor -ConfigPath <String> [-UpdateInterval <Int32>] [-MaxHistoryPoints <Int32>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
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

Monitoring can be performed on the local system or on remote computers by specifying ComputerName parameter.
Remote monitoring requires appropriate permissions and network connectivity to the target system.

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

### EXAMPLE 5
```
Start-tpcMonitor -ConfigName "CPU" -ComputerName "Server01"
```

Monitors CPU performance on remote server 'Server01' using current user credentials.

### EXAMPLE 6
```
Start-tpcMonitor -ConfigName "Memory" -ComputerName "SQLServer01" -Credential $cred
```

Monitors memory performance on remote server 'SQLServer01' using specified credentials.

## PARAMETERS

### -ConfigName
Name of the configuration template to load (without 'tpc_' prefix and '.json' extension).
Must correspond to a JSON file in the config directories (e.g., 'CPU' loads 'tpc_CPU.json').
Default: 'CPU'
Cannot be used together with ConfigPath parameter.
Required when using remote monitoring with ComputerName parameter.

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
Only available for local monitoring.

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

### -ComputerName
DNS name of the remote computer to monitor.
Requires ConfigName parameter to be specified.
The remote system must be reachable and allow remote performance counter access.

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
PSCredential object for authenticating to the remote computer.
If not specified, uses the current user's credentials.
Only applicable when ComputerName is specified.

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
Requires JSON configuration files in the module's config directory or custom directories.
Press Ctrl+C to stop monitoring and display session summary.

Remote monitoring requires:
- Network connectivity to target system
- Appropriate permissions for remote performance counter access
- Windows Remote Management (WinRM) enabled on target system

## RELATED LINKS
