# Get-tpcPerformanceCounterInfo

## SYNOPSIS
Evaluates and resolves language-independent performance counter IDs for configuration template creation.

## SYNTAX

```
Get-tpcPerformanceCounterInfo [-SearchTerm] <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
This function serves as the primary tool for discovering and validating performance counter IDs used in JSON configuration files.
It operates with a language-independent approach by using numeric counter IDs instead of localized counter names,
providing two main evaluation methods:

**ID-based resolution**: Validates and resolves composite ID format (SetID-PathID) to verify counter availability and get localized information
**Name-based discovery**: Searches counter sets and paths to identify correct IDs for JSON configuration creation

The function translates between localized counter names and universal numeric IDs, ensuring JSON configuration templates
work across different system languages and locales. All results include the composite counter IDs that are required
for the counterID property in JSON configuration files.

This is the essential tool for creating new JSON configuration files, as it provides the exact counterID values,
counterSetType information, and available instances needed for proper configuration setup.

## EXAMPLES

### EXAMPLE 1
```powershell
Get-tpcPerformanceCounterInfo -SearchTerm "238-6"
```

Validates the composite counter ID "238-6" and returns detailed information including counterSetType and available instances.
This validation ensures the counter ID is correct for use in JSON configuration files.

### EXAMPLE 2
```powershell
Get-tpcPerformanceCounterInfo -SearchTerm "Processor"
```

Searches for all processor-related performance counters and returns their corresponding counter IDs.
The results show the exact counterID values needed for the JSON configuration files.

### EXAMPLE 3
```powershell
Get-tpcPerformanceCounterInfo -SearchTerm "% Processor Time"
```

Finds the specific counter and returns its composite ID (238-6), counterSetType (MultiInstance),
and available instances for creating JSON configuration entries.

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

### System.Management.Automation.PSCustomObject
Returns a formatted table with counter information required for JSON configuration creation:

**ID**: Composite counter ID (SetID-PathID) for the counterID property in JSON, or "N/A" if not resolvable

**CounterSet**: Localized performance counter set name for reference purposes

**Path**: Full localized counter path showing what the counter measures

**SetType**: SingleInstance or MultiInstance - determines the counterSetType property in JSON configuration

**Instances**: Available counter instances for MultiInstance counters - helps determine the counterInstance property value

## NOTES
Essential function for JSON configuration file creation in the psTerminalPerfCounter module.
The language-independent counter ID approach ensures JSON configurations work across different system locales.

**Workflow for JSON Configuration Creation:**
1. Use this function to discover counter IDs by searching for counter names
2. Validate counter availability and determine counterSetType
3. Identify appropriate counterInstance values for MultiInstance counters
4. Use the returned information to populate JSON configuration files

**Dependencies:** Requires Get-PerformanceCounterId and Get-PerformanceCounterLocalName helper functions.

**Schema Compliance:** All returned counter IDs follow the "SetID-PathID" format required by the JSON schema.

## RELATED LINKS
