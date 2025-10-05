---
external help file: psTerminalPerfCounter-help.xml
Module Name: psTerminalPerfCounter
online version:
schema: 2.0.0
---

# Get-tpcPerformanceCounterInfo

## SYNOPSIS
Evaluates and resolves language-independent performance counter IDs for configuration template creation.

## SYNTAX

```
Get-tpcPerformanceCounterInfo [-SearchTerm] <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
This function serves as the primary tool for evaluating correct counter IDs used in configuration templates.
It operates with a language-independent approach by using numeric IDs instead of localized counter names,
providing two evaluation methods:
- ID-based resolution: Validates and resolves composite ID format (SetID-PathID) to counter information
- Name-based discovery: Searches counter sets and paths to identify correct IDs for template configuration

The function translates between localized counter names and universal IDs, ensuring configuration templates
work across different system languages.
Results include the composite IDs needed for config templates.

## EXAMPLES

### EXAMPLE 1
```
Get-tpcPerformanceCounterInfo -SearchTerm "238-6"
```

Validates and resolves the composite ID "238-6" to verify counter availability and get localized names.

### EXAMPLE 2
```
Get-tpcPerformanceCounterInfo -SearchTerm "Processor"
```

Discovers all processor-related counters and their corresponding IDs for template configuration.

### EXAMPLE 3
```
Get-tpcPerformanceCounterInfo -SearchTerm "% Processor Time"
```

Finds the specific counter and returns its composite ID for use in configuration templates.

## PARAMETERS

### -SearchTerm
The search term for counter ID evaluation.
Can be either:
- Composite ID in format "SetID-PathID" (e.g., "238-6") for validation and resolution
- Localized counter name or path pattern for ID discovery and template preparation

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
### - ID: Composite counter ID (SetID-PathID) for use in config templates, or "N/A" if not resolvable
### - CounterSet: Localized performance counter set name
### - Path: Full localized counter path
### - SetType: SingleInstance or MultiInstance (important for template instance configuration)
### - Instances: Available counter instances for multi-instance counters
## NOTES
Primary function for config template ID creation in the psTerminalPerfCounter module.
Language-independent approach ensures templates work across different system locales.
Composite IDs returned by this function are used directly in JSON configuration files.
Requires Get-PerformanceCounterId and Get-PerformanceCounterLocalName helper functions.

## RELATED LINKS
