
<#
Was passiert hier? - Das Runspace-Management-System
1. Das Grundkonzept
Dieses Skript implementiert ein persistentes Runspace-System, das folgende Hauptkomponenten hat:

Persistente Sessions: Langlebige PowerShell-Runspaces, die kontinuierlich im Hintergrund laufen
Thread-sichere Kommunikation: Über synchronisierte Hashtables und ArrayLists
Command-Queue-Pattern: Befehle werden in Warteschlangen eingereiht und abgearbeitet
Parallele Ausführung: Mehrere Sessions können gleichzeitig arbeiten
2. Die Architektur

Hauptthread    ↓RunspacePool (1-10 Runspaces)    ↓Persistente Sessions (Max, Anna, Peter)    ↓Klasseninstanzen (jeweils eine pro Session)    ↓Command-Queue-System (Befehlsverarbeitung)
3. Der Kommunikationsfluss
Befehl senden: Invoke-SessionMethod → Befehl in Queue einreihen
Befehl verarbeiten: Session-Loop → Befehl aus Queue nehmen → Ausführen
Ergebnis zurück: Ergebnis in ResultStore → Hauptthread abrufen
4. Warum ist das nützlich?
Stateful Operations: Klasseninstanzen bleiben zwischen Aufrufen erhalten
Parallelität: Mehrere zeitaufwändige Operationen gleichzeitig
Isolation: Jede Session läuft in eigenem Thread/Kontext
Skalierbarkeit: Beliebig viele Sessions möglich
5. Anwendungsbeispiele für Ihr Problem
Sie können dieses Pattern für folgende Szenarien adaptieren:

Remote-Verbindungen: Persistente Sessions zu verschiedenen Servern
Datenbank-Connections: Langlebige DB-Verbindungen pro Thread
API-Clients: Wiederverwendbare HTTP-Clients mit Session-State
Datei-Verarbeitung: Parallele Verarbeitung großer Dateisätze
Monitoring: Kontinuierliche Überwachung verschiedener Ressourcen
Das System zeigt, wie man zustandsbehaftete, parallele Operationen in PowerShell elegant implementiert!
#>

# === GLOBALE DATENSTRUKTUREN FÜR THREAD-SICHERE KOMMUNIKATION ===
# Diese drei Hashtables sind thread-sicher und ermöglichen Kommunikation zwischen verschiedenen Runspaces
$global:SessionStore = [hashtable]::Synchronized(@{})      # Speichert Status und Metadaten aller aktiven Sessions
$global:CommandQueues = [hashtable]::Synchronized(@{})     # Warteschlangen für Befehle, die an Sessions gesendet werden
$global:ResultStore = [hashtable]::Synchronized(@{})       # Speichert Ergebnisse von ausgeführten Befehlen

# === KLASSEN-DEFINITION AUS EXTERNER DATEI LADEN ===
# Die Klasse wird aus einer externen .ps1 Datei geladen
# Dies ermöglicht bessere Code-Organisation und Wiederverwendbarkeit

# Pfad zur Klassendatei (relativ zum aktuellen Skript)
$classFilePath = Join-Path $PSScriptRoot "klasse.ps1"

# Prüfen ob die Datei existiert
if (-not (Test-Path $classFilePath)) {
    throw "Klassendatei nicht gefunden: $classFilePath"
}

# Klassendefinition aus Datei einlesen
$classDefinition = Get-Content $classFilePath -Raw

Write-Host "Klassendefinition geladen aus: $classFilePath" -ForegroundColor Green

# === RUNSPACE POOL ERSTELLEN ===
# Ein RunspacePool verwaltet eine Sammlung von Runspaces für parallele Ausführung
# Parameter: Minimum 1, Maximum 10 gleichzeitige Runspaces
$runspacePool = [runspacefactory]::CreateRunspacePool(1, 10)
$runspacePool.Open()  # Pool muss geöffnet werden, bevor er verwendet werden kann

