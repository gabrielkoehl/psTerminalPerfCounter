using namespace System.Collections.Generic

class PerformanceCounter {
    [string]    $counterID
    [string]    $counterSetType
    [string]    $counterInstance
    [string]    $CounterPath
    [string]    $Title
    [string]    $Type
    [string]    $Format
    [int]       $conversionFactor
    [int]       $conversionExponent
    [string]    $Unit
    [hashtable] $graphConfiguration
    [List[int]] $HistoricalData
    [hashtable] $ColorMap
    [hashtable] $Statistics
    [bool]      $IsAvailable
    [string]    $LastError
    [datetime]  $LastUpdate


    # Constructor
    PerformanceCounter([string]$counterID, [string]$counterSetType, [string]$counterInstance, [string]$title, [string]$Type, [string]$Format, [string]$unit, [int]$conversionFactor, [int]$conversionExponent, [psobject]$colorMap, [psobject]$graphConfiguration) {
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
        $this.HistoricalData        = [List[int]]::new()
        $this.Statistics            = @{}
        $this.IsAvailable           = $false
        $this.LastError             = ""
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

    # Add new data point
    [void] AddDataPoint([int]$value, [int]$maxHistoryPoints) {

        $this.HistoricalData.Add($value)
        $this.LastUpdate = Get-Date

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

        $data = $this.HistoricalData.ToArray()

        $this.Statistics = @{
            Current = $data[-1]
            Minimum = ($data | Measure-Object -Minimum).Minimum
            Maximum = ($data | Measure-Object -Maximum).Maximum
            Average = [Math]::Round(($data | Measure-Object -Average).Average, 1)
            Count   = $data.Count
            Last5   = if ($data.Count -ge 5) { $data[-5..-1] } else { $data }
        }

    }

    # Get current value from performance counter
    [int] GetCurrentValue() {

        if ( -not $this.IsAvailable ) {
            throw "Counter '$($this.Title)' is not available: $($this.LastError)"
        }

        try {

            $sample = (Get-Counter -Counter $this.CounterPath -MaxSamples 1).CounterSamples
            $value  = $sample.CookedValue

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

        # Take the last sampleCount points
        if ( $dataCount -ge $sampleCount ) {
            return $this.HistoricalData.GetRange($dataCount - $sampleCount, $sampleCount).ToArray()

        # Pad with zeros at the beginning
        } else {
            $padding = @(0) * ($sampleCount - $dataCount)
            return $padding + $this.HistoricalData.ToArray()
        }
    }

    # ToString override for debugging
    [string] ToString() {
        return "PerformanceCounter: $($this.Title) - Available: $($this.IsAvailable) - Data Points: $($this.HistoricalData.Count)"
    }
}
