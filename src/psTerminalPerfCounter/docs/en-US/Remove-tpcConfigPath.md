---
external help file: psTerminalPerfCounter-help.xml
Module Name: psTerminalPerfCounter
online version:
schema: 2.0.0
---

# Remove-tpcConfigPath

## SYNOPSIS
Removes custom configuration paths from the TPC_CONFIGPATH environment variable.

## SYNTAX

```
Remove-tpcConfigPath [-All] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
This function provides an interactive menu to remove custom paths from the TPC_CONFIGPATH user
environment variable.
It displays all currently configured paths with their existence status
and allows the user to select which path(s) to remove.

The function provides an interactive selection menu where users can choose paths by number.
Paths are displayed with indicators showing whether they exist (✓) or not (✗).

Note: This function only affects custom paths stored in the environment variable.
The module's
default config directory cannot be removed through this function.

## EXAMPLES

### EXAMPLE 1
```
Remove-tpcConfigPath
```

Shows an interactive menu to select and remove custom configuration paths.
Displays path existence status and allows sequential removal with confirmation.

### EXAMPLE 2
```
Remove-tpcConfigPath -All
```

Removes all custom configuration paths from TPC_CONFIGPATH without prompting.

## PARAMETERS

### -All
If specified, removes all custom paths from the TPC_CONFIGPATH environment variable without prompting.
The module's default config directory is not affected.

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

### None. Updates the TPC_CONFIGPATH user environment variable.
## NOTES
Related commands:
- Get-tpcConfigPaths: List all configured paths
- Add-tpcConfigPath: Add new paths to configuration
- Get-tpcAvailableCounterConfig: View available configurations from all paths

## RELATED LINKS
