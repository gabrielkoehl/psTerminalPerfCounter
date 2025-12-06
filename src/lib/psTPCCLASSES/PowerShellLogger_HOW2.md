# PowerShellLogger - Technische Dokumentation

## Übersicht

Der `PowerShellLogger` ist eine Singleton-Klasse für thread-safe Logging in C# mit direkter Console-Ausgabe und optionalem File-Logging.

### Problem (Alt)
- Logger nutzte `PowerShell.Create(RunspaceMode.NewRunspace)`
- Isolierter Runspace → kein Zugriff auf Main-Console
- Output verschwand "ins Leere" oder erschien verzögert
- Funktionierte nicht zuverlässig aus Thread-Pool-Threads

### Lösung (Neu)
- **Singleton-Pattern**: Eine zentrale Logger-Instanz für die gesamte Anwendung
- **Writer-Pattern**: Modulare Output-Ziele über `ILogWriter` Interface
- **Direkte Console-Ausgabe**: `Console.WriteLine()` statt PowerShell Runspace
- **Thread-safe**: Alle Operationen sind mit Locks geschützt

---

## Architektur

```
PowerShellLogger (Singleton)
    └─ List<ILogWriter> _writers
        ├─ ConsoleLogWriter (Standard, immer aktiv)
        └─ FileLogWriter (Optional, aktivierbar)
```

### Singleton-Pattern
```csharp
// Einzige Instanz, beim ersten Zugriff erstellt
private static readonly PowerShellLogger _instance = new PowerShellLogger();

// Zugriff nur über diese Property
public static PowerShellLogger Instance => _instance;

// Konstruktor ist privat - keine direkte Instanziierung möglich
private PowerShellLogger() { ... }
```

**Vorteil**: Alle Klassen nutzen dieselbe Logger-Instanz, keine Parameter-Übergabe nötig.

### Writer-Pattern (ILogWriter)
```csharp
public interface ILogWriter
{
    void WriteInfo(string source, string message);
    void WriteWarning(string source, string message);
    void WriteError(string source, string message);
    void WriteVerbose(string source, string message);
}
```

**Vorteil**: Neue Output-Ziele können einfach hinzugefügt werden, ohne PowerShellLogger zu ändern.

---

## Klassen-Übersicht

### PowerShellLogger
Haupt-Logger-Klasse mit Singleton-Pattern.

**Wichtige Methoden:**
```csharp
// Log-Methoden (schreiben auf ALLE aktiven Writer)
void Info(string source, string message)
void Warning(string source, string message)
void Error(string source, string message)
void Verbose(string source, string message)

// Writer-Management
void AddWriter(ILogWriter writer)
void RemoveWriter(ILogWriter writer)
void EnableFileLogging(string logFilePath)
void DisableFileLogging()
```

**Verwendung in C#:**
```csharp
// In jeder Klasse als static field
private static readonly PowerShellLogger _logger = PowerShellLogger.Instance;

// Logging
_logger.Info("ClassName", "Dies ist eine Info-Nachricht");
_logger.Warning("ClassName", "Warnung!");
_logger.Error("ClassName", "Fehler aufgetreten");
```

### ConsoleLogWriter
Schreibt direkt auf `Console.WriteLine()` und `Console.Error.WriteLine()`.

**Features:**
- Sofort sichtbar in PowerShell
- ANSI-Farbcodes für visuelle Unterscheidung
- Funktioniert aus allen Threads

**Farben:**
- Info: Cyan (`\u001b[36m`)
- Warning: Gelb (`\u001b[33m`)
- Error: Rot (`\u001b[31m`)
- Verbose: Grau (`\u001b[90m`)

**Output-Format:**
```
[INFO] [ClassName] Nachricht
[WARNING] [ClassName] Nachricht
[ERROR] [ClassName] Nachricht
```

### FileLogWriter
Schreibt Log-Einträge in eine Datei mit Timestamps.

**Features:**
- Thread-safe mit Lock-Mechanismus
- Erstellt Verzeichnis automatisch
- Fehler beim Schreiben werden ignoriert (keine Exceptions)

**Log-Format:**
```
2025-10-26 14:30:45.123 [INFO] [ClassName] Nachricht
2025-10-26 14:30:45.456 [WARNING] [ClassName] Warnung
2025-10-26 14:30:45.789 [ERROR] [ClassName] Fehler
```

