---
external help file: psTerminalPerfCounter-help.xml
Module Name: psTerminalPerfCounter
online version:
schema: 2.0.0
---

# Add-tpcConfigPath

## SYNOPSIS
Adds a configuration path to the TPC_CONFIGPATH environment variable.

## SYNTAX

```
Add-tpcConfigPath [-Path] <String> [-Force] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
This function adds a new path to the TPC_CONFIGPATH environment variable which is used
throughout the module to locate configuration files.
The function validates the path
existence and offers to create it if it doesn't exist.
Supports both local and network paths.

Paths are stored comma-separated in the environment variable.

## EXAMPLES

### EXAMPLE 1
```
Add-tpcConfigPath -Path "C:\MyConfigs"
```

Adds a local path to the configuration path list.

### EXAMPLE 2
```
Add-tpcConfigPath -Path "\\server\share\configs" -Force
```

Adds a network path to the configuration path list and creates it if necessary without prompting.

## PARAMETERS

### -Path
The path to add to the configuration path list.
Can be a local path or UNC network path.
The path will be validated for proper format and existence.

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

### -Force
If specified, creates the path without prompting if it doesn't exist.

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
