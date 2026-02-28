


    $ComputerName = $Env:COMPUTERNAME
    $name = 'sql'

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

        $counterMap.GetEnumerator() | Where-Object { $_.Value -like "*$Name*" }