---

## PowerShell Nutzungs-Beispiele

### Logger-Instanz abrufen
```powershell
# Im Modul (psTerminalPerfCounter.psm1)
$script:logger = [psTPCCLASSES.PowerShellLogger]::Instance

# Oder manuell
$logger = [psTPCCLASSES.PowerShellLogger]::Instance
```

### File-Logging aktivieren
```powershell
# Einfaches File-Logging
$logger.EnableFileLogging("C:\Logs\perfcounter.log")

# Mit Datum im Dateinamen
$logPath = "C:\Logs\tpc-$(Get-Date -Format 'yyyyMMdd').log"
$logger.EnableFileLogging($logPath)

# Ab jetzt: Console UND Datei
$logger.Info("TEST", "Diese Nachricht erscheint in beiden Zielen")
```

### File-Logging deaktivieren
```powershell
$logger.DisableFileLogging()
# Ab jetzt wieder nur Console
```

### Test-Ausgaben
```powershell
$logger = [psTPCCLASSES.PowerShellLogger]::Instance

$logger.Info("TEST", "Info-Nachricht in Cyan")
$logger.Warning("TEST", "Warnung in Gelb")
$logger.Error("TEST", "Fehler in Rot")
$logger.Verbose("TEST", "Verbose in Grau")
```

### Aus C# Klassen
```csharp
public class CounterConfiguration
{
    // Singleton-Instanz als static field
    private static readonly PowerShellLogger _logger = PowerShellLogger.Instance;
    private readonly string _source = "CounterConfiguration";

    public void TestAvailability()
    {
        _logger.Info(_source, $"Testing {CounterPath}");

        try
        {
            // ... Counter-Test ...
        }
        catch (Exception ex)
        {
            _logger.Error(_source, $"Error: {ex.Message}");
        }
    }
}
```

---

## Eigene Writer erstellen

### Beispiel: EventLog-Writer
```csharp
using System.Diagnostics;

public class EventLogWriter : ILogWriter
{
    private readonly string _logName = "Application";
    private readonly string _sourceName = "psTerminalPerfCounter";

    public EventLogWriter()
    {
        // Event Source registrieren (einmalig, benötigt Admin-Rechte)
        if (!EventLog.SourceExists(_sourceName))
        {
            EventLog.CreateEventSource(_sourceName, _logName);
        }
    }

    public void WriteInfo(string source, string message)
    {
        EventLog.WriteEntry(_sourceName,
            $"[{source}] {message}",
            EventLogEntryType.Information);
    }

    public void WriteWarning(string source, string message)
    {
        EventLog.WriteEntry(_sourceName,
            $"[{source}] {message}",
            EventLogEntryType.Warning);
    }

    public void WriteError(string source, string message)
    {
        EventLog.WriteEntry(_sourceName,
            $"[{source}] {message}",
            EventLogEntryType.Error);
    }

    public void WriteVerbose(string source, string message)
    {
        // Verbose nicht ins EventLog schreiben
    }
}
```

### Eigenen Writer hinzufügen
```powershell
# EventLog-Writer aktivieren
$logger = [psTPCCLASSES.PowerShellLogger]::Instance
$eventWriter = [psTPCCLASSES.EventLogWriter]::new()
$logger.AddWriter($eventWriter)

# Ab jetzt: Console + File (falls aktiviert) + EventLog
```

### Beispiel: Database-Writer
```csharp
public class DatabaseLogWriter : ILogWriter
{
    private readonly string _connectionString;

    public DatabaseLogWriter(string connectionString)
    {
        _connectionString = connectionString;
    }

    public void WriteInfo(string source, string message)
    {
        InsertLog("INFO", source, message);
    }

    private void InsertLog(string level, string source, string message)
    {
        using var connection = new SqlConnection(_connectionString);
        using var command = new SqlCommand(
            "INSERT INTO Logs (Timestamp, Level, Source, Message) VALUES (@ts, @lvl, @src, @msg)",
            connection);

        command.Parameters.AddWithValue("@ts", DateTime.Now);
        command.Parameters.AddWithValue("@lvl", level);
        command.Parameters.AddWithValue("@src", source);
        command.Parameters.AddWithValue("@msg", message);

        connection.Open();
        command.ExecuteNonQuery();
    }

    // ... weitere Methoden ...
}
```

