<#

  https://powershell.one/tricks/performance/performance-counters
  Licensed under the CC BY 4.0 ( https://creativecommons.org/licenses/by/4.0/ )


#>

function Get-PerformanceCounterId
{
    param(
        [Parameter(Mandatory)]
        [string]
        $Name,

        $ComputerName = $env:COMPUTERNAME
    )

    $code = '[DllImport("pdh.dll", SetLastError=true, CharSet=CharSet.Unicode)]public static extern UInt32 PdhLookupPerfIndexByName(string szMachineName, string szNameBuffer, ref uint dwNameIndex);'
    $type = Add-Type -MemberDefinition $code -PassThru -Name PerfCounter2 -Namespace Utility


    [UInt32]$Index = 0
    if ($type::PdhLookupPerfIndexByName($ComputerName, $Name, [Ref]$Index) -eq 0)
    {
      $index
    }
    else
    {
      throw "Cannot find '$Name' on '$ComputerName'."
    }
}