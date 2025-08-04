# Performance Counter Line Chart Demo für PSWriteHTML
# Basierend auf der Analyse der PSWriteHTML Beispiele

# 1. Ihre vorgeschlagene Datenstruktur (leicht angepasst)
$performanceData = @{
    Intervall = 1  # Sekunden
    Computer = @{
        "Server01" = @{
            "Processor(_Total)\% Processor Time" = @{
                Title = "CPU Auslastung"
                Unit = "%"
                Values = @{
                    "2025-08-04T10:00:00" = 15.2
                    "2025-08-04T10:00:01" = 18.7
                    "2025-08-04T10:00:02" = 22.1
                    "2025-08-04T10:00:03" = 19.8
                    "2025-08-04T10:00:04" = 16.5
                    "2025-08-04T10:00:05" = 24.3
                    "2025-08-04T10:00:06" = 28.9
                    "2025-08-04T10:00:07" = 25.6
                    "2025-08-04T10:00:08" = 21.4
                    "2025-08-04T10:00:09" = 17.8
                }
            }
            "Memory\Available MBytes" = @{
                Title = "Verfügbarer Arbeitsspeicher"
                Unit = "MB"
                Values = @{
                    "2025-08-04T10:00:00" = 2048
                    "2025-08-04T10:00:01" = 2045
                    "2025-08-04T10:00:02" = 2040
                    "2025-08-04T10:00:03" = 2038
                    "2025-08-04T10:00:04" = 2042
                    "2025-08-04T10:00:05" = 2035
                    "2025-08-04T10:00:06" = 2030
                    "2025-08-04T10:00:07" = 2033
                    "2025-08-04T10:00:08" = 2037
                    "2025-08-04T10:00:09" = 2041
                }
            }
            "Network Interface(Realtek PCIe 2.5GbE Family Controller)\Bytes Total/sec" = @{
                Title = "Netzwerk Traffic"
                Unit = "Bytes/sec"
                Values = @{
                    "2025-08-04T10:00:00" = 156743
                    "2025-08-04T10:00:01" = 189234
                    "2025-08-04T10:00:02" = 201567
                    "2025-08-04T10:00:03" = 178923
                    "2025-08-04T10:00:04" = 165432
                    "2025-08-04T10:00:05" = 243876
                    "2025-08-04T10:00:06" = 289012
                    "2025-08-04T10:00:07" = 256789
                    "2025-08-04T10:00:08" = 214356
                    "2025-08-04T10:00:09" = 178901
                }
            }
        }
    }
}

