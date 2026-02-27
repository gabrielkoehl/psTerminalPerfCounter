---
external help file: psTerminalPerfCounter-help.xml
Module Name: psTerminalPerfCounter
online version:
schema: 2.0.0
---

# Add-tpcConfigPath

## SYNOPSIS
Adds a custom configuration path to the TPC_CONFIGPATH user environment variable.

## SYNTAX

```
Add-tpcConfigPath [-Path] <String> [-Force] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
{{ Fill in the Description }}

## EXAMPLES

### EXAMPLE 1
```
Add-tpcConfigPath -Path "C:\MyConfigs"
```

### EXAMPLE 2
```
Add-tpcConfigPath -Path "\\server\share\configs" -Force
```

## PARAMETERS

### -Path
Absolute local or UNC path to add.
Will be validated and optionally created.

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
Creates the path without prompting if it doesn't exist.

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
