# Start-tpcMonitor

## SYNOPSIS
Starts real-time performance counter monitoring using predefined configuration templates with language-independent counter IDs.

## SYNTAX

```
Start-tpcMonitor [[-ConfigName] <String>] [[-UpdateInterval] <Int32>] [[-MaxDataPoints] <Int32>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
This function launches the main monitoring interface of the psTerminalPerfCounter module.
It loads performance counter configurations from JSON templates, validates counter availability, and starts continuous real-time
monitoring with configurable update intervals and data retention.

The function uses the module's language-independent ID system to ensure configurations work across different
system locales. It automatically filters unavailable counters and provides detailed feedback about monitoring status.
Supports monitoring with graphical console output, tables, and statistics based on configuration settings.

## EXAMPLES

### EXAMPLE 1
```
Start-tpcMonitor
```

Starts monitoring using the default CPU configuration with 1-second updates and 100 data points.

### EXAMPLE 2
```
Start-tpcMonitor -ConfigName "Memory" -UpdateInterval 2
```

Starts memory monitoring with 2-second update intervals using the 'tpc_Memory.json' configuration.

### EXAMPLE 3
```
Start-tpcMonitor -ConfigName "Disk" -UpdateInterval 1 -MaxDataPoints 200
```

Starts disk monitoring with 1-second updates and extended data retention of 200 historical points.

## PARAMETERS

### -ConfigName
Name of the configuration template to load (without 'tpc_' prefix and '.json' extension).
Must correspond to a JSON file in the config directory (e.g., 'CPU' loads 'tpc_CPU.json').
Default: 'CPU'

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: CPU
Accept pipeline input: False
Accept wildcard characters: False
```

### -UpdateInterval
Interval in seconds between performance counter updates and display refreshes.
Lower values provide more responsive monitoring but increase system load.
Default: 1 second

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: 1
Accept pipeline input: False
Accept wildcard characters: False
```

### -MaxDataPoints
Maximum number of data points to retain in memory for each counter.
Affects currently only statistical calculations.
Higher values use more memory.
Default: 100 data points

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
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
Requires JSON configuration files in the module's config directory.
Press Ctrl+C to stop monitoring and display session summary.

## RELATED LINKS
