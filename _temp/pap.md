# PowerShell Terminal Performance Counter (psTerminalPerfCounter) - Programmablaufplan (PAP)

## 1. Modulstruktur und Initialisierung

### 1.1 Modul-Manifest (psTerminalPerfCounter.psd1)
- **ModuleVersion**: 0.1.0
- **RequiredModules**: GripDevJsonSchemaValidator
- **FunctionsToExport**:
  - Get-tpcAvailableCounterConfig
  - Get-tpcPerformanceCounterInfo
  - Start-tpcMonitor
  - Add-tpcConfigPath
  - Remove-tpcConfigPath
  - Get-tpcConfigPaths

### 1.2 Modul-Initialisierung (psTerminalPerfCounter.psm1)
```
Schritt 1: Konfiguration von Script-Variablen
├── $script:TPC_CONFIG_PATH_VAR = "TPC_CONFIGPATH"
├── $script:DEFAULT_CONFIG_PATH = Join-Path $PSScriptRoot "Config"
└── $script:JSON_SCHEMA_FILE = Join-Path $script:DEFAULT_CONFIG_PATH "schema.json"

Schritt 2: Laden der Modul-Komponenten
├── Classes/*.ps1 (PerformanceCounter-Klasse)
├── Public/*.ps1 (Öffentliche Funktionen)
├── Private/*.ps1 (Private Hilfsfunktionen)
└── GraphicalEngine/*.ps1 (Grafik-Engine)

Schritt 3: Export der öffentlichen Funktionen
```

## 2. Hauptablauf - Start-tpcMonitor

### 2.1 Parameter-Verarbeitung
```
Parameter (Start-tpcMonitor):
├── ConfigName: string (Default: "CPU")
├── ConfigPath: string (alternativ zu ConfigName)
├── UpdateInterval: int (Default: 1 Sekunde)
└── MaxHistoryPoints: int (Default: 100)

Parameter-Sets:
├── 'ConfigName' (Standard)
└── 'ConfigPath' (Direkter Pfad)
```

### 2.2 Konfiguration laden
```
IF ConfigPath angegeben:
    ├── Test-Path $ConfigPath
    ├── Validierung: Dateiname = 'tpc_*.json'
    └── Get-PerformanceConfig -ConfigPath $ConfigPath
ELSE:
    └── Get-PerformanceConfig -ConfigName $ConfigName
```

### 2.3 Get-PerformanceConfig Workflow
```
Parameter:
├── ConfigName: string ODER
└── ConfigPath: string

IF ConfigPath-Modus:
    ├── Get-Content $ConfigPath -Raw
    ├── ConvertFrom-Json
    └── New-PerformanceCountersFromJson
ELSE ConfigName-Modus:
    ├── Get-tpcConfigPaths
    ├── Suche nach "tpc_$ConfigName.json" in allen Pfaden
    ├── Duplikat-Prüfung
    ├── Get-Content der gefundenen Datei
    ├── ConvertFrom-Json
    └── New-PerformanceCountersFromJson

Rückgabe:
├── Name: string
├── Description: string
├── Counters: PerformanceCounter[]
└── ConfigPath: string
```

### 2.4 Counter-Verfügbarkeit testen
```
Test-CounterAvailability -Counters $Config.Counters
├── Für jeden Counter:
│   ├── $Counter.TestAvailability()
│   │   ├── Get-Counter -Counter $CounterPath -MaxSamples 1
│   │   ├── IsAvailable = true/false
│   │   └── LastError setzen bei Fehler
│   └── Ergebnis-Objekt erstellen
└── Verfügbare/Nicht-verfügbare Counter trennen
```

## 3. PerformanceCounter-Klasse

### 3.1 Konstruktor-Parameter
```
PerformanceCounter([string]$counterID, [string]$counterSetType, [string]$counterInstance,
                  [string]$title, [string]$Type, [string]$Format, [string]$unit,
                  [int]$conversionFactor, [int]$conversionExponent,
                  [psobject]$colorMap, [psobject]$graphConfiguration)
```

### 3.2 Eigenschaften
```
├── counterID: string (z.B. "238-6")
├── counterSetType: string ("SingleInstance" | "MultiInstance")
├── counterInstance: string (z.B. "_Total")
├── CounterPath: string (generiert via GetCounterPath())
├── Title: string
├── Type: string ("Percentage" | "Number")
├── Format: string ("graph" | "table" | "both")
├── Unit: string (z.B. "%", "Threads")
├── conversionFactor/conversionExponent: int
├── ColorMap: hashtable (Schwellenwerte -> Farben)
├── GraphConfiguration: hashtable
├── HistoricalData: List[PSCustomObject] (Timestamp + Value)
├── Statistics: hashtable (Current, Min, Max, Average, Count, Last5)
├── IsAvailable: bool
├── LastError: string
└── LastUpdate: datetime
```

