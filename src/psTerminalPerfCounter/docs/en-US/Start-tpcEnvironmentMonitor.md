---
external help file: psTerminalPerfCounter-help.xml
Module Name: psTerminalPerfCounter
online version:
schema: 2.0.0
---

# Start-tpcEnvironmentMonitor

## SYNOPSIS
Starts parallel environment monitoring across multiple remote servers using a JSON environment configuration.

## SYNTAX

```
Start-tpcEnvironmentMonitor [-EnvConfigPath] <String> [[-UpdateInterval] <Int32>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
{{ Fill in the Description }}

## EXAMPLES

### EXAMPLE 1
```
Start-tpcEnvironmentMonitor -EnvConfigPath "C:\Configs\SQL_PROD.json"
```

### EXAMPLE 2
```
Start-tpcEnvironmentMonitor -EnvConfigPath "C:\Configs\SQL_PROD.json" -UpdateInterval 5
```

## PARAMETERS

### -EnvConfigPath
Absolute path to the environment JSON configuration file.

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

### -UpdateInterval
Seconds between updates.
Default: uses interval from JSON config (fallback: 2s).

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: 0
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
