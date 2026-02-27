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
    if (-not $script:tpcPerfCounterReverseCache) { $script:tpcPerfCounterReverseCache = @{} }

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

            $tempMap        = @{}
            $tempReverse    = @{}

            for ($i = 0; $i -lt ($rawCounterData.Count - 1); $i += 2) {
                if ([string]$rawCounterData[$i] -match '^\d+$') {
                    $cId   = [int]$rawCounterData[$i]
                    $cName = $rawCounterData[$i+1]

                    if ($cName) {
                        $trimmedName        = $cName.Trim()
                        $tempMap[$cId]      = $trimmedName

                        # Reverse lookup: Name -> ID (first match wins, needed for SQL multi-instance)
                        if (-not $tempReverse.ContainsKey($trimmedName)) {
                            $tempReverse[$trimmedName] = $cId
                        }
                    }
                }
            }

            $script:tpcPerfCounterCache[$cacheKey]          = $tempMap
            $script:tpcPerfCounterReverseCache[$cacheKey]    = $tempReverse

        } catch {

            Write-Error "Error building cache on $ComputerName : $_"
            return $null

        }
    }

    $counterMap         = $script:tpcPerfCounterCache[$cacheKey]
    $reverseMap         = $script:tpcPerfCounterReverseCache[$cacheKey]

    if ($PSCmdlet.ParameterSetName -eq 'ByName') {

        # O(1) reverse lookup instead of O(n) enumeration
        if ($reverseMap.ContainsKey($Name)) {
            return $reverseMap[$Name]
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