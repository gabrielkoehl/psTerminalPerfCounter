---
external help file: psTerminalPerfCounter-help.xml
Module Name: psTerminalPerfCounter
online version:
schema: 2.0.0
---

# Remove-tpcConfigPath

## SYNOPSIS

## SYNTAX

```
Remove-tpcConfigPath [-All] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Removes custom configuration paths from the TPC_CONFIGPATH user environment variable.

## EXAMPLES

### EXAMPLE 1
```
Remove-tpcConfigPath
```

Interactively select and remove individual configuration paths.

### EXAMPLE 2
```
Remove-tpcConfigPath -All
```

Removes all custom configuration paths without prompting.

## PARAMETERS

### -All
Removes all custom paths without prompting.
Module default is not affected.

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
