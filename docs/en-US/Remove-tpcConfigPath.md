---
external help file: psTerminalPerfCounter-help.xml
Module Name: psTerminalPerfCounter
online version:
schema: 2.0.0
---

# Remove-tpcConfigPath

## SYNOPSIS
Removes a configuration path from the TPC_CONFIGPATH environment variable.

## SYNTAX

```
Remove-tpcConfigPath [-All] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
This function displays all currently configured paths in the TPC_CONFIGPATH environment
variable as a numbered list and allows the user to select which path(s) to remove.

The function provides an interactive selection menu where users can choose paths by number.

## EXAMPLES

### EXAMPLE 1
```
Remove-tpcConfigPath
```

Shows an interactive menu to select and remove configuration paths.

### EXAMPLE 2
```
Remove-tpcConfigPath -All
```

Removes all configuration paths without prompting.

## PARAMETERS

### -All
If specified, removes all paths from the TPC_CONFIGPATH environment variable without prompting.

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

### None. Updates the TPC_CONFIGPATH environment variable.
## NOTES

## RELATED LINKS
