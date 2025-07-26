# Get-tpcAvailableCounterConfig

## SYNOPSIS
Retrieves, validates, and displays detailed information about available performance
counter configurations including JSON schema validation and optional counter availability testing.

## SYNTAX

```
Get-tpcAvailableCounterConfig [[-ConfigPath] <String>] [[-SchemaPath] <String>] [-Raw] [-TestCounters]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
This function scans the config directory for all JSON files with the 'tpc_' prefix
and provides detailed information about each configuration including counter details,
validation status, and availability checks.

## EXAMPLES

### EXAMPLE 1
```
Get-tpcAvailableCounterConfig
```

Shows formatted overview of all available configurations (without counter testing).

### EXAMPLE 2
```
Get-tpcAvailableCounterConfig -TestCounters
```

Shows formatted overview with counter availability testing.

### EXAMPLE 3
```
Get-tpcAvailableCounterConfig -ConfigPath "C:\MyConfigs" -TestCounters
```

Shows formatted overview of configurations from a custom directory with counter testing.

### EXAMPLE 4
```
Get-tpcAvailableCounterConfig -Raw
```

Returns raw configuration objects for further processing.

## PARAMETERS

### -ConfigPath
Optional custom path to configuration files.
If not specified, uses the module's
config directory.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: $(Join-Path $PSScriptRoot "..\Config")
Accept pipeline input: False
Accept wildcard characters: False
```

### -SchemaPath
Path to Json Schema file

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: $(Join-Path $ConfigPath "schema.json")
Accept pipeline input: False
Accept wildcard characters: False
```

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

### Formatted output by default, PSCustomObject[] when -Raw is used.
## NOTES

## RELATED LINKS
