<#
ERWEITERTE VERSION: Klassen aus externen Dateien in Runspaces laden

Dieses Skript zeigt verschiedene Ansätze zum Laden von Klassen aus externen Dateien:
1. Get-Content -Raw (einfachster Ansatz)
2. Using module (für PowerShell-Module)
3. Mehrere Klassendateien laden
4. Fehlerbehandlung und Validierung
#>

# === GLOBALE DATENSTRUKTUREN FÜR THREAD-SICHERE KOMMUNIKATION ===
$global:SessionStore = [hashtable]::Synchronized(@{})
$global:CommandQueues = [hashtable]::Synchronized(@{})
$global:ResultStore = [hashtable]::Synchronized(@{})

# === KLASSEN AUS EXTERNEN DATEIEN LADEN ===
function Get-ClassDefinitionsFromFiles {
    param(
        [string[]]$ClassFiles = @("klasse.ps1"),
        [string]$BasePath = $PSScriptRoot
    )

    $allClassDefinitions = @()

    foreach ($classFile in $ClassFiles) {
        $classFilePath = Join-Path $BasePath $classFile

        Write-Host "Lade Klassendatei: $classFilePath" -ForegroundColor Cyan

        if (-not (Test-Path $classFilePath)) {
            throw "Klassendatei nicht gefunden: $classFilePath"
        }

        # Validierung: Prüfen ob es wirklich eine Klassendefinition enthält
        $content = Get-Content $classFilePath -Raw
        if ($content -notmatch 'class\s+\w+') {
            Write-Warning "Datei $classFile scheint keine Klassendefinition zu enthalten"
        }

        $allClassDefinitions += $content
        Write-Host "✓ Geladen: $classFile" -ForegroundColor Green
    }

    # Alle Klassendefinitionen zu einem String kombinieren
    return ($allClassDefinitions -join "`n`n")
}

# === ALTERNATIVE: MODULE-BASIERTER ANSATZ ===
function Get-ClassDefinitionFromModule {
    param(
        [string]$ModulePath,
        [string]$ClassName
    )

    # Für komplexere Szenarien mit PowerShell-Modulen
    if (Test-Path $ModulePath) {
        $moduleContent = Get-Content $ModulePath -Raw
        return $moduleContent
    }

    throw "Modul nicht gefunden: $ModulePath"
}

# === KLASSEN LADEN ===
try {
    # Einzelne Datei laden
    $classDefinition = Get-ClassDefinitionsFromFiles -ClassFiles @("klasse.ps1")

    # Alternativ: Mehrere Klassendateien gleichzeitig laden
    # $classDefinition = Get-ClassDefinitionsFromFiles -ClassFiles @("klasse.ps1", "andereklasse.ps1")

    Write-Host "Klassendefinitionen erfolgreich geladen!" -ForegroundColor Green
}
catch {
    Write-Error "Fehler beim Laden der Klassendefinitionen: $($_.Exception.Message)"
    exit 1
}

# === RUNSPACE POOL ERSTELLEN ===
$runspacePool = [runspacefactory]::CreateRunspacePool(1, 10)
$runspacePool.Open()

