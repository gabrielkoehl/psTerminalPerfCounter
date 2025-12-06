# -----------------------------------------------------------
# Variablen definieren (238 = Processor, 6 = % Processor Time)
# -----------------------------------------------------------
$FullIdString = "238-6"
$Parts = $FullIdString -split '-'
$SetId = [uint32]$Parts[0]
$PathId = [uint32]$Parts[1]

Write-Host "Teste 'ALTE LÖSUNG' für ID: $SetId und $PathId..." -ForegroundColor Cyan
Write-Host "HINWEIS: Das Kompilieren wird jetzt bei JEDEM Aufruf erzwungen." -ForegroundColor Yellow

# -----------------------------------------------------------
# Die "LANGSAME" Funktion (Simuliert das Problem)
# -----------------------------------------------------------
Function Get-PerformanceCounterLocalNameSlow
{
    param
    (
        [UInt32]
        $ID,

        $ComputerName = $env:COMPUTERNAME
    )

    # Wir erzeugen einen eindeutigen Namen, um den C#-Compiler (csc.exe)
    # zwingend jedes Mal neu zu starten (Simuliert deinen C# Konstruktor-Effekt)
    $RandomName = "PerfCounter_" + [Guid]::NewGuid().ToString("N")

    $code = '[DllImport("pdh.dll", SetLastError=true, CharSet=CharSet.Unicode)] public static extern UInt32 PdhLookupPerfNameByIndex(string szMachineName, uint dwNameIndex, System.Text.StringBuilder szNameBuffer, ref uint pcchNameBufferSize);'

    # --- HIER IST DER FLASCHENHALS ---
    # Add-Type läuft jedes Mal komplett durch
    $type = Add-Type -MemberDefinition $code -PassThru -Name $RandomName -Namespace Utility

    $Buffer = [System.Text.StringBuilder]::new(1024)
    [UInt32]$BufferSize = $Buffer.Capacity

    $rv = $type::PdhLookupPerfNameByIndex($ComputerName, $id, $Buffer, [Ref]$BufferSize)

    if ($rv -eq 0)
    {
        $Buffer.ToString().Substring(0, $BufferSize-1)
    }
    else
    {
        Throw 'Get-PerformanceCounterLocalName : Unable to retrieve localized name.'
    }
}

# -----------------------------------------------------------
# Test-Ausführung mit Zeitmessung
# -----------------------------------------------------------

Write-Host "`n--- Start Test 1 (Set Name - Langsam) ---"
$Zeit1 = Measure-Command {
    $SetName = Get-PerformanceCounterLocalNameSlow -ID $SetId
}
Write-Host "Ergebnis Set:  '$SetName'" -ForegroundColor Red
Write-Host "Dauer:         $($Zeit1.TotalMilliseconds) ms"

Write-Host "`n--- Start Test 2 (Counter Name - Langsam) ---"
$Zeit2 = Measure-Command {
    $PathName = Get-PerformanceCounterLocalNameSlow -ID $PathId
}
Write-Host "Ergebnis Path: '$PathName'" -ForegroundColor Red
Write-Host "Dauer:         $($Zeit2.TotalMilliseconds) ms"

Write-Host "`n--- Gesamtergebnis ---"
Write-Host "Counterpfad:   \$SetName\$PathName" -ForegroundColor Magenta
Write-Host "Gesamtdauer:   $(($Zeit1.TotalMilliseconds + $Zeit2.TotalMilliseconds)) ms" -ForegroundColor Red