# 2. Funktion zur Konvertierung für PSWriteHTML Line Charts
function ConvertTo-PSWriteHTMLLineChart {
    param(
        [hashtable]$PerformanceData,
        [string]$ComputerName,
        [string]$HtmlFilePath
    )

    # Computer-Daten extrahieren
    $computerData = $PerformanceData.Computer[$ComputerName]

    # Zeitstempel aus dem ersten Counter extrahieren (alle sollten gleich sein)
    $firstCounter = $computerData.Values | Select-Object -First 1
    $timestamps = $firstCounter.Values.Keys | Sort-Object

    # Labels für X-Achse (nur Uhrzeiten anzeigen)
    $labels = $timestamps | ForEach-Object {
        ([DateTime]$_).ToString("HH:mm:ss")
    }

    Import-Module PSWriteHTML -ErrorAction Stop

    New-HTML -TitleText "Performance Monitor - $ComputerName" -FilePath $HtmlFilePath -Show {

        # Übersichts-Tabelle
        New-HTMLSection -HeaderText "Performance Counter Übersicht" {
            $overviewData = foreach ($counterName in $computerData.Keys) {
                $counter = $computerData[$counterName]
                $values = $counter.Values.Values
                [PSCustomObject]@{
                    'Counter' = $counterName
                    'Titel' = $counter.Title
                    'Einheit' = $counter.Unit
                    'Min' = ($values | Measure-Object -Minimum).Minimum
                    'Max' = ($values | Measure-Object -Maximum).Maximum
                    'Durchschnitt' = [Math]::Round(($values | Measure-Object -Average).Average, 2)
                    'Samples' = $values.Count
                }
            }
            New-HTMLTable -DataTable $overviewData -HideFooter
        }

        # Line Chart für jeden Counter
        foreach ($counterName in $computerData.Keys) {
            $counter = $computerData[$counterName]
            $values = $timestamps | ForEach-Object { $counter.Values[$_] }

            New-HTMLSection -HeaderText "$($counter.Title) ($($counter.Unit))" {
                New-HTMLChart -Title "$($counter.Title) - Zeitverlauf" -TitleAlignment center {
                    New-ChartAxisX -Name $labels
                    # Serie mit Unit-Info für Tooltip
                    $seriesName = "$($counter.Title) ($($counter.Unit))"
                    New-ChartLine -Name $seriesName -Value $values -Color "#007acc"
                    # Y-Achse nur mit Unit-Titel (keine Zahlen-Parameter verfügbar)
                    New-ChartAxisY -Show -TitleText $counter.Unit
                }
            }
        }

        # Kombinierter Chart mit mehreren Y-Achsen
        New-HTMLSection -HeaderText "Kombinierte Ansicht" {
            New-HTMLChart -Title "Alle Counter (Multiple Y-Achsen)" -TitleAlignment center {
                New-ChartAxisX -Name $labels

                # Farben für verschiedene Counter
                $colors = @("#007acc", "#ff6b35", "#4caf50", "#ff9800", "#9c27b0")
                $colorIndex = 0

                # Sammle einzigartige Units für Y-Achsen
                $uniqueUnits = $computerData.Values | ForEach-Object { $_.Unit } | Select-Object -Unique
                $useOpposite = $false

                foreach ($counterName in $computerData.Keys) {
                    $counter = $computerData[$counterName]
                    $values = $timestamps | ForEach-Object { $counter.Values[$_] }

                    # Serie mit Unit-Info für Tooltip erstellen
                    $seriesName = "$($counter.Title) ($($counter.Unit))"
                    New-ChartLine -Name $seriesName -Value $values -Color $colors[$colorIndex % $colors.Count]

                    $colorIndex++
                }

                # Y-Achsen für jede einzigartige Unit erstellen
                foreach ($unit in $uniqueUnits) {
                    # Finde Counter mit dieser Unit
                    $countersWithUnit = $computerData.Keys | Where-Object { $computerData[$_].Unit -eq $unit }
                    $seriesNames = $countersWithUnit | ForEach-Object { "$($computerData[$_].Title) ($($computerData[$_].Unit))" }

                    if ($useOpposite) {
                        New-ChartAxisY -Show -Opposite -TitleText $unit -SeriesName $seriesNames
                    } else {
                        New-ChartAxisY -Show -TitleText $unit -SeriesName $seriesNames
                    }
                    $useOpposite = -not $useOpposite  # Wechsle zwischen links und rechts
                }
            }
        }
    }
}

# 3. Demo ausführen
$outputPath = "$PSScriptRoot\PerformanceCounter-Demo.html"
ConvertTo-PSWriteHTMLLineChart -PerformanceData $performanceData -ComputerName "Server01" -HtmlFilePath $outputPath

Write-Host "Demo-Chart erstellt: $outputPath" -ForegroundColor Green

# 4. Beispiel-Code für Ihre Performance Counter Implementierung
Write-Host "`n=== IMPLEMENTIERUNGS-HINWEISE ===" -ForegroundColor Yellow
Write-Host @"

Ihre Datenstruktur sollte so aufgebaut werden:

`$exportData = @{
    Intervall = `$intervallInSekunden
    Computer = @{}
}

# Für jeden Computer:
`$exportData.Computer[`$computerName] = @{}

# Für jeden Counter:
`$exportData.Computer[`$computerName][`$counterName] = @{
    Title = `$displayName     # z.B. "CPU Auslastung"
    Unit = `$unit            # z.B. "%", "MB", "MB/sec"
    Values = @{}             # Hashtable mit Timestamp = Wert
}

# Werte hinzufügen:
`$exportData.Computer[`$computerName][`$counterName].Values[`$timestamp] = `$value

WICHTIG:
- Timestamps als String im ISO-Format: (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss")
- Alle Counter eines Computers sollten die gleichen Timestamps haben
- Values sollten numerisch sein (Int/Double)
- PSWriteHTML benötigt für Line Charts Arrays in der richtigen Reihenfolge
- Parameter 'ShowTickLabels' existiert NICHT in PSWriteHTML (Y-Achsen zeigen immer Zahlen)
- Units werden im Tooltip angezeigt durch Serienname: 'Titel (Unit)'
- Mehrere Y-Achsen für verschiedene Einheiten verwenden -SeriesName Parameter

"@ -ForegroundColor Cyan
