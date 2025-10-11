---
external help file: psTerminalPerfCounter-help.xml
Module Name: psTerminalPerfCounter
online version:
schema: 2.0.0
---

# Get-tpcAvailableCounterConfig

## SYNOPSIS
Retrieves, validates, and displays detailed information about available performance counter configurations from all configured paths.

## SYNTAX

```
Get-tpcAvailableCounterConfig [-Raw] [-TestCounters] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
This function scans all configured paths (using Get-tpcConfigPaths) for JSON configuration files with the 'tpc_' prefix
and provides comprehensive information about each configuration including counter details, JSON schema validation status,
and optional counter availability testing.

Results are grouped by path similar to Get-Module -ListAvailable.
Duplicate configurations across paths are automatically
detected and marked to help identify potential conflicts.
The function validates each configuration against the module's
JSON schema and optionally tests counter availability on the system.

Template files (containing 'template' in the basename) are automatically excluded from the results.

## EXAMPLES

### EXAMPLE 1
```
Get-tpcAvailableCounterConfig
```

Shows formatted overview of all available configurations from all configured paths.
Displays configuration names, descriptions, counter counts, and validation status.

### EXAMPLE 2
```
Get-tpcAvailableCounterConfig -TestCounters
```

Shows formatted overview with counter availability testing from all configured paths.
Validates each counter to ensure it's available on the current system.

### EXAMPLE 3
```
Get-tpcAvailableCounterConfig -Raw
```

Returns raw configuration objects for further processing or custom filtering.

### EXAMPLE 4
```
Get-tpcAvailableCounterConfig | Where-Object { $_.JsonValid -eq $false }
```

Lists only configurations with JSON validation errors (when used with -Raw).

## PARAMETERS

### -Raw
If specified, returns raw PSCustomObject array instead of formatted console output.
Useful for further processing or filtering of configuration data.

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

### -TestCounters
If specified, tests each counter for availability on the current system.
This validates that counters can actually be queried but may be slow with many counters.

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

### Formatted console output by default (grouped by path), PSCustomObject[] when -Raw is used.
## NOTES
This function requires the GripDevJsonSchemaValidator module for JSON schema validation.
If not installed, validation will be skipped with a warning.

Related commands:
- Get-tpcConfigPaths: List all configured configuration paths
- Start-tpcMonitor: Start monitoring with a specific configuration
- Get-tpcPerformanceCounterInfo: Get counter IDs for creating custom configurations

## RELATED LINKS
