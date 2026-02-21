function Get-PerformanceCounterLookup {
    [CmdletBinding(DefaultParameterSetName = 'ByName')]
    param(
        [Parameter(Mandatory, ParameterSetName = 'ByName', Position = 0)]
        [string] $Name,

        [Parameter(Mandatory, ParameterSetName = 'ById', Position = 0)]
        [int] $Id,

        [Parameter(Mandatory = $false)]
        [string] $ComputerName = $env:COMPUTERNAME,

        [Parameter(Mandatory = $false)]
        [pscredential] $Credential = $null


    )

    # Global cache to prevent repeated registry reads
    if (-not $script:tpcPerfCounterCache) { $script:tpcPerfCounterCache = @{} }

    $cacheKey = $ComputerName.ToLower()

    # Populate cache if empty
    if (-not $script:tpcPerfCounterCache.ContainsKey($cacheKey)) {

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

                if ($Credential) {
                    $conParam['Credential'] = $Credential
                }
            }

            $rawCounterData = Invoke-Command @conParam

            if (-not $rawCounterData) { Throw "No data returned from registry." }

            $tempMap = @{}

            for ($i = 0; $i -lt ($rawCounterData.Count - 1); $i += 2) {
                if ([string]$rawCounterData[$i] -match '^\d+$') {
                    $cId   = [int]$rawCounterData[$i]
                    $cName = $rawCounterData[$i+1]

                    if ($cName) {
                        # Use lowercase key for case-insensitive lookup later if needed, trimmed... safe
                        # but keeping ID mapping clean
                        $tempMap[$cId] = $cName.Trim()
                    }
                }
            }

            $script:tpcPerfCounterCache[$cacheKey] = $tempMap

        } catch {

            Write-Error "Error building cache on $ComputerName : $_"
            return $null

        }
    }

    $counterMap = $script:tpcPerfCounterCache[$cacheKey]

    if ($PSCmdlet.ParameterSetName -eq 'ByName') {
        $result = $counterMap.GetEnumerator() | Where-Object { $_.Value -eq $Name } | Select-Object -First 1 # not shure if this breaks things later, needed for sql for example with multiple instances

        if ($result) {
            return $result.Key
        } else {
            return $null
        }
    }
    else {
        if ($counterMap.ContainsKey($Id)) {
            return $counterMap[$Id]
        } else {
            return $null
        }
    }
}