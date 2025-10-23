# Multi-Server Remote Monitoring - Implementierungsanalyse

## Chat-Erkenntnisse und Lösungsansätze

### Ausgangslage
- **Aktuelles Modul**: psTerminalPerfCounter nur für localhost ausgelegt
- **Zentrale Architektur**: PerformanceCounter-Klasse enthält gesamte Counter-Logik
- **Erweiterungsziel**: Remote Server Monitoring mit paralleler Ausführung

### Neue Anforderungen
1. **Runspaces pro Server** - parallele Überwachung mehrerer Server
2. **Remoting Configuration** - JSON-basierte Multi-Server Konfiguration
3. **Conditional Display Logic** - Graph bei einem Server, Tabelle bei mehreren
4. **HTML Export** - JSON Export nach vollständigem Durchlauf
5. **Credential Management** - flexible Authentifizierung (Integrated/Explicit/Vault)

### Architektur-Entscheidung: Klassen-zentrierter Ansatz

**Kernentscheidung**: Alle Remote-Logik in die `PerformanceCounter`-Klasse integrieren
- ✅ Saubere Kapselung der Counter-Logik
- ✅ Transparente API (`GetValue()` funktioniert für local/remote)
- ✅ Runspaces müssen nur Klasseninstanzen verarbeiten
- ✅ Session Management in der Klasse gekapselt

### PerformanceCounter Klassen-Erweiterung

#### Neue Properties
```powershell
[bool]          $IsLocal = $true
[bool]          $IsRemote = $false
[string]        $ComputerName = $env:COMPUTERNAME
[PSCredential]  $Credential        # Von außen übergeben (null oder PSCredential)
[string]        $CredentialName     # Für Vault-Integration
hidden [PSSession] $RemoteSession   # Session Management
hidden [bool]   $SessionEstablished = $false
```

#### Neue Konstruktoren
```powershell
PerformanceCounter([hashtable]$Config, [string]$ComputerName)
PerformanceCounter([hashtable]$Config, [string]$ComputerName, [PSCredential]$Credential)
```

#### Erweiterte Methoden
- `GetValue()` - Transparent für local/remote
- `GetRemoteValue()` - Remote Counter Abfrage via PSSession
- `EstablishRemoteSession()` - Session Management
- `TestConnection()` - Connectivity Check
- `Dispose()` - Session Cleanup

### Parameter-Erweiterung Start-tpcMonitor

#### Neues ParameterSet 'RemoteConfig'
```powershell
[Parameter(ParameterSetName = 'RemoteConfig')]
[string] $RemotingConfig

[Parameter(ParameterSetName = 'RemoteConfig')]
[PSCredential] $Credential

[switch] $Html  # Für JSON Export
```

#### Routing-Logik (Zeile 101 Änderung)
```powershell
# Aktuell:
Get-PerformanceConfig

# Neu:
if ($PSCmdlet.ParameterSetName -eq 'RemoteConfig') {
    $Config = Get-RemotePerformanceConfig -ConfigPath $RemotingConfig -Credential $Credential
} else {
    $Config = Get-PerformanceConfig -ConfigName $ConfigName -ConfigPath $ConfigPath
}
```

### JSON Strukturen

#### Input: structure_MultiServerTemplate.json
```json
{
  "Servers": [
    {
      "Name": "Server01",
      "CredentialName": "Domain\\ServiceAccount"
    }
  ],
  "Counters": [ /* Standard Counter Config */ ],
  "Display": { /* Display Settings */ }
}
```

#### Output: structure_ExportData.json
```json
{
  "Timestamp": "2025-08-05T14:30:00Z",
  "Servers": [
    {
      "Name": "Server01",
      "Counters": [ /* Counter Data */ ],
      "Statistics": { /* Aggregated Stats */ }
    }
  ]
}
```

### Neue Funktionen

#### Get-RemotePerformanceConfig
- Lädt Multi-Server JSON Konfiguration
- Erstellt PerformanceCounter Instanzen pro Server
- Validiert Server-Konnektivität
- **Abhängigkeit**: Erweiterte PerformanceCounter Klasse

#### Start-RemoteMonitoringLoop
- Runspace Pool Management (1 Runspace pro Server)
- Parallele Counter-Abfrage über PerformanceCounter Instanzen
- Daten-Aggregation für Display
- **Abhängigkeit**: Get-RemotePerformanceConfig

#### Show-MultiServerData
- Conditional Rendering basierend auf Server-Anzahl
- Graph: nur bei einem Server möglich
- Tabelle: bei mehreren Servern (Pflicht)
- **Abhängigkeit**: Start-RemoteMonitoringLoop

#### Export-HtmlData
- JSON Export nach structure_ExportData.json Format
- Wird nach kompletten Monitoring-Durchlauf ausgeführt
- Trigger: Ctrl+C oder definierte Laufzeit
- **Abhängigkeit**: Vollständige Datensammlung

### Credential Management Strategie

#### Prioritätenreihenfolge
1. **Explicit Credential** - über -Credential Parameter übergeben
2. **Vault Credential** - über CredentialName aus JSON (später)
3. **Integrated Authentication** - Windows-Authentifikierung

