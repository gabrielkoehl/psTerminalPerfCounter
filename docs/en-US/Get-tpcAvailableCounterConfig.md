---
external help file: psTerminalPerfCounter-help.xml
Module Name: psTerminalPerfCounter
online version:
schema: 2.0.0
---

# Get-tpcAvailableCounterConfig

## SYNOPSIS
Retrieves, validates, and displays detailed information about available performance
counter configurations from all configured paths including JSON schema validation and optional counter availability testing.

## SYNTAX

```
Get-tpcAvailableCounterConfig [-Raw] [-TestCounters] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
This function scans all configured paths (using Get-tpcConfigPaths) for JSON files with the 'tpc_' prefix
and provides detailed information about each configuration including counter details,
validation status, and availability checks.
Results are grouped by path similar to Get-Module -ListAvailable.
Duplicate configurations across paths are marked to help identify conflicts.

## EXAMPLES

### EXAMPLE 1
```
Get-tpcAvailableCounterConfig
```

Shows formatted overview of all available configurations from all configured paths (without counter testing).

### EXAMPLE 2
```
Get-tpcAvailableCounterConfig -TestCounters
```

Shows formatted overview with counter availability testing from all configured paths.

### EXAMPLE 3
```
Get-tpcAvailableCounterConfig -Raw
```

Returns raw configuration objects for further processing from all configured paths.

## PARAMETERS

### -Raw
If specified, returns raw PSCustomObject array instead of formatted output.

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
If specified, tests each counter for availability.
This can be slow with many counters.

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

### Formatted output by default grouped by path, PSCustomObject[] when -Raw is used.
## NOTES

## RELATED LINKS
