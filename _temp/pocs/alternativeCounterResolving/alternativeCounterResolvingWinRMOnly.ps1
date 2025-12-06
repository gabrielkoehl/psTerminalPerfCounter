function Get-PerfCounterMapViaWinRM {
    param (
        [string]$ComputerName = "localhost"
    )

    $remoteScript = {
        try {
            # Registry Key öffnen (Lokal auf dem Ziel!)
            $path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Perflib\CurrentLanguage"
            $values = Get-ItemProperty -Path $path -Name "Counter" -ErrorAction Stop
            return $values.Counter # string[] array
        }
        catch {
            Write-Error "Registry Zugriff auf Ziel fehlgeschlagen: $_"
        }
    }

    try {
        # invoke command, um remote registry abhängigkeit zu umgehen
        $rawCounterData = Invoke-Command -ComputerName $ComputerName -ScriptBlock $remoteScript -ErrorAction Stop

        if (-not $rawCounterData) { return $null }

        # lokales parsing, einfache map
        $counterMap = @{}

        for ($i = 0; $i -lt ($rawCounterData.Count - 1); $i += 2) {
            # teste für Zahl
            if ($rawCounterData[$i] -match '^\d+$') {
                $id = [int]$rawCounterData[$i]
                $name = $rawCounterData[$i+1]

                $counterMap[$id] = $name
            }
        }

        return $counterMap

    } catch {
        Write-Error "Verbindung zu $ComputerName fehlgeschlagen: $_"
        return $null
    }
}

# die gesamt map wird in die klasse geladen, einmal und kann dann ausgelesen werden

$map = Get-PerfCounterMapViaWinRM -ComputerName "lab-node1"

if ($map) {
    Write-Host "Lookup via WinRM erfolgreich."
    Write-Host "SetID 238 Name: $($map[238])"
    Write-Host "CounterID 6 Name: $($map[6])"

    # auch für sql server :)
    $map.GetEnumerator() |  where { $_.value -like "*SQL*"}

}