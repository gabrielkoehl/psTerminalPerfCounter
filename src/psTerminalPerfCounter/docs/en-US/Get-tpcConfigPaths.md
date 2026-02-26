---
external help file: psTerminalPerfCounter-help.xml
Module Name: psTerminalPerfCounter
online version:
schema: 2.0.0
---

# Get-tpcConfigPaths

## SYNOPSIS
Retrieves all configured paths from the TPC_CONFIGPATH environment variable and module defaults.

## SYNTAX

```
Get-tpcConfigPaths [-noDefault] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
This function returns an array of all paths where the module searches for configuration files.
By default, it includes the module's default config directory and any custom paths defined
in the TPC_CONFIGPATH user environment variable.

The function validates that each path exists and returns only valid paths.
Non-existent
paths generate warnings but do not cause the function to fail.

Paths are automatically deduplicated and sorted in the output.

## EXAMPLES

### EXAMPLE 1
```
Get-tpcConfigPaths
```

Returns all configured paths including the module's default config directory and
any custom paths from the TPC_CONFIGPATH environment variable.

### EXAMPLE 2
```
Get-tpcConfigPaths -noDefault
```

Returns only custom paths from the TPC_CONFIGPATH environment variable, excluding
the module's default config directory.

## PARAMETERS

### -noDefault
If specified, excludes the module's default config directory from the returned paths.
Only custom paths from the TPC_CONFIGPATH environment variable will be returned.

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

### String[]. Array of validated, unique configuration paths sorted alphabetically.
## NOTES
Custom paths are stored in the user-level TPC_CONFIGPATH environment variable.
The module's default config directory is always included unless -noDefault is specified.

Related commands:
- Add-tpcConfigPath: Add new paths to configuration
- Remove-tpcConfigPath: Remove paths from configuration
- Test-tpcAvailableCounterConfig: View available configurations from all paths

## RELATED LINKS