# === FUNKTION: PERSISTENTE SESSION ERSTELLEN ===
# Diese Funktion erstellt eine dauerhafte Session, die kontinuierlich auf Befehle wartet
function New-PersistentSession {
    param($SessionId, $Name, $Alter)

    # Für jede Session wird eine eigene Befehlswarteschlange und ein Ergebnisspeicher erstellt
    # ArrayList::Synchronized macht die Liste thread-sicher für den Zugriff aus mehreren Threads
    $global:CommandQueues[$SessionId] = [System.Collections.ArrayList]::Synchronized([System.Collections.ArrayList]::new())
    $global:ResultStore[$SessionId] = [hashtable]::Synchronized(@{})

    # Neues PowerShell-Objekt erstellen und dem RunspacePool zuweisen
    $powershell = [powershell]::Create()
    $powershell.RunspacePool = $runspacePool

    # === SCRIPT BLOCK: DER CODE, DER IM RUNSPACE AUSGEFÜHRT WIRD ===
    # Dieser Code läuft persistent in einem separaten Thread/Runspace
    $scriptBlock = {
        param($sessionId, $name, $alter, $commandQueues, $resultStore, $sessionStore, $classCode)

        # === RUNSPACE INITIALISIERUNG ===
        # Klassendefinition in diesem Runspace verfügbar machen
        # Invoke-Expression führt den String als PowerShell-Code aus
        Invoke-Expression $classCode

        # Klasseninstanz INNERHALB des Runspace erstellen
        # Diese Instanz existiert nur in diesem spezifischen Thread/Runspace
        $instance = [klasse]::new($name, $alter)

        # Session-Metadaten im globalen SessionStore registrieren
        $sessionStore[$sessionId] = @{
            Status = 'Active'  # Session ist aktiv und bereit für Befehle
            ThreadId = [System.Threading.Thread]::CurrentThread.ManagedThreadId  # Für Debugging
            StartTime = Get-Date  # Startzeitpunkt der Session
        }

        Write-Host "Session $sessionId started with instance '$name' on ThreadID: $([System.Threading.Thread]::CurrentThread.ManagedThreadId)" -ForegroundColor Cyan

        # === HAUPT-VERARBEITUNGSSCHLEIFE ===
        # Diese Schleife hält den Runspace am Leben und verarbeitet eingehende Befehle
        while ($sessionStore[$sessionId].Status -eq 'Active') {
            $command = $null

            # Überprüfung auf neue Befehle in der Warteschlange
            $queue = $commandQueues[$sessionId]
            if ($queue.Count -gt 0) {
                # Ersten Befehl aus der Warteschlange nehmen (FIFO - First In, First Out)
                $command = $queue[0]
                $queue.RemoveAt(0)

                Write-Host "Processing command '$($command.Method)' for session $sessionId" -ForegroundColor Yellow

                try {
                    # === BEFEHL AUSFÜHRUNG ===
                    # Switch-Statement verarbeitet verschiedene Methodenaufrufe
                    $result = switch ($command.Method) {
                        'Vorstellung' {
                            # Ruft die Vorstellung-Methode der Klasseninstanz auf
                            $instance.Vorstellung()
                        }
                        'ModifyName' {
                            # Ändert den Namen und fügt Thread-Info hinzu
                            $instance.Name = "$($instance.Name)_modified - ThreadID: $([System.Threading.Thread]::CurrentThread.ManagedThreadId)"
                            $instance.Name  # Rückgabe des neuen Namens
                        }
                        'GetName' {
                            # Gibt den aktuellen Namen zurück
                            $instance.Name
                        }
                        'SetName' {
                            # Setzt einen neuen Namen (aus dem Befehl)
                            $instance.Name = $command.Value
                            'OK'  # Bestätigung
                        }
                        'GetInfo' {
                            # Gibt ein Objekt mit allen Informationen zurück
                            @{
                                Name = $instance.Name
                                Alter = $instance.Alter
                                ThreadId = [System.Threading.Thread]::CurrentThread.ManagedThreadId
                            }
                        }
                        default {
                            "Unknown method: $($command.Method)"
                        }
                    }

                    # === ERFOLGREICHE ERGEBNIS-SPEICHERUNG ===
                    $resultStore[$sessionId][$command.Id] = @{
                        Success = $true
                        Result = $result
                        Timestamp = Get-Date
                    }
                }
                catch {
                    # === FEHLER-BEHANDLUNG ===
                    # Bei Fehlern wird eine Fehlermeldung gespeichert
                    $resultStore[$sessionId][$command.Id] = @{
                        Success = $false
                        Error = $_.Exception.Message
                        Timestamp = Get-Date
                    }
                }
            }

            # Kurze Pause, um CPU-Last zu reduzieren (verhindert "Busy Waiting")
            Start-Sleep -Milliseconds 50
        }

        # === SESSION CLEANUP ===
        Write-Host "Session $sessionId shutting down" -ForegroundColor Magenta
        $sessionStore.Remove($sessionId)  # Session aus dem globalen Store entfernen
    }

    # === RUNSPACE STARTEN ===
    # Alle Parameter für den ScriptBlock hinzufügen
    $powershell.AddScript($scriptBlock).AddArgument($SessionId).AddArgument($Name).AddArgument($Alter).AddArgument($global:CommandQueues).AddArgument($global:ResultStore).AddArgument($global:SessionStore).AddArgument($classDefinition) | Out-Null

    # Asynchrone Ausführung starten (non-blocking)
    # Der Runspace läuft ab jetzt parallel im Hintergrund
    $handle = $powershell.BeginInvoke()

    # Kurz warten, damit sich die Session initialisieren kann
    Start-Sleep -Milliseconds 100

    # Objekt mit Referenzen zurückgeben für spätere Verwaltung
    return @{
        PowerShell = $powershell  # PowerShell-Instanz
        Handle = $handle          # Handle für Async-Überwachung
        SessionId = $SessionId    # ID der Session
    }
}

