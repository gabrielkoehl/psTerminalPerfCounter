function Test-tpcServerConfiguration {
    <#
    .SYNOPSIS
        Testet die ServerConfiguration-Klasse mit paralleler Counter-Abfrage

    .DESCRIPTION
        Diese Funktion ist zum Testen der neuen async ServerConfiguration-Funktionalität gedacht.
        Sie erstellt eine ServerConfiguration-Instanz mit mehreren Countern und testet die
        parallele Abfrage über GetValuesParallelAsync().

        Zeigt:
        - Server-Verfügbarkeit
        - Parallele Counter-Abfrage
        - Timestamp und Dauer
        - Counter-Werte und Statistiken

    .PARAMETER ComputerName
        Name des zu testenden Servers
        Default: Localhost

    .PARAMETER ConfigName
        Name der Counter-Konfiguration (ohne 'tpc_' und '.json')
        Default: 'CPU'

    .PARAMETER Credential
        Credentials für Remote-Zugriff
        Optional

    .PARAMETER Iterations
        Anzahl der Test-Durchläufe
        Default: 3

    .EXAMPLE
        Test-tpcServerConfiguration

        Testet den lokalen Server mit CPU-Countern

    .EXAMPLE
        Test-tpcServerConfiguration -ComputerName "DEV-DC" -ConfigName "CPU" -Iterations 5

        Testet den Remote-Server DEV-DC mit 5 Durchläufen

    .EXAMPLE
        Test-tpcServerConfiguration -ComputerName "DEV-NODE3" -Credential $cred

        Testet Remote-Server mit expliziten Credentials

    .OUTPUTS
        Zeigt detaillierte Test-Ausgabe in der Konsole

    .NOTES
        Entwicklungs-/Test-Funktion für die ServerConfiguration-Klasse
    #>

    [CmdletBinding()]
    param(
        [Parameter()]
        [string] $ComputerName = $env:COMPUTERNAME,

        [Parameter()]
        [string] $ConfigName = 'CPU',

        [Parameter()]
        [pscredential] $Credential = $null,

        [Parameter()]
        [int] $Iterations = 3
    )

    BEGIN {

        Write-Host "`n=== ServerConfiguration Test ===" -ForegroundColor Cyan
        Write-Host "Computer: $ComputerName" -ForegroundColor White
        Write-Host "Config  : $ConfigName" -ForegroundColor White
        Write-Host "Iterations: $Iterations" -ForegroundColor White
        Write-Host ""

    }

    PROCESS {

        try {

            # 1. Counter-Konfiguration laden
            Write-Host "[1/4] Loading counter configuration..." -ForegroundColor Yellow

            $isRemote = $ComputerName -ne $env:COMPUTERNAME

            if ($isRemote) {
                Write-Host "  Remote mode for $ComputerName" -ForegroundColor Gray
                $counters = Get-CounterConfiguration -ConfigName $ConfigName -isRemote -computername $ComputerName -credential $Credential
            } else {
                Write-Host "  Local mode" -ForegroundColor Gray
                $counters = Get-CounterConfiguration -ConfigName $ConfigName
            }

            if (-not $counters -or $counters.Counters.Count -eq 0) {
                Write-Warning "No counters loaded"
                return
            }

            Write-Host "  Loaded $($counters.Counters.Count) counter(s)" -ForegroundColor Green
            Write-Host ""

            # 2. ServerConfiguration erstellen
            Write-Host "[2/4] Creating ServerConfiguration object..." -ForegroundColor Yellow

            $server = [psTPCCLASSES.ServerConfiguration]::new(
                $script:logger,
                $ComputerName,
                "Test Server",
                $counters.Counters
            )

            Write-Host "  IsAvailable: $($server.IsAvailable)" -ForegroundColor $(if($server.IsAvailable){"Green"}else{"Red"})

            if (-not $server.IsAvailable) {
                Write-Warning "Server not available: $($server.LastError)"
                return
            }

            Write-Host "  Total Counters: $($server.Counters.Count)" -ForegroundColor Green
            Write-Host "  Available Counters: $($server.Counters | Where-Object IsAvailable | Measure-Object | Select-Object -ExpandProperty Count)" -ForegroundColor Green
            Write-Host ""

            # 3. Counter Details anzeigen
            Write-Host "[3/4] Counter details:" -ForegroundColor Yellow
            foreach ($counter in $server.Counters) {
                $status = if ($counter.IsAvailable) { "✓" } else { "✗" }
                $statusColor = if ($counter.IsAvailable) { "Green" } else { "Red" }
                Write-Host "  [$status] $($counter.Title) - $($counter.CounterPath)" -ForegroundColor $statusColor
            }
            Write-Host ""

            # 4. Parallele Abfragen testen
            Write-Host "[4/4] Testing parallel queries ($Iterations iteration(s))..." -ForegroundColor Yellow
            Write-Host ""

            for ($i = 1; $i -le $Iterations; $i++) {

                Write-Host "  Iteration $i of $Iterations" -ForegroundColor Cyan

                # Zeitmessung starten
                $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

                # ASYNC Parallele Abfrage
                $server.GetValuesParallelAsync().GetAwaiter().GetResult()

                $stopwatch.Stop()

                # Ergebnisse anzeigen
                Write-Host "    Last Update: $($server.LastUpdate.ToString('HH:mm:ss.fff'))" -ForegroundColor Gray
                Write-Host "    Total Duration: $($stopwatch.ElapsedMilliseconds)ms" -ForegroundColor Gray
                Write-Host ""

                # Counter-Werte anzeigen
                foreach ($counter in $server.Counters | Where-Object IsAvailable) {

                    if ($counter.HistoricalData.Count -gt 0) {
                        $latestData = $counter.HistoricalData[-1]
                        $value = $latestData.Value
                        $timestamp = $latestData.Timestamp.ToString('HH:mm:ss.fff')

                        Write-Host "    $($counter.Title): $value $($counter.Unit) (at $timestamp)" -ForegroundColor White

                        # Statistiken nach mehreren Iterationen
                        if ($counter.Statistics.Count -gt 0) {
                            $stats = $counter.Statistics
                            Write-Host "      Stats: Min=$($stats['Minimum']), Max=$($stats['Maximum']), Avg=$($stats['Average'])" -ForegroundColor DarkGray
                        }
                    }

                }

                Write-Host ""

                # Pause zwischen Iterationen (außer bei letzter)
                if ($i -lt $Iterations) {
                    Start-Sleep -Seconds 2
                }

            }

            # Server-Statistiken anzeigen
            Write-Host "=== Final Server Statistics ===" -ForegroundColor Cyan
            $server.UpdateStatistics()
            $server.Statistics.GetEnumerator() | Sort-Object Name | ForEach-Object {
                Write-Host "  $($_.Key): $($_.Value)" -ForegroundColor White
            }
            Write-Host ""

            # Zusammenfassung
            Write-Host "=== Test Summary ===" -ForegroundColor Green
            Write-Host "Server: $($server.ComputerName) - Available: $($server.IsAvailable)" -ForegroundColor White
            Write-Host "Counters tested: $($server.Counters.Count)" -ForegroundColor White
            Write-Host "Iterations completed: $Iterations" -ForegroundColor White
            Write-Host "Last update: $($server.LastUpdate)" -ForegroundColor White
            Write-Host ""
            Write-Host "Test completed successfully!" -ForegroundColor Green

        } catch {

            Write-Host "`n=== ERROR ===" -ForegroundColor Red
            Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Yellow
            Write-Host "StackTrace: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
            throw

        }

    }

    END {

    }

}
