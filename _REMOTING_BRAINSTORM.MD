```powershell

$cred = get-credential
while ($true) {
   $cpuValue = Invoke-Command -ComputerName "DEV-DC" -Credential $cred -ScriptBlock {
       (Get-Counter "\Processor(_Total)\% Processor Time").CounterSamples.CookedValue
   }
   Write-Host ([Math]::Round($cpuValue, 0))
   Start-Sleep 1
}

```

- Already prepare that for console graph only 1 server is possible, for export, HTML etc. multiple servers
- Enable credential vault connectors, or direct credential passing
- Parallel processing via runspaces, since multiple servers will likely block each other
- Possibility for each server to have its own JSON config
- Also work with configuration files again to quickly load specific server sets and configs, but also enable direct loading
- In this context, also implement the output as JSON right away, depending on what PsWriteHTML requires


# Challenges

- all values from all counters need same timestamp