# === FUNKTION: METHODE IN RUNSPACE AUSFÜHREN ===
# Diese Funktion ermöglicht es, Befehle an eine laufende Session zu senden
function Invoke-SessionMethod {
    param($SessionId, $Method, $Value = $null, $Timeout = 5000)

    # Prüfen, ob die Session existiert
    if (-not $global:CommandQueues.ContainsKey($SessionId)) {
        throw "Session $SessionId not found"
    }

    # Eindeutige ID für diesen Befehl generieren
    $commandId = [guid]::NewGuid().ToString()

    # Befehl-Objekt erstellen
    $command = @{
        Id = $commandId           # Eindeutige ID
        Method = $Method          # Methodenname
        Value = $Value           # Optionaler Wert (z.B. für SetName)
        Timestamp = Get-Date     # Zeitstempel
    }

    # Befehl in die Warteschlange der Session einreihen
    # Das wird von der Session-Schleife abgearbeitet
    $null = $global:CommandQueues[$SessionId].Add($command)

    # === WARTEN AUF ERGEBNIS ===
    # Polling-Schleife: Warten bis das Ergebnis verfügbar ist
    $start = Get-Date
    while (-not $global:ResultStore[$SessionId].ContainsKey($commandId)) {
        # Timeout-Prüfung
        if ((Get-Date) - $start -gt [timespan]::FromMilliseconds($Timeout)) {
            throw "Timeout waiting for method result from session $SessionId"
        }
        Start-Sleep -Milliseconds 10  # Kurze Pause zwischen Prüfungen
    }

    # === ERGEBNIS ABRUFEN UND CLEANUP ===
    $result = $global:ResultStore[$SessionId][$commandId]
    $global:ResultStore[$SessionId].Remove($commandId)  # Aufräumen

    # Fehlerbehandlung
    if (-not $result.Success) {
        throw "Method execution failed: $($result.Error)"
    }

    return $result.Result
}

# === FUNKTION: SESSION SCHLIESSEN ===
# Beendet eine Session ordnungsgemäß
function Close-PersistentSession {
    param($SessionId)

    if ($global:SessionStore.ContainsKey($SessionId)) {
        # Status auf 'Closing' setzen - das stoppt die Verarbeitungsschleife im Runspace
        $global:SessionStore[$SessionId].Status = 'Closing'

        # === GRACEFUL SHUTDOWN ===
        # Warten, bis die Session sich selbst beendet hat
        $timeout = 5000
        $start = Get-Date
        while ($global:SessionStore.ContainsKey($SessionId)) {
            if ((Get-Date) - $start -gt [timespan]::FromMilliseconds($timeout)) {
                Write-Warning "Timeout waiting for session $SessionId to close"
                break
            }
            Start-Sleep -Milliseconds 50
        }
    }

    # === CLEANUP ===
    # Alle Datenstrukturen für diese Session aufräumen
    $global:CommandQueues.Remove($SessionId)
    $global:ResultStore.Remove($SessionId)
}

