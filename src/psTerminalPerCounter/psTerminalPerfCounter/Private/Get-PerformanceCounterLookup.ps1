function Get-PerformanceCounterLookup {
    [CmdletBinding(DefaultParameterSetName = 'ByName')]
    param(
        [Parameter(Mandatory, ParameterSetName = 'ByName', Position = 0)]
        [string] $Name,

        [Parameter(Mandatory, ParameterSetName = 'ById', Position = 0)]
        [int] $Id,

        [Parameter(Mandatory = $false)]
        [string] $ComputerName = $env:COMPUTERNAME
    )

    $remoteScript = {
        try {
            $path   = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Perflib\CurrentLanguage"
            $values = Get-ItemProperty -Path $path -Name "Counter" -ErrorAction Stop
            return $values.Counter
        }
        catch {
            Write-Error "Error accessing registry: $_"
        }
    }

    try {
        $conParam = @{
            ScriptBlock = $remoteScript
            ErrorAction = 'Stop'
        }

        if (-not [string]::IsNullOrWhiteSpace($ComputerName) -and $ComputerName -ne $env:COMPUTERNAME) {
            $conParam['ComputerName'] = $ComputerName
        }

        $rawCounterData = Invoke-Command @conParam

        if (-not $rawCounterData) { Throw "No data returned from registry." }

        $counterMap = @{}

        for ($i = 0; $i -lt ($rawCounterData.Count - 1); $i += 2) {
            if ([string]$rawCounterData[$i] -match '^\d+$') {
                $cId   = [int]$rawCounterData[$i]
                $cName = $rawCounterData[$i+1]
                $counterMap[$cId] = $cName
            }
        }

        if ($PSCmdlet.ParameterSetName -eq 'ByName') {
            $result = $counterMap.GetEnumerator() | Where-Object { $_.Value -eq $Name }

            if ($result) {
                return $result.Key
            } else {
                throw "Counter name '$Name' not found on '$ComputerName'."
            }
        }
        else {
            if ($counterMap.ContainsKey($Id)) {
                return $counterMap[$Id]
            } else {
                throw "Counter ID '$Id' not found on '$ComputerName'."
            }
        }

    } catch {
        Write-Error "Error retrieving performance counter data on $ComputerName : $_"
    }
}


# Get-PerformanceCounterLookup -Name "Processor"
# Get-PerformanceCounterLookup -Id 238
# Get-PerformanceCounterLookup -ComputerName 'lab-node2' -Name "Processor"
