---
external help file: psTerminalPerfCounter-help.xml
Module Name: psTerminalPerfCounter
online version:
schema: 2.0.0
---

# Test-tpcServerConfiguration

## SYNOPSIS
Testet die ServerConfiguration-Klasse mit paralleler Counter-Abfrage

## SYNTAX

```
Test-tpcServerConfiguration [[-ComputerName] <String>] [[-ConfigName] <String>] [[-Credential] <PSCredential>]
 [[-Iterations] <Int32>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Diese Funktion ist zum Testen der neuen async ServerConfiguration-Funktionalität gedacht.
Sie erstellt eine ServerConfiguration-Instanz mit mehreren Countern und testet die
parallele Abfrage über GetValuesParallelAsync().

Zeigt:
- Server-Verfügbarkeit
- Parallele Counter-Abfrage
- Timestamp und Dauer
- Counter-Werte und Statistiken

## EXAMPLES

### EXAMPLE 1
```
Test-tpcServerConfiguration
```

Testet den lokalen Server mit CPU-Countern

### EXAMPLE 2
```
Test-tpcServerConfiguration -ComputerName "DEV-DC" -ConfigName "CPU" -Iterations 5
```

Testet den Remote-Server DEV-DC mit 5 Durchläufen

### EXAMPLE 3
```
Test-tpcServerConfiguration -ComputerName "DEV-NODE3" -Credential $cred
```

Testet Remote-Server mit expliziten Credentials

## PARAMETERS

### -ComputerName
Name des zu testenden Servers
Default: Localhost

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: $env:COMPUTERNAME
Accept pipeline input: False
Accept wildcard characters: False
```

### -ConfigName
Name der Counter-Konfiguration (ohne 'tpc_' und '.json')
Default: 'CPU'

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: CPU
Accept pipeline input: False
Accept wildcard characters: False
```

### -Credential
Credentials für Remote-Zugriff
Optional

```yaml
Type: PSCredential
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Iterations
Anzahl der Test-Durchläufe
Default: 3

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: 3
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

### Zeigt detaillierte Test-Ausgabe in der Konsole
## NOTES
Entwicklungs-/Test-Funktion für die ServerConfiguration-Klasse

## RELATED LINKS
