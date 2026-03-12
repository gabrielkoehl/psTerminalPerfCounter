# TUI Implementation Plan

## Bestandsaufnahme

**Bereits implementiert:**
- `Format-TuiCell` — fertig
- `Format-TuiCenter` — fertig
- `Update-TuiHeader` — nur Stub
- `Show-TuiMainApplication` — Layout teilweise, aber keine Logik, keine Parameter, nutzt `$script:`-Scope implizit

---

## Funktionsliste (atomar, ohne `$script:`-Scope)

### 1. `New-TuiSparkBlocks` (Pure Data)
**Zweck:** Gibt das Array der 9 Unicode-Block-Zeichen zurueck (Konstante).
| Parameter | Typ | Beschreibung |
|-----------|-----|-------------|
| *(keine)* | — | — |
| **Return** | `char[]` | Array mit 9 Zeichen (Space + U+2581..U+2588) |

---

### 2. `New-TuiColumnNames` (Pure Data)
**Zweck:** Erzeugt die Hashtable mit zentrierten Spaltennamen.
| Parameter | Typ | Beschreibung |
|-----------|-----|-------------|
| *(keine)* | — | Nutzt intern `Format-TuiCenter` |
| **Return** | `hashtable` | Keys: Computer, Counter, Unit, Current, Last5, Min, Max, Avg, Samples |

---

### 3. `New-TuiDataTable`
**Zweck:** Erzeugt die `System.Data.DataTable` mit allen Spalten.
| Parameter | Typ | Beschreibung |
|-----------|-----|-------------|
| `ColumnNames` | `hashtable` | Output von `New-TuiColumnNames` |
| **Return** | `System.Data.DataTable` | Leere DataTable mit 9 String-Spalten |

---

### 4. `New-TuiLayout`
**Zweck:** Baut das gesamte UI-Layout auf (Window, Frames, Labels, Buttons). Gibt ein State-Objekt zurueck.
| Parameter | Typ | Beschreibung |
|-----------|-----|-------------|
| `DataTable` | `System.Data.DataTable` | Die vorbefuellte DataTable |
| `ColumnNames` | `hashtable` | Fuer ColumnStyles-Zuordnung |
| **Return** | `hashtable` | Keys: `Window`, `HeaderLabel`, `TableView`, `SparkLabel`, `BtnPause`, `BtnToggle`, `BtnQuit` |

---

### 5. `Update-TuiHeader` (bestehender Stub → implementieren)
**Zweck:** Aktualisiert den Header-Text mit Session-Infos.
| Parameter | Typ | Beschreibung |
|-----------|-----|-------------|
| `HeaderLabel` | `Terminal.Gui.Label` | Das Header-Label-Widget |
| `ConfigName` | `string` | Name der Config/Environment |
| `StartTime` | `datetime` | Session-Startzeit |
| `CounterCount` | `int` | Anzahl Counter |
| `SampleCount` | `int` | Anzahl bisheriger Samples |
| `IsPaused` | `bool` | Pause-Status |
| `Interval` | `int` | Update-Intervall in Sekunden |

---

### 6. `Update-TuiTable`
**Zweck:** Baut alle Tabellenzeilen neu auf aus den Counter-Daten.
| Parameter | Typ | Beschreibung |
|-----------|-----|-------------|
| `DataTable` | `System.Data.DataTable` | Ziel-DataTable (Rows.Clear + Rebuild) |
| `TableView` | `Terminal.Gui.TableView` | Fuer `.Update()` Aufruf |
| `Counters` | `List[CounterConfiguration]` | Die Counter-Objekte mit Statistics |
| `ColumnNames` | `hashtable` | Fuer Spalten-Zuordnung |

---

### 7. `Get-TuiSparkline3Row`
**Zweck:** Erzeugt 3 Zeilen (top/mid/bottom) als Sparkline aus historischen Daten.
| Parameter | Typ | Beschreibung |
|-----------|-----|-------------|
| `Data` | `List[DataPoint]` | HistoricalData eines Counters |
| `MaxWidth` | `int` | Maximale Zeichenbreite (Default: 60) |
| `SparkBlocks` | `char[]` | Die 9 Block-Zeichen |
| **Return** | `string[]` | Array mit 3 Strings: [top, mid, bottom] |

---

