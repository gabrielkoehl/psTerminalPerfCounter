---
external help file: psTerminalPerfCounter-help.xml
Module Name: psTerminalPerfCounter
online version:
schema: 2.0.0
---

# Start-tpcEnvironmentMonitor

## SYNOPSIS
Starts real-time performance counter monitoring for multiple remote servers in parallel

## SYNTAX

```
Start-tpcEnvironmentMonitor [-ConfigPath] <String> [[-UpdateInterval] <Int32>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
This function launches environment-level monitoring across multiple servers.
It loads an environment configuration from JSON (containing multiple servers),
queries all servers and their counters IN PARALLEL, and displays results in a table format.

Key features:
- Parallel querying: All servers are queried simultaneously
- Within each server: All counters are queried in parallel
- Common timestamp: All data points share the same timestamp
- Performance tracking: Total query duration is measured

The function uses async/await pattern internally for maximum performance.

## EXAMPLES

### EXAMPLE 1
```
Start-tpcEnvironmentMonitor -ConfigPath "_remoteconfigs\AD_SERVER_001.json"
```

Starts monitoring using the default interval from JSON configuration.
Queries all servers in parallel every 2 seconds (or as configured).

### EXAMPLE 2
```
Start-tpcEnvironmentMonitor -ConfigPath "C:\Configs\SQL_PROD.json" -UpdateInterval 5
```

Starts monitoring with 5-second update intervals (overrides JSON interval).

## PARAMETERS

### -ConfigPath
Absolute path to the environment JSON configuration file.
Example: "_remoteconfigs\AD_SERVER_001.json"

JSON structure:
{
    "name": "SQL_ENVIRONMENT_001",
    "description": "SQL Server Production Environment",
    "interval": 2,
    "servers": \[
        {
            "computername": "DEV-DC",
            "comment": "Domain Controller",
            "counterConfig": \["CPU"\]
        }
    \]
}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UpdateInterval
Interval in seconds between performance counter updates and display refreshes.
Lower values provide more responsive monitoring but increase system load.
Default: Uses interval from JSON configuration (or 2 seconds if not specified)

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: 0
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

### Interactive real-time monitoring display with:
### - Tabular data showing all servers and their counters
### - Common timestamp for all measurements
### - Query duration in milliseconds
### - Statistical summaries (min, max, average, current values)
## NOTES
Environment monitoring entry point for multi-server scenarios.

Requirements:
- JSON configuration file with server definitions
- Network connectivity to all target systems
- Appropriate permissions for remote performance counter access
- Windows Remote Management (WinRM) enabled on target systems

Performance characteristics:
- 3 servers with 2 counters each (6 total) queries in ~1-2 seconds
- All servers and counters run in parallel (not sequentially)

Press Ctrl+C to stop monitoring and display session summary.

## RELATED LINKS
