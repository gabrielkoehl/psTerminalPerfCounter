using System.Management.Automation;

namespace psTPCCLASSES;

public class PowerShellLogger
{
     public PowerShellLogger()
     {

     }

     public void Info(string source, string message)
     {
          var script = $"Write-Host '[{source}] {message}' -ForegroundColor Cyan";
          ExecuteScript(script);
     }

     public void Warning(string source, string message)
     {
          var script = $"Write-Warning '[{source}] {message}'";
          ExecuteScript(script);
     }

     public void Error(string source, string message)
     {
          var script = $"Write-Error '[{source}] {message}'";
          ExecuteScript(script);
     }

     public void Verbose(string source, string message)
     {
          var script = $"Write-Verbose '[{source}] {message}'";
          ExecuteScript(script);
     }

     private void ExecuteScript(string script)
     {
          using var ps = PowerShell.Create(RunspaceMode.NewRunspace);
          ps.AddScript(script);
          ps.Invoke();
     }
}