### 3.3 Methoden
```
GetCounterPath():
├── Split counterID in setID und pathID
├── Get-PerformanceCounterLocalName für beide IDs
├── IF SingleInstance: "\$setName\$pathName"
└── IF MultiInstance: "\$setName($counterInstance)\$pathName"

TestAvailability():
├── Get-Counter -Counter $CounterPath -MaxSamples 1
├── IsAvailable = true/false
└── LastError setzen

GetCurrentValue():
├── Get-Counter -Counter $CounterPath -MaxSamples 1
├── CookedValue extrahieren
├── Einheiten-Konvertierung: value / (conversionFactor ^ conversionExponent)
└── Math.Round()

AddDataPoint(value, maxHistoryPoints):
├── PSCustomObject mit Timestamp + Value erstellen
├── HistoricalData.Add()
├── LastUpdate setzen
├── Historische Daten begrenzen (älteste entfernen)
└── UpdateStatistics() aufrufen

GetGraphData(sampleCount):
├── Values aus HistoricalData extrahieren
├── IF dataCount >= sampleCount: Letzte sampleCount nehmen
└── ELSE: Mit Nullen auffüllen
```

## 4. Monitoring-Loop (Start-MonitoringLoop)

### 4.1 Parameter
```
Parameter:
├── Counters: PerformanceCounter[]
├── Config: hashtable
├── UpdateInterval: int
└── MaxDataPoints: int
```

### 4.2 Hauptschleife
```
WHILE (true):
    ├── SampleCount++
    ├── Für jeden Counter:
    │   ├── $Value = $Counter.GetCurrentValue()
    │   └── $Counter.AddDataPoint($Value, $MaxDataPoints)
    ├── Show-SessionHeader -ConfigName -StartTime -SampleCount
    ├── Counter nach Format trennen:
    │   ├── graphCounters = Format "graph" | "both"
    │   └── tableCounters = Format "table" | "both"
    ├── Für jeden graphCounter:
    │   └── Show-CounterGraph -Counter $Counter
    ├── IF tableCounters vorhanden:
    │   └── Show-CounterTable -Counters $tableCounters
    └── Start-Sleep -Seconds $UpdateInterval
```

## 5. Grafik-Darstellung

### 5.1 Show-CounterGraph
```
Parameter:
└── Counter: PerformanceCounter

Workflow:
├── $Config = $Counter.GraphConfiguration
├── $GraphData = $Counter.GetGraphData($Config.Samples)
├── $YAxisStep = Get-AdaptiveYAxisStep
├── Show-Graph mit Parametern:
│   ├── Datapoints: $GraphData
│   ├── GraphTitle: $Counter.GetFormattedTitle()
│   ├── Type: $Config.GraphType
│   ├── YAxisStep: $YAxisStep
│   ├── yAxisMaxRows: $Config.yAxisMaxRows
│   └── ColorMap: $Counter.ColorMap (optional)
├── IF ShowStatistics: Show-CounterStatistic
└── Leerzeilen für Abstand
```

### 5.2 Show-Graph (GraphicalEngine)
```
Parameter:
├── Datapoints: int[]
├── GraphTitle: string
├── XAxisStep: int (Default: 10)
├── YAxisStep: int (Default: 10)
├── yAxisMaxRows: int (Default: 10)
├── Type: string ("Bar" | "Scatter" | "Line")
└── ColorMap: hashtable (optional)

Workflow:
├── Unicode-Zeichen für Rahmen definieren
├── Min/Max/Range der Y-Achse berechnen
├── Y-Werte formatieren (k, M für große Zahlen)
├── Graph-Matrix erstellen
├── Je nach Type:
│   ├── Bar: Get-BarPlot
│   ├── Line: Get-LinePlot
│   └── Scatter: Get-ScatterPlot
└── Graph mit Farben ausgeben
```

## 6. Konfigurationsverwaltung

### 6.1 Get-tpcConfigPaths
```
Parameter:
└── noDefault: switch

Workflow:
├── $paths = @()
├── IF NOT noDefault:
│   └── $paths += $script:DEFAULT_CONFIG_PATH
├── $envPaths = Environment::GetEnvironmentVariable("TPC_CONFIGPATH")
├── IF envPaths vorhanden:
│   ├── Split bei Komma
│   ├── Trim Leerzeichen
│   └── $paths += gefilterte Pfade
└── Return: Unique sortierte Pfade
```