# ===================================================================
# === HAUPTPROGRAMM: DEMONSTRATION DES RUNSPACE-SYSTEMS ===
# ===================================================================

Write-Host "=== Creating Persistent Sessions ===" -ForegroundColor White
$sessions = @()  # Array zum Speichern aller Session-Referenzen

# === TESTDATEN ===
# Drei verschiedene Personen für die Demonstration
$instanceData = @(
    @{ Name = "Max"; Alter = 30 }
    @{ Name = "Anna"; Alter = 25 }
    @{ Name = "Peter"; Alter = 40 }
)

# === SESSIONS ERSTELLEN ===
# Für jede Person wird eine eigene persistente Session erstellt
foreach ($data in $instanceData) {
    $sessionId = $data.Name.ToLower()  # Session-ID = Kleinbuchstaben des Namens

    # Session erstellen - diese läuft ab jetzt parallel im Hintergrund
    $session = New-PersistentSession -SessionId $sessionId -Name $data.Name -Alter $data.Alter
    $sessions += $session  # Session zur Verwaltungsliste hinzufügen

    Write-Host "Created session: $sessionId" -ForegroundColor Green
}

Write-Host "`n=== Sessions Active ===" -ForegroundColor White
Start-Sleep 1  # Kurze Pause, damit alle Sessions vollständig initialisiert sind

Write-Host "`n=== Executing Methods in Parallel ===" -ForegroundColor White

# === PARALLELE AUSFÜHRUNG DEMONSTRIEREN ===
# Hier wird gezeigt, wie mehrere Operationen gleichzeitig in verschiedenen Sessions ausgeführt werden
Write-Host "Executing ModifyName and Vorstellung in parallel..." -ForegroundColor Yellow

$parallelJobs = @()  # Array für parallele Job-Überwachung

# === FÜR JEDE SESSION EINEN PARALLELEN JOB STARTEN ===
foreach ($data in $instanceData) {
    $sessionId = $data.Name.ToLower()

    # Neues PowerShell-Objekt für parallele Ausführung erstellen
    # Dies ist UNTERSCHIEDLICH zu den persistenten Sessions - dies ist nur für die Koordination
    $ps = [powershell]::Create()
    $ps.RunspacePool = $runspacePool

    # === SCRIPT BLOCK FÜR PARALLELE KOORDINATION ===
    # Dieser Code läuft parallel und koordiniert die Befehle an die persistenten Sessions
    $scriptBlock = {
        param($sessionId, $commandQueues, $resultStore)

        # === LOKALE KOPIE DER INVOKE-SESSIONMETHOD FUNKTION ===
        # Da dieser Code in einem separaten Runspace läuft, muss die Funktion hier verfügbar sein
        function Invoke-SessionMethod {
            param($SessionId, $Method, $Value = $null, $Timeout = 5000, $CommandQueues, $ResultStore)

            $commandId = [guid]::NewGuid().ToString()
            $command = @{
                Id = $commandId
                Method = $Method
                Value = $Value
                Timestamp = Get-Date
            }

            # Befehl zur Warteschlange hinzufügen
            $null = $CommandQueues[$SessionId].Add($command)

            # Auf Ergebnis warten
            $start = Get-Date
            while (-not $ResultStore[$SessionId].ContainsKey($commandId)) {
                if ((Get-Date) - $start -gt [timespan]::FromMilliseconds($Timeout)) {
                    throw "Timeout waiting for method result from session $SessionId"
                }
                Start-Sleep -Milliseconds 10
            }

            $result = $ResultStore[$SessionId][$commandId]
            $ResultStore[$SessionId].Remove($commandId)

            if (-not $result.Success) {
                throw "Method execution failed: $($result.Error)"
            }

            return $result.Result
        }

        try {
            # === SEQUENZIELLE AUSFÜHRUNG INNERHALB DIESES PARALLELEN JOBS ===
            Write-Host "Starting parallel execution for session $sessionId" -ForegroundColor Cyan

            # Ersten Befehl ausführen: Name modifizieren
            $modifiedName = Invoke-SessionMethod -SessionId $sessionId -Method 'ModifyName' -CommandQueues $commandQueues -ResultStore $resultStore
            Write-Host "ModifyName completed for $sessionId`: $modifiedName" -ForegroundColor Yellow

            # Zweiten Befehl ausführen: Vorstellung (zeitaufwändig)
            $vorstellungResult = Invoke-SessionMethod -SessionId $sessionId -Method 'Vorstellung' -CommandQueues $commandQueues -ResultStore $resultStore
            Write-Host "Vorstellung completed for $sessionId with result: $vorstellungResult" -ForegroundColor Green

            # Erfolgsergebnis zurückgeben
            return @{
                SessionId = $sessionId
                ModifiedName = $modifiedName
                VorstellungResult = $vorstellungResult
                Success = $true
            }
        }
        catch {
            # Fehlerbehandlung
            Write-Host "Error in parallel execution for $sessionId`: $($_.Exception.Message)" -ForegroundColor Red
            return @{
                SessionId = $sessionId
                Error = $_.Exception.Message
                Success = $false
            }
        }
    }

    # === JOB STARTEN ===
    # Script und Parameter hinzufügen, dann asynchron starten
    $ps.AddScript($scriptBlock).AddArgument($sessionId).AddArgument($global:CommandQueues).AddArgument($global:ResultStore) | Out-Null
    $handle = $ps.BeginInvoke()  # Asynchroner Start

    # Job-Referenz für späteren Abruf speichern
    $parallelJobs += @{
        PowerShell = $ps
        Handle = $handle
        SessionId = $sessionId
    }
}