### 8. `Update-TuiSparklines`
**Zweck:** Aktualisiert das Sparkline-Label fuer alle Counter.
| Parameter | Typ | Beschreibung |
|-----------|-----|-------------|
| `SparkLabel` | `Terminal.Gui.Label` | Das Sparkline-Label-Widget |
| `Counters` | `List[CounterConfiguration]` | Die Counter-Objekte |
| `SparkBlocks` | `char[]` | Die 9 Block-Zeichen |
| `ShowSparklines` | `bool` | Sichtbarkeit |

---

### 9. `Register-TuiEventHandlers`
**Zweck:** Registriert Button-Clicks und den Timer-Callback.
| Parameter | Typ | Beschreibung |
|-----------|-----|-------------|
| `Layout` | `hashtable` | Output von `New-TuiLayout` |
| `TuiState` | `hashtable` | Mutable State-Objekt (siehe unten) |
| `Counters` | `List[CounterConfiguration]` | Counter fuer Timer-Update |
| `ColumnNames` | `hashtable` | Fuer Table-Update im Timer |
| `DataTable` | `System.Data.DataTable` | Fuer Table-Update im Timer |
| `SparkBlocks` | `char[]` | Fuer Sparkline-Update im Timer |
| `Interval` | `int` | Timer-Intervall in Sekunden |

---

### 10. `Show-TuiMainApplication` (Orchestrator)
**Zweck:** Zentraler Einstiegspunkt — verdrahtet alles und startet `Application::Run()`.
| Parameter | Typ | Beschreibung |
|-----------|-----|-------------|
| `Counters` | `List[CounterConfiguration]` | Die Counter-Objekte (bereits befuellt) |
| `ConfigName` | `string` | Anzeigename der Config |
| `Interval` | `int` | Update-Intervall in Sekunden (Default: 2) |

---

## TuiState-Objekt (mutable Hashtable statt `$script:`-Variablen)

```powershell
$TuiState = @{
    IsPaused       = $false
    ShowSparklines = $true
    StartTime      = Get-Date
    SampleCount    = 0
}
```

Wird per Referenz an alle Funktionen uebergeben, die den Zustand lesen/aendern muessen. Hashtables sind Reference-Types in PowerShell — Aenderungen innerhalb einer Funktion wirken sich auf das Original aus.

---

## Aufruf-Reihenfolge im Orchestrator `Show-TuiMainApplication`

```
 1. [Application]::Init()
 2. $sparkBlocks  = New-TuiSparkBlocks
 3. $columnNames  = New-TuiColumnNames
 4. $dataTable    = New-TuiDataTable       -ColumnNames $columnNames
 5. $layout       = New-TuiLayout          -DataTable $dataTable -ColumnNames $columnNames
 6. $tuiState     = @{ IsPaused=$false; ShowSparklines=$true; StartTime=Get-Date; SampleCount=0 }
 7. Register-TuiEventHandlers              -Layout $layout -TuiState $tuiState -Counters $counters ...
 8. Update-TuiHeader      (initialer Aufruf)
 9. Update-TuiTable       (initialer Aufruf)
10. Update-TuiSparklines  (initialer Aufruf)
11. [Application]::Top.Add($layout.Window)
12. [Application]::Run()
13. [Application]::Shutdown()
```

---

## Dateistruktur (alles in GraphicalEngine/)

| Datei | Funktion | Status |
|-------|----------|--------|
| `Format-TuiCell.ps1` | `Format-TuiCell` | fertig |
| `Format-TuiCenter.ps1` | `Format-TuiCenter` | fertig |
| `New-TuiSparkBlocks.ps1` | `New-TuiSparkBlocks` | **neu** |
| `New-TuiColumnNames.ps1` | `New-TuiColumnNames` | **neu** |
| `New-TuiDataTable.ps1` | `New-TuiDataTable` | **neu** |
| `New-TuiLayout.ps1` | `New-TuiLayout` | **neu** (Extrakt aus bestehendem Show-TuiMainApplication) |
| `Update-TuiHeader.ps1` | `Update-TuiHeader` | **implementieren** |
| `Update-TuiTable.ps1` | `Update-TuiTable` | **neu** |
| `Get-TuiSparkline3Row.ps1` | `Get-TuiSparkline3Row` | **neu** |
| `Update-TuiSparklines.ps1` | `Update-TuiSparklines` | **neu** |
| `Register-TuiEventHandlers.ps1` | `Register-TuiEventHandlers` | **neu** |
| `Show-TuiMainApplication.ps1` | `Show-TuiMainApplication` | **umbauen** (wird reiner Orchestrator) |
