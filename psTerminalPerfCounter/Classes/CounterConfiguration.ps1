using namespace System.Collections.Generic

class CounterConfiguration {
    [string]                $counterID
    [string]                $counterSetType
    [string]                $counterInstance
    [string]                $CounterPath
    [string]                $Title
    [string]                $Type
    [string]                $Format
    [int]                   $conversionFactor
    [int]                   $conversionExponent
    [string]                $Unit
    [hashtable]             $graphConfiguration
    [List[PSCustomObject]]  $HistoricalData
    [hashtable]             $ColorMap
    [hashtable]             $Statistics
    [bool]                  $IsAvailable
    [bool]                  $isRemote
    [string]                $ComputerName
    [pscredential]          $Credential
    [string]                $LastError
    [datetime]              $LastUpdate


    CounterConfiguration([string]$counterID, [string]$counterSetType, [string]$counterInstance, [string]$title, [string]$Type, [string]$Format, [string]$unit, [int]$conversionFactor, [int]$conversionExponent, [psobject]$colorMap, [psobject]$graphConfiguration) {
        $this.counterID             = $counterID
        $this.counterSetType        = $counterSetType
        $this.counterInstance       = $counterInstance
        $this.CounterPath           = $this.GetCounterPath($counterID, $counterSetType, $counterInstance)
        $this.Title                 = $title
        $this.Type                  = $Type
        $this.Format                = $Format
        $this.Unit                  = $unit
        $this.conversionFactor      = $conversionFactor
        $this.conversionExponent    = $conversionExponent
        $this.ColorMap              = $this.SetColorMap($colorMap)
        $this.GraphConfiguration    = $this.SetGraphConfig($graphConfiguration)
        $this.HistoricalData        = [List[PSCustomObject]]::new()
        $this.Statistics            = @{}
        $this.IsAvailable           = $false
        $this.LastError             = ""
        $this.isRemote              = $false
        $this.ComputerName          = $env:COMPUTERNAME
        $this.Credential            = $null
    }

    [hashtable] SetColorMap([psobject]$colorMap) {

        $returnObject = @{}
        foreach ( $property in $colorMap.PSObject.Properties ) {
            $returnObject[[int]$property.Name] = $property.Value
        }
        return $returnObject

    }

    [hashtable] SetGraphConfig([psobject]$graphConfiguration) {

        $returnObject = @{}
        foreach ( $property in $graphConfiguration.PSObject.Properties ) {

                if ( $property.Name -eq "colors" -and $property.Value ) {
                    $Colors = @{}
                    foreach ( $colorProperty in $property.Value.PSObject.Properties ) {
                        $Colors[$colorProperty.Name] = $colorProperty.Value
                    }

                    $returnObject["Colors"] = $Colors

                } else {

                    # override min values for specific properties
                    if ( $property.Name -eq "Samples" -and $property.Value -lt 70 ) {
                        $returnObject[$property.Name] = 70
                    } elseif ( $property.Name -eq "yAxisMaxRows" -and $property.Value -lt 10 ) {
                        $returnObject[$property.Name] = 10
                    } else {
                        $returnObject[$property.Name] = $property.Value
                    }

                }
            }
        return $returnObject

    }

    [string] GetCounterPath([string]$counterID, [string]$counterSetType, [string]$counterInstance) {

        [string] $returnObject = ""

        if ( -not $counterID ) {
            throw "Counter ID cannot be null or empty."
        }

        try {

            $setID          = $counterID.Split('-')[0]
            $pathID         = $counterID.Split('-')[1]

            $setName        = Get-PerformanceCounterLocalName -Id $setID    -ErrorAction Stop
            $pathName       = Get-PerformanceCounterLocalName -Id $pathID   -ErrorAction Stop

            if ( $counterSetType -eq 'SingleInstance'  ) {
                $returnObject = "\$($setName)\$($pathName)"
            } elseif ( $counterSetType -eq 'MultiInstance' ) {
                $returnObject = "\$setName($counterInstance)\$pathName"
            } else {
                throw "Unknown counter set type: $counterSetType"
            }

            return $returnObject

        } catch {
            Throw "Error getting counter path for ID '$counterID': $($_.Exception.Message)"
        }

    }

