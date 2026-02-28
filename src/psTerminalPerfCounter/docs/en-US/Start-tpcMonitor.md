---
external help file: psTerminalPerfCounter-help.xml
Module Name: psTerminalPerfCounter
online version:
schema: 2.0.0
---

# Start-tpcMonitor

## SYNOPSIS

## SYNTAX

### RemoteByName
```
Start-tpcMonitor -ConfigName <String> -ComputerName <String> [-Credential <PSCredential>]
 [-UpdateInterval <Int32>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### ConfigName
```
Start-tpcMonitor -ConfigName <String> [-UpdateInterval <Int32>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

### RemoteByPath
```
Start-tpcMonitor -ConfigPath <String> -ComputerName <String> [-Credential <PSCredential>]
 [-UpdateInterval <Int32>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### ConfigPath
```
Start-tpcMonitor -ConfigPath <String> [-UpdateInterval <Int32>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Starts real-time performance counter monitoring for a single local or remote system.

## EXAMPLES

### EXAMPLE 1
```
Start-tpcMonitor -ConfigName "CPU"
```

Starts local CPU monitoring using the built-in CPU template.

### EXAMPLE 2
```
Start-tpcMonitor -ConfigPath "C:\MyConfigs\tpc_CustomCPU.json"
```

Starts monitoring using a custom configuration file.

### EXAMPLE 3
```
Start-tpcMonitor -ConfigName "Memory" -ComputerName "Server01" -Credential $cred -UpdateInterval 2
```

Starts remote memory monitoring with 2-second intervals.

## PARAMETERS

### -ConfigName
Name of the configuration template (without 'tpc_' prefix and '.json' extension).
Cannot be combined with ConfigPath.

```yaml
Type: String
Parameter Sets: RemoteByName, ConfigName
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ConfigPath
Absolute path to a JSON configuration file (pattern 'tpc_*.json').
Cannot be combined with ConfigName.

```yaml
Type: String
Parameter Sets: RemoteByPath, ConfigPath
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ComputerName
DNS name of the remote computer to monitor.

```yaml
Type: String
Parameter Sets: RemoteByName, RemoteByPath
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Credential
PSCredential for remote authentication.
Only applicable with ComputerName.

```yaml
Type: PSCredential
Parameter Sets: RemoteByName, RemoteByPath
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UpdateInterval
Seconds between counter updates.
Default: 1.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 1
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