#### Implementierung
- Credential wird **außerhalb der Klasse** erzeugt
- PerformanceCounter Constructor erhält null oder PSCredential Objekt
- Session-Erstellung in `EstablishRemoteSession()` mit Credential-Priorität

### Implementierungsreihenfolge

#### Phase 1: Klassen-Erweiterung (Priorität 1)
- [ ] PerformanceCounter um Remote-Properties erweitern
- [ ] Remote-Konstruktoren implementieren
- [ ] `GetRemoteValue()` Methode mit PSSession-Logik
- [ ] Session Management (`EstablishRemoteSession()`, `Dispose()`)
- [ ] **Testkriterium**: Einzelner Remote-Counter funktioniert

#### Phase 2: Config-Loading (Priorität 2)
- [ ] `Get-RemotePerformanceConfig` Funktion
- [ ] Multi-Server JSON Parsing
- [ ] PerformanceCounter Instanzen-Erstellung pro Server
- [ ] **Testkriterium**: Remote Config wird korrekt in Counter-Objekte konvertiert

#### Phase 3: Parameter Integration (Priorität 3)
- [ ] Start-tpcMonitor um RemoteConfig ParameterSet erweitern
- [ ] Credential Parameter Integration
- [ ] Routing-Logik zwischen local/remote Pfaden
- [ ] **Testkriterium**: Parameter werden korrekt an Config-Functions weitergegeben

#### Phase 4: Runspace Implementation (Priorität 4)
- [ ] `Start-RemoteMonitoringLoop` mit Runspace Pool
- [ ] Parallele Counter-Abfrage über PerformanceCounter Instanzen
- [ ] Daten-Synchronisation und Aggregation
- [ ] **Testkriterium**: Multi-Server Monitoring läuft parallel stabil

#### Phase 5: Display Logic (Priorität 5)
- [ ] `Show-MultiServerData` mit Conditional Rendering
- [ ] Single Server: Graph-Display verfügbar
- [ ] Multiple Server: Table-Display (Pflicht)
- [ ] **Testkriterium**: Display passt sich Server-Anzahl an

#### Phase 6: HTML Export (Priorität 6)
- [ ] `Export-HtmlData` nach structure_ExportData.json
- [ ] Integration in Monitoring Loop
- [ ] Export-Trigger nach Monitoring-Ende
- [ ] **Testkriterium**: JSON Export entspricht Struktur-Vorgabe

### Technische Herausforderungen

#### Session Management
- **Problem**: Wann Remote-Sessions öffnen/schließen?
- **Lösung**: Sessions im Constructor öffnen, via `Dispose()` schließen
- **Cleanup**: Try/Finally Block in Start-tpcMonitor für Dispose-Aufrufe

#### Performance Considerations
- **Challenge**: Viele Remote-Sessions belasten Netzwerk/Memory
- **Mitigation**:
  - Connection Pooling in PerformanceCounter
  - Session Reuse wo möglich
  - Runspace Pool Limits

#### Error Handling
- **Scenario**: Remote-Server nicht erreichbar
- **Strategy**:
  - Connection Tests via `TestConnection()`
  - Graceful Degradation (Server überspringen)
  - Error-Logging ohne Monitoring-Abbruch

#### Display Conditional Logic
- **Rule**: `$Config.Servers.Count -eq 1` → Graph möglich
- **Rule**: `$Config.Servers.Count -gt 1` → nur Table
- **Implementation**: Check in `Show-MultiServerData`

### Abhängigkeitskette

```
PerformanceCounter (erweitert)
    ↓
Get-RemotePerformanceConfig
    ↓
Start-tpcMonitor (Parameter erweitert)
    ↓
Start-RemoteMonitoringLoop
    ↓
Show-MultiServerData + Export-HtmlData
```

### Offene Fragen für weitere Iteration

1. **Vault Integration**: Wann Secret-Manager anbinden?
2. **Session Limits**: Wie viele gleichzeitige Remote-Sessions sind sinnvoll?
3. **Update Intervals**: Unterschiedliche Intervalle pro Server unterstützen?
4. **Auto-Reconnect**: Automatische Session-Wiederherstellung bei Verbindungsabbruch?
5. **Memory Management**: Daten-Retention bei Long-Running Multi-Server Monitoring?

### Nächste Schritte

1. **Phase 1 starten**: PerformanceCounter Klasse um Remote-Eigenschaften erweitern
2. **Prototyping**: Einfacher Remote-Counter Test für Machbarkeitsnachweis
3. **JSON Analysis**: structure_MultiServerTemplate.json und structure_ExportData.json detailliert analysieren
4. **Testing Strategy**: Unit Tests für Remote-Methoden definieren

### Architektur-Vorteile der gewählten Lösung

- **Minimale Disruption**: Bestehende lokale Funktionalität bleibt unverändert
- **Klare Separation**: ParameterSets trennen lokale und Remote-Ausführungspfade
- **Skalierbarkeit**: Runspace-basierte Architektur skaliert mit Server-Anzahl
- **Testbarkeit**: Klassen können isoliert getestet werden
- **Erweiterbarkeit**: Vault-Integration und weitere Features einfach