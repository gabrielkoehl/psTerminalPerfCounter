---
external help file: psTerminalPerfCounter-help.xml
Module Name: psTerminalPerfCounter
online version:
schema: 2.0.0
---

# Start-tpcEnvironmentMonitor

## SYNOPSIS

## SYNTAX

```
Start-tpcEnvironmentMonitor [-EnvConfigPath] <String> [[-UpdateInterval] <Int32>] [-Tui] [-ExportCsv]
 [[-CsvPath] <String>] [-ExportHtml] [[-HtmlPath] <String>] [[-HtmlGroupBy] <String>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Starts parallel environment monitoring across multiple remote servers using a JSON environment configuration.

## EXAMPLES

### EXAMPLE 1
```
Start-tpcEnvironmentMonitor -EnvConfigPath "C:\Configs\SQL_PROD.json"
```

Starts environment monitoring using the interval defined in the JSON config.

### EXAMPLE 2
```
Start-tpcEnvironmentMonitor -EnvConfigPath "C:\Configs\SQL_PROD.json" -UpdateInterval 5
```

Starts environment monitoring with a 5-second update interval.

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

### -Tui
(Beta) Launches an interactive Terminal GUI (Terminal.Gui) instead of the scrolling console output.
For environment monitoring the TUI shows a table-only view (counters are not graphed across servers).

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

### -ExportCsv
Enables CSV export of counter values after each batch cycle (append mode, long format).

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

### -CsvPath
Directory path for the CSV export file.
Default: Desktop.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: [Environment]::GetFolderPath('Desktop')
Accept pipeline input: False
Accept wildcard characters: False
```

### -ExportHtml
Enables HTML report export after each batch cycle using PSWriteHTML.
The report contains a counter overview table, a combined chart and individual charts per counter.

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

### -HtmlPath
Directory path for the HTML report file.
Default: Desktop.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: [Environment]::GetFolderPath('Desktop')
Accept pipeline input: False
Accept wildcard characters: False
```

### -HtmlGroupBy
Controls how individual tabs are grouped in the HTML report.
'Counter' (default): one tab per counter type, series per host - best for comparing hosts.
'Host': one tab per host, series per counter - best for viewing a single host's metrics.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: Counter
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
