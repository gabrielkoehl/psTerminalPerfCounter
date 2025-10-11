$exportData = @{
    Intervall = $intervallInSekunden
    Computer = @{}
}

# Für jeden Computer:
$exportData.Computer[$computerName] = @{}

# Für jeden Counter:
$exportData.Computer[$computerName][$counterName] = @{
    Title =     $displayName     # z.B. "CPU Auslastung"
    Unit       = $unit           # z.B. "%", "MB", "MB/sec"
    Values     = @{}             # Hashtable mit Timestamp = Wert
}

# Werte hinzufügen:
$exportData.Computer[$computerName][$counterName].Values[$timestamp] = $value

WICHTIG:
- Timestamps als String im ISO-Format: (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss")
- Alle Counter eines Computers sollten die gleichen Timestamps haben
- Values sollten numerisch sein (Int/Double)
- PSWriteHTML benötigt für Line Charts Arrays in der richtigen Reihenfolge