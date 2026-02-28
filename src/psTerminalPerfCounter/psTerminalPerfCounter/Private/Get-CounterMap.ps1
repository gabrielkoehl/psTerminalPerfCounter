function Get-CounterMap {
    [CmdletBinding()]
    [OutputType([System.Collections.Generic.Dictionary[int, string]])]
    param(
        [Parameter(Position = 0)]
        [string] $ComputerName = $env:COMPUTERNAME,

        [Parameter()]
        [PSCredential] $Credential
    )

    $counterMapScript = {
        try {
            $path   = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Perflib\CurrentLanguage"
            $values = Get-ItemProperty -Path $path -Name "Counter" -ErrorAction Stop
            return $values.Counter
        }
        catch {
            throw "Error accessing registry on $env:COMPUTERNAME : $_"
        }
    }

    try {
        $rawCounterData = $null

        $invokeParams = @{
            ScriptBlock = $counterMapScript
            ErrorAction = 'Stop'
        }

        $isLocal = [string]::IsNullOrWhiteSpace($ComputerName) -or ($ComputerName -eq $env:COMPUTERNAME)

        if ($isLocal) {
            Write-Host "Retrieving CounterMap locally..." -ForegroundColor Yellow
            $rawCounterData = & $counterMapScript
        }
        else {
            Write-Host "Retrieving CounterMap from remote computer: $ComputerName..." -ForegroundColor Yellow
            $invokeParams['ComputerName'] = $ComputerName

            if ($Credential) {
                $invokeParams['Credential'] = $Credential
            }

            $rawCounterData = Invoke-Command @invokeParams
        }

        if (-not $rawCounterData) {
            throw "No data returned from registry on '$ComputerName'."
        }

        $counterMap = [System.Collections.Generic.Dictionary[int, string]]::new()

        for ($i = 0; $i -lt ($rawCounterData.Count - 1); $i += 2) {
            if ([string]$rawCounterData[$i] -match '^\d+$') {
                $cId   = [int]$rawCounterData[$i]
                $cName = $rawCounterData[$i+1]

                if (-not [string]::IsNullOrWhiteSpace($cName)) {
                    $counterMap[$cId] = $cName
                }
            }
        }

        return $counterMap

    }
    catch {
        Write-Error "Failed to retrieve CounterMap: $($_.Exception.Message)"
    }
}