### 6.2 JSON-Konfiguration (Beispiel tpc_CPU.json)
```
Struktur:
├── name: "CPU Performance"
├── description: "CPU utilization and queue monitoring"
└── counters: Array von:
    ├── title: string
    ├── unit: string
    ├── conversionFactor/conversionExponent: int
    ├── type: "Percentage" | "Number"
    ├── format: "graph" | "table" | "both"
    ├── counterID: "238-6" (setID-pathID)
    ├── counterSetType: "SingleInstance" | "MultiInstance"
    ├── counterInstance: string (z.B. "_Total")
    ├── colorMap: Schwellenwerte -> Farben
    └── graphConfiguration:
        ├── Samples: int (Graph-Breite)
        ├── graphType: "Bar" | "Line" | "Scatter"
        ├── showStatistics: bool
        ├── yAxisStep: int
        ├── yAxisMaxRows: int
        └── colors: title/statistics/default Farben
```

## 7. Datenfluss-Übersicht

```
Start-tpcMonitor
├── Parameter-Validierung
├── Get-PerformanceConfig
│   ├── Get-tpcConfigPaths
│   ├── JSON laden und parsen
│   └── New-PerformanceCountersFromJson
│       └── PerformanceCounter-Objekte erstellen
├── Test-CounterAvailability
│   └── Für jeden Counter: TestAvailability()
├── Verfügbare Counter filtern
└── Start-MonitoringLoop
    ├── LOOP:
    │   ├── Für jeden Counter: GetCurrentValue() + AddDataPoint()
    │   ├── Show-SessionHeader
    │   ├── Show-CounterGraph
    │   │   ├── GetGraphData()
    │   │   └── Show-Graph (GraphicalEngine)
    │   ├── Show-CounterTable (optional)
    │   └── Sleep
    └── Bei Beendigung: Show-SessionSummary
```

## 8. Fehlerbehandlung

### 8.1 Ebenen der Fehlerbehandlung
```
1. Parameter-Validierung:
   ├── ConfigPath existiert
   ├── Dateiname-Konvention 'tpc_*.json'
   └── Parameter-Sets (ConfigName XOR ConfigPath)

2. JSON-Verarbeitung:
   ├── Datei lesbar
   ├── JSON parsbar
   └── Schema-Validierung (GripDevJsonSchemaValidator)

3. Counter-Verfügbarkeit:
   ├── Counter-Pfad auflösbar
   ├── Performance Counter verfügbar
   └── Berechtigung zum Lesen

4. Laufzeit-Fehler:
   ├── Counter-Lesefehler
   ├── Grafik-Darstellungsfehler
   └── Benutzer-Unterbrechung (Ctrl+C)
```

### 8.2 Error-Recovery
```
├── Nicht verfügbare Counter werden gefiltert, nicht abgebrochen
├── Counter-Lesefehler werden geloggt, aber Monitoring fortsetzt
├── Grafik-Fehler werden einzeln behandelt
└── Finally-Block für Session-Summary bei jeder Beendigung
```

## 9. Performance-Optimierungen

### 9.1 Daten-Management
```
├── HistoricalData als List[PSCustomObject] für bessere Performance
├── MaxHistoryPoints begrenzt Speicherverbrauch
├── GraphData wird on-demand generiert
└── Statistics werden nur bei AddDataPoint() aktualisiert
```

### 9.2 Display-Optimierungen
```
├── Graph-Samples unabhängig von HistoricalData
├── Y-Achsen-Werte formatiert (k, M für große Zahlen)
├── Adaptive Y-Achsen-Schritte
└── Color-Mapping über Schwellenwerte
```

## 10. Erweiterbarkeit

### 10.1 Plugin-System
```
├── GraphicalEngine als separate Komponente
├── Neue Graph-Typen über Type-Parameter erweiterbar
├── Counter-Konfiguration vollständig JSON-basiert
└── Multiple Config-Pfade über Umgebungsvariable
```

### 10.2 Multi-Language Support
```
├── Counter-IDs sprachunabhängig (numerisch)
├── Get-PerformanceCounterLocalName für Lokalisierung
└── Konfiguration in Englisch, Runtime lokalisiert
```

---

*Erstellt am: 5. August 2025*
*Modul-Version: 0.1.0*
*PowerShell-Kompatibilität: 5.1+*