---

## Technische Details

### Thread-Safety
Alle Log-Operationen sind durch Locks geschützt:

```csharp
private readonly object _writersLock = new object();

public void Info(string source, string message)
{
    lock (_writersLock)  // Nur ein Thread zur Zeit
    {
        foreach (var writer in _writers)
        {
            writer.WriteInfo(source, message);
        }
    }
}
```

**Wichtig**: FileLogWriter hat zusätzlich einen eigenen Lock für Datei-Zugriffe.

### ANSI-Farbcodes
```csharp
// ANSI Escape Sequences für Terminal-Farben
\u001b[36m  // Cyan
\u001b[33m  // Gelb
\u001b[31m  // Rot
\u001b[90m  // Grau
\u001b[0m   // Reset (zurück zur Standard-Farbe)

// Beispiel
Console.WriteLine($"\u001b[36m[INFO]\u001b[0m Nachricht");
//                 ^^^^^^^^^ Cyan    ^^^^^^^^ Reset
```

### Fehlerbehandlung
Fehler beim Logging werden bewusst ignoriert, um keine Exceptions in der Anwendung zu verursachen:

```csharp
foreach (var writer in _writers)
{
    try
    {
        writer.WriteInfo(source, message);
    }
    catch
    {
        // Fehler ignorieren - Logging darf nie die App crashen
    }
}
```

### Speicherverwaltung
- Singleton-Instanz lebt für die gesamte Anwendungsdauer
- Writer-Liste ist dynamisch (Add/Remove möglich)
- FileLogWriter öffnet/schließt Datei bei jedem Schreibvorgang (kein dauerhafter File-Handle)

---

## Migration von alter zu neuer Version

### Alte Version (Runspace-basiert)
```csharp
// Konstruktor mit Logger-Parameter
public CounterConfiguration(PowerShellLogger logger, ...)
{
    _logger = logger;  // Logger wurde übergeben
}

// Im PowerShell-Modul
$script:logger = [psTPCCLASSES.PowerShellLogger]::new()
```

### Neue Version (Singleton)
```csharp
// Kein Logger-Parameter mehr im Konstruktor
public CounterConfiguration(...)
{
    // Logger ist static field
}

// Logger als static field in der Klasse
private static readonly PowerShellLogger _logger = PowerShellLogger.Instance;

// Im PowerShell-Modul
$script:logger = [psTPCCLASSES.PowerShellLogger]::Instance
```

**Vorteile der neuen Version:**
- Keine Parameter-Übergabe nötig
- Garantiert eine einzige Logger-Instanz
- Einfachere Konstruktoren
- Funktioniert zuverlässig aus Threads

---

## Best Practices

### 1. Source-Namen konsistent verwenden
```csharp
private readonly string _source = "CounterConfiguration";  // Klassenname

_logger.Info(_source, "Nachricht");  // Immer gleicher Source
```

### 2. File-Logging mit Datum
```powershell
# Täglich neue Log-Datei
$logPath = "C:\Logs\tpc-$(Get-Date -Format 'yyyyMMdd').log"
$logger.EnableFileLogging($logPath)
```

### 3. Verbose-Logging sparsam nutzen
```csharp
// Nur für Debugging, nicht in Produktiv-Code
_logger.Verbose(_source, "Detail-Information");
```

### 4. Fehler mit Kontext loggen
```csharp
catch (Exception ex)
{
    _logger.Error(_source, $"Error reading counter '{Title}': {ex.Message}");
    //                      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Kontext wichtig!
}
```

---

## Zusammenfassung

| Feature | Beschreibung |
|---------|--------------|
| **Pattern** | Singleton + Writer-Pattern |
| **Thread-Safety** | Ja, mit Locks |
| **Standard-Output** | Console (ANSI-Farben) |
| **Optional** | File-Logging |
| **Erweiterbar** | Eigene Writer via ILogWriter |
| **Performance** | Minimal (direkte Console-Ausgabe) |

**Vorteil gegenüber alter Version:**
- Sofortige, zuverlässige Console-Ausgabe
- Funktioniert aus allen Threads
- Keine Runspace-Overhead
- Einfach erweiterbar