# === ERWEITERTE PERSISTENTE SESSION MIT DATEI-BASIERTEN KLASSEN ===
function New-PersistentSessionFromFile {
    param(
        $SessionId,
        $Name,
        $Alter,
        [string]$ClassDefinitions,
        [string[]]$AdditionalModules = @()
    )

    $global:CommandQueues[$SessionId] = [System.Collections.ArrayList]::Synchronized([System.Collections.ArrayList]::new())
    $global:ResultStore[$SessionId] = [hashtable]::Synchronized(@{})

    $powershell = [powershell]::Create()
    $powershell.RunspacePool = $runspacePool

    $scriptBlock = {
        param($sessionId, $name, $alter, $commandQueues, $resultStore, $sessionStore, $classCode, $additionalModules)

        try {
            # === ZUSÄTZLICHE MODULE LADEN (OPTIONAL) ===
            foreach ($module in $additionalModules) {
                if ($module -and (Test-Path $module)) {
                    Write-Host "Lade zusätzliches Modul: $module" -ForegroundColor Blue
                    Import-Module $module -Force
                }
            }

            # === KLASSENDEFINITIONEN AUSFÜHREN ===
            Write-Host "Lade Klassendefinitionen in Runspace $sessionId..." -ForegroundColor Yellow
            Invoke-Expression $classCode
            Write-Host "✓ Klassendefinitionen geladen in Runspace $sessionId" -ForegroundColor Green

            # === KLASSENINSTANZ ERSTELLEN ===
            $instance = [klasse]::new($name, $alter)
            Write-Host "✓ Klasseninstanz '$name' erstellt in Runspace $sessionId" -ForegroundColor Green

            # Session-Metadaten registrieren
            $sessionStore[$sessionId] = @{
                Status = 'Active'
                ThreadId = [System.Threading.Thread]::CurrentThread.ManagedThreadId
                StartTime = Get-Date
                ClassName = 'klasse'
                InstanceName = $name
            }

            Write-Host "Session $sessionId bereit (ThreadID: $([System.Threading.Thread]::CurrentThread.ManagedThreadId))" -ForegroundColor Cyan

            # === VERARBEITUNGSSCHLEIFE ===
            while ($sessionStore[$sessionId].Status -eq 'Active') {
                $command = $null
                $queue = $commandQueues[$sessionId]

                if ($queue.Count -gt 0) {
                    $command = $queue[0]
                    $queue.RemoveAt(0)

                    Write-Host "Verarbeite '$($command.Method)' in Session $sessionId" -ForegroundColor Yellow

                    try {
                        $result = switch ($command.Method) {
                            'Vorstellung' {
                                $instance.Vorstellung()
                            }
                            'ModifyName' {
                                $instance.Name = "$($instance.Name)_modified_$(Get-Date -Format 'HHmmss')"
                                $instance.Name
                            }
                            'GetName' {
                                $instance.Name
                            }
                            'SetName' {
                                $instance.Name = $command.Value
                                'OK'
                            }
                            'GetInfo' {
                                @{
                                    Name = $instance.Name
                                    Alter = $instance.Alter
                                    ThreadId = [System.Threading.Thread]::CurrentThread.ManagedThreadId
                                    SessionId = $sessionId
                                    LoadedFromFile = $true
                                }
                            }
                            'TestClassLoading' {
                                # Test ob die Klasse korrekt geladen wurde
                                @{
                                    ClassExists = ($instance -is [klasse])
                                    InstanceType = $instance.GetType().Name
                                    Methods = ($instance | Get-Member -MemberType Method | Select-Object -ExpandProperty Name)
                                }
                            }
                            default {
                                "Unbekannte Methode: $($command.Method)"
                            }
                        }

                        $resultStore[$sessionId][$command.Id] = @{
                            Success = $true
                            Result = $result
                            Timestamp = Get-Date
                        }
                    }
                    catch {
                        $resultStore[$sessionId][$command.Id] = @{
                            Success = $false
                            Error = $_.Exception.Message
                            Timestamp = Get-Date
                        }
                    }
                }

                Start-Sleep -Milliseconds 50
            }

        }
        catch {
            Write-Error "Fehler in Session $sessionId`: $($_.Exception.Message)"
            if ($sessionStore.ContainsKey($sessionId)) {
                $sessionStore[$sessionId].Status = 'Error'
                $sessionStore[$sessionId].Error = $_.Exception.Message
            }
        }
        finally {
            Write-Host "Session $sessionId wird beendet" -ForegroundColor Magenta
            if ($sessionStore.ContainsKey($sessionId)) {
                $sessionStore.Remove($sessionId)
            }
        }
    }

    # Runspace mit Klassendefinitionen starten
    $powershell.AddScript($scriptBlock).AddArgument($SessionId).AddArgument($Name).AddArgument($Alter).AddArgument($global:CommandQueues).AddArgument($global:ResultStore).AddArgument($global:SessionStore).AddArgument($ClassDefinitions).AddArgument($AdditionalModules) | Out-Null

    $handle = $powershell.BeginInvoke()
    Start-Sleep -Milliseconds 200  # Etwas mehr Zeit für das Laden

    return @{
        PowerShell = $powershell
        Handle = $handle
        SessionId = $SessionId
    }
}

