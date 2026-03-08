# Konzept: Value Export (JSON + CSV)

## Uebersicht

Der Export wird nach jedem abgeschlossenen Batch-Durchlauf getriggert (nach `GetAllValuesBatched()` bzw. `GetValuesBatched()`). Dadurch ist garantiert, dass alle Server abgefragt wurden und das Dataset vollstaendig ist. Null-Werte sind echte Information, kein Timing-Artefakt.

Zwei Exportformate mit unterschiedlichen Aufgaben:

| | JSON (Live) | CSV (Archiv) |
|---|---|---|
| Zweck | Browser-Visualisierung (PSWriteHTML) | Vollstaendige Historie fuer User |
| Schreibmodus | Overwrite (Rolling Window) | Append |
| Inhalt | Letzte N Punkte aus HistoricalData | Jeder Messwert, akkumuliert |
| Dateigroesse | Konstant (~50-100 KB) | Wachsend |
| Trigger | Nach jedem Batch-Durchlauf | Nach jedem Batch-Durchlauf |

---

## JSON Export (Rolling Window, Overwrite)

### Strategie

Das JSON spiegelt den aktuellen In-Memory-Stand von HistoricalData wider. Da MaxHistoryPoints bereits die Anzahl der Datenpunkte begrenzt, bleibt die Dateigroesse konstant. Bei jedem Batch-Durchlauf wird die Datei komplett ueberschrieben.

### Begruendung Rolling Window

- Browser-Performance: ApexCharts (PSWriteHTML) wird ab ca. 1.000-2.000 Datenpunkten pro Serie langsam
- DOM-Last: Jeder Datenpunkt erzeugt SVG-Pfade, mehr Punkte = mehr RAM im Browser
- Parsing: Bei Auto-Refresh muss der Browser das komplette JSON jedes Mal neu parsen
- Mit Rolling Window bleibt die Datei klein und der Browser performant, auch bei stundenlangem Betrieb

### Struktur

Kompatibel mit PSWriteHTML (siehe structure_ExportData.json):

```json
{
  "Intervall": 1,
  "Computer": {
    "SRV-DB01": {
      "Processor(_Total)\\% Processor Time": {
        "Title": "CPU Auslastung",
        "Unit": "%",
        "Values": {
          "2025-08-04T10:00:00": 15.2,
          "2025-08-04T10:00:30": 23.8
        }
      }
    }
  }
}
```

### Datenquelle

Transformation aus dem bestehenden Objektmodell:

- EnvironmentConfiguration.Servers[] -> Computer-Keys
- ServerConfiguration.ComputerName -> Computer-Name
- CounterConfiguration.CounterPath -> Counter-Key
- CounterConfiguration.Title -> Title
- CounterConfiguration.Unit -> Unit
- CounterConfiguration.HistoricalData[] -> Values (Timestamp als Key, Value als Wert)

---

## CSV Export (Vollstaendige Historie, Append)

### Strategie

Die CSV akkumuliert jeden Messwert ueber die gesamte Laufzeit. Nach jedem Batch-Durchlauf werden die neuen Werte als Zeilen angehaengt. Der Header wird nur einmal beim Erstellen der Datei geschrieben.

### Format: Long-Format

```csv
Timestamp,Computer,CounterPath,Title,Unit,Value
2025-08-04T10:00:00,SRV-DB01,Processor(_Total)\% Processor Time,CPU Auslastung,%,15.2
2025-08-04T10:00:00,SRV-DB01,Memory\Available MBytes,Verfuegbarer Arbeitsspeicher,MB,2048
2025-08-04T10:00:00,SRV-WEB02,Processor(_Total)\% Processor Time,CPU Auslastung,%,8.3
```

### Begruendung Long-Format

- Append funktioniert problemlos, Header einmal, dann nur Zeilen
- Neue Server oder Counter aendern nicht die Spaltenstruktur
- Standardformat fuer Analyse-Tools (Pivot in Excel, groupby in pandas, Power BI)
- Wide-Format waere bei Append problematisch: neue Counter wuerden die Spaltenstruktur brechen

### Datenquelle

Pro Batch-Durchlauf wird fuer jeden Counter nur der neueste DataPoint geschrieben (nicht die gesamte HistoricalData), da die vorherigen Punkte bereits in frueheren Durchlaeufen geschrieben wurden.

---

## Implementierung

### Trigger-Punkt

Der Export wird direkt nach dem Batch-Aufruf in Start-MonitoringLoop getriggert:

- Environment-Modus: Nach GetAllValuesBatched() (Zeile 79)
- Local/RemoteSingle: Nach GetValuesBatched() (Zeile 23)

### Methoden

- JSON: Instanzmethode auf EnvironmentConfiguration (hat Zugriff auf alle Server und Counter). Fuer Local/Single eine statische Methode auf CounterConfiguration die eine List of CounterConfiguration entgegennimmt.
- CSV: Gleiche Aufteilung. Schreibt pro Durchlauf nur die aktuellen neuen Werte (letzter DataPoint pro Counter).

### Ablauf pro Batch-Zyklus

```
1. GetAllValuesBatched()          -> Werte sammeln (bestehend)
2. ExportJson(pfad)               -> JSON mit Rolling Window ueberschreiben
3. ExportCsvAppend(pfad)          -> Neue Zeilen an CSV anhaengen
4. Anzeige aktualisieren          -> Show-CounterTable etc. (bestehend)
5. Start-Sleep                    -> Intervall abwarten (bestehend)
```
