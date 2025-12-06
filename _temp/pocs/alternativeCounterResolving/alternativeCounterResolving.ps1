function Get-PerfCounterMapFromRegistry {
    param (
        [string]$ComputerName = $env:COMPUTERNAME
    )

    $regKey = $null
    $subKey = $null

    try {
        # Unterscheidung: Lokal vs. Remote
        if ($ComputerName -in $env:COMPUTERNAME, "localhost", ".", "127.0.0.1") {
            # LOKAL: Direkter Zugriff (benötigt keinen Remote-Dienst)
            $regKey = [Microsoft.Win32.Registry]::LocalMachine
        }
        else {
            # REMOTE: Zugriff über Netzwerk (Benötigt Dienst 'RemoteRegistry' auf dem Ziel!)
            $regKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey(
                [Microsoft.Win32.RegistryHive]::LocalMachine,
                $ComputerName
            )
        }

        # Perflib\CurrentLanguage verweist automatisch auf die korrekte ID (z.B. 007 für DE, 009 für EN)
        $subKey = $regKey.OpenSubKey("SOFTWARE\Microsoft\Windows NT\CurrentVersion\Perflib\CurrentLanguage")

        if (-not $subKey) {
            Write-Warning "Konnte Perflib Key auf '$ComputerName' nicht finden/öffnen."
            return $null
        }

        # Den riesigen 'Counter' Multi-String auslesen
        [string[]]$rawCounterData = $subKey.GetValue("Counter")

        if (-not $rawCounterData) {
            Write-Warning "Keine Counter-Daten im Registry-Pfad gefunden."
            return $null
        }

        # Hashtable erstellen
        $counterMap = @{}

        # Format ist: Index 0 = ID, Index 1 = Name, Index 2 = ID, Index 3 = Name ...
        for ($i = 0; $i -lt ($rawCounterData.Count - 1); $i += 2) {
            # Nur hinzufügen, wenn der Key wie eine Zahl aussieht (Sicherheitscheck)
            if ($rawCounterData[$i] -match '^\d+$') {
                # Wir casten die ID zu Int für saubere Lookups

                $id = [int]$rawCounterData[$i]
                $name = $rawCounterData[$i+1]

                $counterMap[$id] = $name
            }
        }

        return $counterMap

    } catch {
        Write-Error "Fehler bei Registry-Zugriff auf '$ComputerName': $_"
        return $null
    } finally {
        # Aufräumen
        if ($subKey) { $subKey.Close() }
        # Bei lokalem Zugriff dürfen wir LocalMachine nicht schließen (es ist statisch),
        # aber OpenRemoteBaseKey Objekte müssen geschlossen werden.
        if ($regKey -and $regKey.Name -ne "HKEY_LOCAL_MACHINE") { $regKey.Close() }
    }
}

# --- TEST ---
$map = Get-PerfCounterMapFromRegistry -ComputerName "lab-node1"

if ($map) {
    Write-Host "Erfolg! Anzahl geladener Counter: $($map.Count)"
    Write-Host "ID 238: $($map[238])"
    Write-Host "ID 6:   $($map[6])"
}