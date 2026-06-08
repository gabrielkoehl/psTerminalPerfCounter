function Test-tpcWinRm {
    <#
        .SYNOPSIS
            Fast TCP reachability check for the WinRM (PowerShell Remoting) port.

        .DESCRIPTION
            Single, module-wide definition of "is this host reachable for remoting?".
            All remote data collection runs over WinRM (Invoke-Command), so this is the only
            reachability probe the module needs.

            Uses a TcpClient connect with an explicit timeout, deliberately NOT:
              * ICMP ping (Test-Connection) - firewalls often block ICMP while allowing WinRM, and
                a green ping does not prove WinRM is up either.
              * Test-NetConnection -Port - it has no timeout parameter and blocks for the full OS
                SYN timeout (~21s) on dropped/dead hosts, which defeats fast-fail in multi-server runs.

            For WinRM over HTTPS the port would be 5986.

        .PARAMETER ComputerName
            DNS name or address of the host to probe.

        .PARAMETER Port
            TCP port to test. Default: 5985 (WinRM HTTP).

        .PARAMETER TimeoutMs
            Connect timeout in milliseconds. Default: 2000.
    #>
    [OutputType([bool])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $ComputerName,

        [int]    $Port      = 5985,

        [int]    $TimeoutMs = 2000
    )

    $tcp = [System.Net.Sockets.TcpClient]::new()
    try {
        $connectTask = $tcp.ConnectAsync($ComputerName, $Port)
        # Wait() returns $false on timeout; a refused connection / DNS failure surfaces as an exception
        return ( $connectTask.Wait($TimeoutMs) -and $tcp.Connected )
    } catch {
        return $false
    } finally {
        $tcp.Dispose()
    }
}
