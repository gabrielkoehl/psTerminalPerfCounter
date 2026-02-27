---
external help file: psTerminalPerfCounter-help.xml
Module Name: psTerminalPerfCounter
online version:
schema: 2.0.0
---

# Test-tpcAvailableCounterConfig

## SYNOPSIS
Validates and lists available tpc counter configurations from all registered paths.

## SYNTAX

```
Test-tpcAvailableCounterConfig [[-configFilePath] <String>] [-Raw] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
{{ Fill in the Description }}

## EXAMPLES

### EXAMPLE 1
```
Test-tpcAvailableCounterConfig
```

### EXAMPLE 2
```
Test-tpcAvailableCounterConfig -configFilePath "C:\configs\tpc_CPU.json"
```

### EXAMPLE 3
```
Test-tpcAvailableCounterConfig -Raw | Where-Object { -not $_.JsonValid }
```

## PARAMETERS

### -configFilePath
Path to a single configuration file.
If omitted, all configured paths are scanned.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Raw
Returns PSCustomObject\[\] instead of formatted console output.

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

## NOTES

## RELATED LINKS
