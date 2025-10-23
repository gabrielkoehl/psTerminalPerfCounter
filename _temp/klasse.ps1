class klasse {
   [string]   $Name    # Name der Person
   [int]      $Alter   # Alter der Person

   # Konstruktor: Initialisiert eine neue Instanz der Klasse
   klasse([string]$name, [int]$alter) {
       $this.Name = $name
       $this.Alter = $alter
   }

   # Methode, die eine zeitaufwändige Operation simuliert
   [int] Vorstellung() {
       # Zeigt Start-Zeit und Thread-ID an (wichtig für Parallelitäts-Debugging)
       Write-Host "$(Get-Date) - START: $($this.Name) - ThreadID: $([System.Threading.Thread]::CurrentThread.ManagedThreadId)" -ForegroundColor Green
       Start-Sleep 1    # Simuliert zeitaufwändige Arbeit
       # Zeigt End-Zeit und Thread-ID an
       Write-Host "$(Get-Date) - END: $($this.Name) - ThreadID: $([System.Threading.Thread]::CurrentThread.ManagedThreadId)" -ForegroundColor Red
       return 42        # Gibt einen festen Wert zurück
   }
}