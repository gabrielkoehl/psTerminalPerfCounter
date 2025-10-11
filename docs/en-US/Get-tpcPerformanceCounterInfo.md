---
external help file: psTerminalPerfCounter-help.xml
Module Name: psTerminalPerfCounter
online version:
schema: 2.0.0
---

# Get-tpcPerformanceCounterInfo

## SYNOPSIS
Evaluates and resolves language-independent performance counter IDs for creating custom configuration templates.

## SYNTAX

```
Get-tpcPerformanceCounterInfo [-SearchTerm] <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
This function serves as the primary tool for discovering and validating correct counter IDs used in JSON configuration templates.
It operates with a language-independent approach by using numeric IDs instead of localized counter names, ensuring
configurations work across different Windows language settings.

Two evaluation methods are supported:
- ID-based resolution: Validates and resolves composite ID format (SetID-PathID) to counter information
- Name-based discovery: Searches counter sets and paths to identify correct IDs for template configuration

The function translates between localized counter names and universal numeric IDs.
Results include the composite IDs
(format: "SetID-PathID") needed for the counterID field in JSON configuration files.

## EXAMPLES

### EXAMPLE 1
```
Get-tpcPerformanceCounterInfo -SearchTerm "238-6"
```

Validates and resolves the composite ID "238-6" to verify counter availability and display localized names.
Shows the counter set, path, type, and available instances.

### EXAMPLE 2
```
Get-tpcPerformanceCounterInfo -SearchTerm "Processor"
```

Discovers all processor-related counters and their corresponding composite IDs.
Use these IDs in the counterID field of JSON configuration files.

### EXAMPLE 3
```
Get-tpcPerformanceCounterInfo -SearchTerm "% Processor Time"
```

Finds the specific counter path and returns its composite ID for use in configuration templates.

### EXAMPLE 4
```
Get-tpcPerformanceCounterInfo -SearchTerm "Memory"
```

Searches for all memory-related counters across all counter sets.

## PARAMETERS

### -SearchTerm
The search term for counter ID evaluation.
Can be either:
- Composite ID in format "SetID-PathID" (e.g., "238-6") for validation and resolution
- Localized counter name or path pattern for ID discovery (supports wildcards)

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

### Formatted table displaying counter information for template configuration:
### - ID: Composite counter ID (SetID-PathID) for use in JSON config counterID field, or "N/A" if not resolvable
### - CounterSet: Localized performance counter set name
### - Path: Full localized counter path
### - SetType: SingleInstance or MultiInstance (determines counterSetType in JSON config)
### - Instances: Available counter instances for multi-instance counters (use in counterInstance field)
## NOTES
Primary function for creating custom JSON configuration templates in the psTerminalPerfCounter module.
Language-independent approach ensures templates work across different Windows system locales.
Composite IDs returned by this function are used directly in the counterID field of JSON configuration files.

Related commands:
- Get-tpcAvailableCounterConfig: View existing configurations
- Start-tpcMonitor: Start monitoring with a configuration
- Add-tpcConfigPath: Add custom configuration paths

## RELATED LINKS