# === WARTEN AUF ALLE PARALLELEN JOBS ===
# Hier wird auf die Completion aller parallelen Koordinationsjobs gewartet
Write-Host "Waiting for all parallel executions to complete..." -ForegroundColor Yellow
foreach ($job in $parallelJobs) {
    # Polling: Warten bis Job fertig ist
    while (-not $job.Handle.IsCompleted) {
        Start-Sleep -Milliseconds 100
    }

    try {
        # Ergebnis des parallelen Jobs abrufen
        $result = $job.PowerShell.EndInvoke($job.Handle)
        if ($result.Success) {
            Write-Host "Parallel job completed - Session: $($result.SessionId), VorstellungResult: $($result.VorstellungResult)" -ForegroundColor Green
        } else {
            Write-Host "Parallel job failed - Session: $($result.SessionId), Error: $($result.Error)" -ForegroundColor Red
        }
    }
    catch {
        Write-Host "Error retrieving result for session $($job.SessionId): $($_.Exception.Message)" -ForegroundColor Red
    }
    finally {
        # PowerShell-Objekt aufräumen
        $job.PowerShell.Dispose()
    }
}

Write-Host "`n=== Getting Final Results ===" -ForegroundColor White

# === FINALER ZUSTAND ALLER SESSIONS ===
# Nach den parallelen Operationen den aktuellen Zustand jeder Session abfragen
foreach ($data in $instanceData) {
    $sessionId = $data.Name.ToLower()

    # GetInfo-Methode aufrufen, um den aktuellen Zustand der Klasseninstanz zu erhalten
    $info = Invoke-SessionMethod -SessionId $sessionId -Method 'GetInfo'
    Write-Host "$sessionId`: $($info.Name) (ThreadID: $($info.ThreadId))" -ForegroundColor White
}

Write-Host "`n=== Cleaning Up ===" -ForegroundColor White

# === ALLE SESSIONS ORDNUNGSGEMÄSS BEENDEN ===
foreach ($session in $sessions) {
    # Session schließen (setzt Status auf 'Closing', wartet auf graceful shutdown)
    Close-PersistentSession -SessionId $session.SessionId

    # PowerShell-Objekt der Session aufräumen
    $session.PowerShell.Dispose()

    Write-Host "Closed session: $($session.SessionId)" -ForegroundColor Red
}

# === RUNSPACE POOL AUFRÄUMEN ===
$runspacePool.Close()    # Pool schließen
$runspacePool.Dispose()  # Ressourcen freigeben

Write-Host "`n=== Done ===" -ForegroundColor White