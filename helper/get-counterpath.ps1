# Get registry counter ID/Name pairs
$regCounters = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Perflib\009').Counter
$idMap = @{}
for ($i = 0; $i -lt $regCounters.Count - 1; $i += 2) {
    $idMap[[int]$regCounters[$i]] = $regCounters[$i + 1]
}

$nameToId = @{}
$idMap.GetEnumerator() | ForEach-Object { $nameToId[$_.Value] = $_.Key }

$sqlObjects = Get-Counter -ListSet * | Where-Object {
    $_.CounterSetName -match '^(MSSQL\$|SQLServer:|PhysicalDisk|LogicalDisk)'
}

$result = foreach ($obj in $sqlObjects) {
    $objId   = $nameToId[$obj.CounterSetName]
    $isMulti = $obj.CounterSetType.ToString() -eq 'MultiInstance'

    $instances = if ($isMulti) {
        $vals = $obj.PathsWithInstances | ForEach-Object {
            if ($_ -match '\(([^)]+)\)\\') { $matches[1] }
        } | Select-Object -Unique

        if ($vals) { $vals -join ', ' } else { '-' }
    } else { '-' }

    $instanceType = if ($isMulti) { 'MultiInstance' } else { 'SingleInstance' }

    foreach ($counter in $obj.Counter) {
        $leafName  = ($counter -replace '^\\[^\\]+\\', '') -replace '\(\*\)', ''
        $counterId = $nameToId[$leafName]

        [PSCustomObject]@{
            IDRange      = "$objId-$counterId"
            Object       = $obj.CounterSetName
            CounterPath  = $counter
            InstanceType = $instanceType
            Instances    = $instances
        }
    }
}

$result | Sort-Object Object, CounterPath | Format-Table -AutoSize