    # Test if counter is available
    [bool] TestAvailability() {

        try {
            $null               = Get-Counter -Counter $this.CounterPath -MaxSamples 1 -ErrorAction Stop
            $this.IsAvailable   = $true
            $this.LastError     = ""
            return $true
        } catch {
            $this.IsAvailable   = $false
            $this.LastError     = $_.Exception.Message
            return $false
        }

    }

    # Add new data point with timestamp
    [void] AddDataPoint([int]$value, [int]$maxHistoryPoints) {

        $dataPoint = [PSCustomObject]@{
            Timestamp = Get-Date
            Value = $value
        }

        $this.HistoricalData.Add($dataPoint)
        $this.LastUpdate = $dataPoint.Timestamp

        # Limit historical data size, drop oldest point
        while ( $this.HistoricalData.Count -gt $maxHistoryPoints ) {
            $this.HistoricalData.RemoveAt(0)
        }

        # Update statistics
        $this.UpdateStatistics()

    }

    # Update statistics
    [void] UpdateStatistics() {

        if ( $this.HistoricalData.Count -eq 0 ) { return }

        $values = $this.HistoricalData | ForEach-Object { $_.Value }

        $this.Statistics = @{
            Current = $values[-1]
            Minimum = ($values | Measure-Object -Minimum).Minimum
            Maximum = ($values | Measure-Object -Maximum).Maximum
            Average = [Math]::Round(($values | Measure-Object -Average).Average, 1)
            Count   = $values.Count
            Last5   = if ($values.Count -ge 5) { $values[-5..-1] } else { $values }
        }

    }

    # Get current value from performance counter
    [int] GetCurrentValue() {

        if ( -not $this.IsAvailable ) {
            throw "Counter '$($this.Title)' is not available: $($this.LastError)"
        }

        try {

            if ( $this.isRemote ) {

                $paramRemote = @{
                    ComputerName = $this.computername
                }

                if ( $this.Credential ) {
                    $paramRemote.Credential = $this.Credential
                }

                $script = {
                    param($CounterPath, $MaxSamples)
                    $counter = Get-Counter -Counter $CounterPath -MaxSamples $MaxSamples
                    $counter.CounterSamples.CookedValue
                }

                $value = Invoke-Command @paramRemote -ScriptBlock $script -ArgumentList $this.CounterPath, 1

            } else {

                $value = (Get-Counter -Counter $this.CounterPath -MaxSamples 1).CounterSamples.CookedValue

            }

            # Convert Units
            $value = [Math]::Round($value / [Math]::Pow($this.conversionFactor, $this.conversionExponent))

            return $value

        } catch {
            $this.LastError = $_.Exception.Message
            throw "Error reading counter '$($this.Title)': $($_.Exception.Message)"
        }

    }

    # Get color for a specific value
    [string] GetColorForValue([int]$value) {

        if ( $this.ColorMap.Count -eq 0 ) { return "White" }

        # map color by thresholds
        $sortedThresholds = $this.ColorMap.Keys | Sort-Object -Descending

        foreach ( $threshold in $sortedThresholds ) {
            if ( $value -ge $threshold ) {
                return $this.ColorMap[$threshold]
            }
        }

        return "White"  # Default color

    }

    # Get formatted title with unit
    [string] GetFormattedTitle() {

        if ( [string]::IsNullOrEmpty($this.Unit) ) { return $this.Title }
        return "$($this.Title) ($($this.Unit))"

    }

    # Get data for graphing (padded to target sample count)
    [int[]] GetGraphData([int]$sampleCount) {

        $dataCount = $this.HistoricalData.Count
        if ( $dataCount -eq 0 ) { return @() }

        # Extract values from timestamped data points
        $values = $this.HistoricalData | ForEach-Object { $_.Value }

        # Take the last sampleCount points
        if ( $dataCount -ge $sampleCount ) {
            return $values[-$sampleCount..-1]

        # Pad with zeros at the beginning
        } else {
            $padding = @(0) * ($sampleCount - $dataCount)
            return $padding + $values
        }
    }

    # Get complete historical data with timestamps for external tools
    [PSCustomObject[]] GetHistoricalDataWithTimestamps() {
        return $this.HistoricalData.ToArray()
    }

    # ToString override for output
    [string] ToString() {
        return "PerformanceCounter: $($this.Title) - Available: $($this.IsAvailable) - Data Points: $($this.HistoricalData.Count)"
    }
}
