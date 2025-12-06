<#

https://powershell.one/tricks/performance/performance-counters
Licensed under the CC BY 4.0 ( https://creativecommons.org/licenses/by/4.0/ )


#>

Function Get-PerformanceCounterLocalName
{
  param
  (
    [UInt32]
    $ID,

    $ComputerName = $env:COMPUTERNAME
  )

  $code = '[DllImport("pdh.dll", SetLastError=true, CharSet=CharSet.Unicode)] public static extern UInt32 PdhLookupPerfNameByIndex(string szMachineName, uint dwNameIndex, System.Text.StringBuilder szNameBuffer, ref uint pcchNameBufferSize);'
  $type = Add-Type -MemberDefinition $code -PassThru -Name PerfCounter1 -Namespace Utility

  $Buffer = [System.Text.StringBuilder]::new(1024)
  [UInt32]$BufferSize = $Buffer.Capacity


  $rv = $type::PdhLookupPerfNameByIndex($ComputerName, $id, $Buffer, [Ref]$BufferSize)

  if ($rv -eq 0)
  {
    $Buffer.ToString().Substring(0, $BufferSize-1)
  }
  else
  {
    Throw 'Get-PerformanceCounterLocalName : Unable to retrieve localized name. Check computer name and performance counter ID.'
  }
}