# === INVOKE-SESSIONMETHOD FUNKTION (UNVERÄNDERT) ===
function Invoke-SessionMethod {
    param($SessionId, $Method, $Value = $null, $Timeout = 5000)

    if (-not $global:CommandQueues.ContainsKey($SessionId)) {
        throw "Session $SessionId nicht gefunden"
    }

    $commandId = [guid]::NewGuid().ToString()
    $command = @{
        Id = $commandId
        Method = $Method
        Value = $Value
        Timestamp = Get-Date
    }

    $null = $global:CommandQueues[$SessionId].Add($command)

    $start = Get-Date
    while (-not $global:ResultStore[$SessionId].ContainsKey($commandId)) {
        if ((Get-Date) - $start -gt [timespan]::FromMilliseconds($Timeout)) {
            throw "Timeout beim Warten auf Ergebnis von Session $SessionId"
        }
        Start-Sleep -Milliseconds 10
    }

    $result = $global:ResultStore[$SessionId][$commandId]
    $global:ResultStore[$SessionId].Remove($commandId)

    if (-not $result.Success) {
        throw "Methodenausführung fehlgeschlagen: $($result.Error)"
    }

    return $result.Result
}

# === HAUPTPROGRAMM MIT DATEI-BASIERTEN KLASSEN ===
Write-Host "=== Erstelle Sessions mit datei-basierten Klassen ===" -ForegroundColor White

$sessions = @()
$instanceData = @(
    @{ Name = "Max"; Alter = 30 }
    @{ Name = "Anna"; Alter = 25 }
    @{ Name = "Peter"; Alter = 40 }
)

# Sessions erstellen
foreach ($data in $instanceData) {
    $sessionId = $data.Name.ToLower()

    # Session mit datei-basierten Klassendefinitionen erstellen
    $session = New-PersistentSessionFromFile -SessionId $sessionId -Name $data.Name -Alter $data.Alter -ClassDefinitions $classDefinition
    $sessions += $session

    Write-Host "✓ Session erstellt: $sessionId (aus Datei geladen)" -ForegroundColor Green
}

Write-Host "`n=== Teste Klassen-Ladung ===" -ForegroundColor White

# Test ob die Klassen korrekt geladen wurden
foreach ($data in $instanceData) {
    $sessionId = $data.Name.ToLower()

    try {
        $testResult = Invoke-SessionMethod -SessionId $sessionId -Method 'TestClassLoading'
        Write-Host "$sessionId - Klasse geladen: $($testResult.ClassExists), Typ: $($testResult.InstanceType)" -ForegroundColor Cyan
    }
    catch {
        Write-Host "$sessionId - Fehler beim Klassentest: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n=== Teste Methoden ===" -ForegroundColor White

# Test der Klassenmethoden
foreach ($data in $instanceData) {
    $sessionId = $data.Name.ToLower()

    try {
        # Namen modifizieren
        $newName = Invoke-SessionMethod -SessionId $sessionId -Method 'ModifyName'
        Write-Host "$sessionId - Neuer Name: $newName" -ForegroundColor Yellow

        # Info abrufen
        $info = Invoke-SessionMethod -SessionId $sessionId -Method 'GetInfo'
        Write-Host "$sessionId - Info: Name=$($info.Name), Alter=$($info.Alter), LoadedFromFile=$($info.LoadedFromFile)" -ForegroundColor Green
    }
    catch {
        Write-Host "$sessionId - Fehler: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n=== Aufräumen ===" -ForegroundColor White

# Cleanup
foreach ($session in $sessions) {
    if ($global:SessionStore.ContainsKey($session.SessionId)) {
        $global:SessionStore[$session.SessionId].Status = 'Closing'
    }

    $timeout = 3000
    $start = Get-Date
    while ($global:SessionStore.ContainsKey($session.SessionId)) {
        if ((Get-Date) - $start -gt [timespan]::FromMilliseconds($timeout)) {
            Write-Warning "Timeout beim Schließen von Session $($session.SessionId)"
            break
        }
        Start-Sleep -Milliseconds 50
    }

    $global:CommandQueues.Remove($session.SessionId)
    $global:ResultStore.Remove($session.SessionId)
    $session.PowerShell.Dispose()

    Write-Host "✓ Session geschlossen: $($session.SessionId)" -ForegroundColor Red
}

$runspacePool.Close()
$runspacePool.Dispose()

Write-Host "`n=== Fertig - Klassen erfolgreich aus Datei geladen! ===" -ForegroundColor White
