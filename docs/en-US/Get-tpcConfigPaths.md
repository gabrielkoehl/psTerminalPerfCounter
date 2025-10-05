---
external help file: psTerminalPerfCounter-help.xml
Module Name: psTerminalPerfCounter
online version:
schema: 2.0.0
---

# Get-tpcConfigPaths

## SYNOPSIS
Retrieves all configured paths from the TPC_CONFIGPATH environment variable.

## SYNTAX

```
Get-tpcConfigPaths [-noDefault] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
This function returns an array of all paths currently configured in the
TPC_CONFIGPATH environment variable.

## EXAMPLES

### EXAMPLE 1
```
Get-tpcConfigPaths
```

Returns all configured paths.

### EXAMPLE 2
```
Get-tpcConfigPaths -noDefault
```

Returns all configured paths excluding the module's default config directory.

## PARAMETERS

### -noDefault
If specified, excludes the module's default config directory from the returned paths.

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

### String[]. Array of configuration paths.
## NOTES

## RELATED LINKS
