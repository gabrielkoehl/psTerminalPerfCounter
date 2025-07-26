function Show-CounterTable {
     [CmdletBinding()]
     param(
          [Parameter(Mandatory=$true)]
          [PerformanceCounter[]]$Counters
     )

     if ( $Counters.Count -eq 0 ) { return }

     # Create table data structure
     $tableData = @()

     foreach ( $Counter in $Counters ) {

          $Stats = $Counter.Statistics

          # Create row data
          $rowData = [PSCustomObject]@{
               Counter        = $Counter
               CounterName    = $Counter.Title
               Unit           = $Counter.Unit
               Current        = if ( $null -ne $Stats.Current )   { $Stats.Current }  else { "-" }
               Last5          = if ( $Stats.Last5.Count -gt 0 )   { $Stats.Last5 }    else { @() }
               Min            = if ( $null -ne $Stats.Minimum )   { $Stats.Minimum }  else { "-" }
               Max            = if ( $null -ne $Stats.Maximum )   { $Stats.Maximum }  else { "-" }
               Avg            = if ( $null -ne $Stats.Average )   { $Stats.Average }  else { "-" }
               ColorMap       = $Counter.colorMap
          }

          $tableData += $rowData

     }

     # Calculate column widths
     $widths = @{
          CounterName    = ($tableData | ForEach-Object { $_.CounterName.Length } | Measure-Object -Maximum).Maximum + 2
          Unit           = ($tableData | ForEach-Object { $_.Unit.Length } | Measure-Object -Maximum).Maximum + 2
          Current        = ($tableData | ForEach-Object { $_.Current.ToString().Length } | Measure-Object -Maximum).Maximum + 2
          Last5          = 0
          Min            = ($tableData | ForEach-Object { $_.Min.ToString().Length } | Measure-Object -Maximum).Maximum + 2
          Max            = ($tableData | ForEach-Object { $_.Max.ToString().Length } | Measure-Object -Maximum).Maximum + 2
          Avg            = ($tableData | ForEach-Object { $_.Avg.ToString().Length } | Measure-Object -Maximum).Maximum + 2
     }

     # Calculate Last5 width
     $maxLast5Count      = ($tableData | ForEach-Object { $_.Last5.Count } | Measure-Object -Maximum).Maximum
     $last5SubWidths     = @()

     for ( $pos = 0; $pos -lt $maxLast5Count; $pos++ ) {
          $maxWidthAtPos = 0
          foreach ( $row in $tableData ) {
               if ( $pos -lt $row.Last5.Count ) {
                    $valueLength = $row.Last5[$pos].ToString().Length
                    if ( $valueLength -gt $maxWidthAtPos ) {
                         $maxWidthAtPos = $valueLength
                    }
               }
          }
          $last5SubWidths += $maxWidthAtPos
     }

     # Calculate total Last5 width: sum of all sub-widths plus separators
     if ( $last5SubWidths.Count -gt 0 ) {
          $totalLast5Width = ($last5SubWidths | Measure-Object -Sum).Sum + (($last5SubWidths.Count - 1) * 3) # 3 chars for " | "
          $widths.Last5 = $totalLast5Width + 2
     } else {
          $widths.Last5 = $headers.Last5.Length + 2
     }

     # Ensure minimum widths for headers
     $headers = @{
          CounterName    = "Counter Name"
          Unit           = "Unit"
          Current        = "Current"
          Last5          = "Last 5 Values"
          Min            = "Min"
          Max            = "Max"
          Avg            = "Avg"
     }

     foreach ( $key in $headers.Keys ) {
          if ( $widths[$key] -lt ($headers[$key].Length + 2) ) {
               $widths[$key] = $headers[$key].Length + 2
          }
     }

     # Helper function to get color for value
     function Get-ValueColor {
          param($value, $colorMap)

          if ([string]::IsNullOrEmpty($value) -or $value -eq "-") {
               return "White"
          }

          $numericValue = 0
          if (![int]::TryParse($value, [ref]$numericValue)) {
               return "White"
          }

          $colorMapOrdered = [ordered]@{}
          $colorMap.Keys | Sort-Object | ForEach-Object {
               $colorMapOrdered.add($_, $colorMap[$_])
          }

          $color = for ( $b = 0; $b -lt $colorMapOrdered.Count; $b++ ) {
               $bound = $colorMapOrdered.Keys[$b]
               if ( $value -lt $bound ) {
                    $colorMapOrdered[$b]
                    break
               }
          }

          if ( [string]::IsNullOrEmpty($color) ) {
               $color = $colorMapOrdered[-1]
          }

          return $color
     }

     # Print header
     $headerLine = " {0} | {1} | {2} | {3} | {4} | {5} | {6} " -f `
          $headers.CounterName.PadRight($widths.CounterName - 2), `
          $headers.Unit.PadRight($widths.Unit - 2), `
          $headers.Current.PadRight($widths.Current - 2), `
          $headers.Last5.PadRight($widths.Last5 - 2), `
          $headers.Min.PadRight($widths.Min - 2), `
          $headers.Max.PadRight($widths.Max - 2), `
          $headers.Avg.PadRight($widths.Avg - 2)

     Write-Host $headerLine -ForegroundColor Cyan

     # Print separator line
     $separatorLine = "-" * $headerLine.Length
     Write-Host $separatorLine -ForegroundColor Gray

     # Print data rows
     foreach ( $row in $tableData ) {
          $currentColor  = Get-ValueColor -value $row.Current    -colorMap $row.ColorMap
          $minColor      = Get-ValueColor -value $row.Min        -colorMap $row.ColorMap
          $maxColor      = Get-ValueColor -value $row.Max        -colorMap $row.ColorMap
          $avgColor      = Get-ValueColor -value $row.Avg        -colorMap $row.ColorMap

          # Format Last5 values with colors
          $last5Formatted = ""
          if ( $row.Last5.Count -gt 0 ) {
               $last5Parts = @()
               foreach ( $value in $row.Last5) {
                    $last5Parts += $value
               }
               $last5Formatted = ($last5Parts -join " | ")
          } else {
               $last5Formatted = "-"
          }

          # Print row parts
          Write-Host -NoNewline (" {0} | " -f $row.CounterName.PadRight($widths.CounterName - 2)) -ForegroundColor White
          Write-Host -NoNewline ("{0} | " -f $row.Unit.PadRight($widths.Unit - 2)) -ForegroundColor White
          Write-Host -NoNewline ("{0} " -f $row.Current.ToString().PadRight($widths.Current - 2)) -ForegroundColor $currentColor
          Write-Host -NoNewline "| " -ForegroundColor White

          # Handle Last5 with individual colors
          if ( $row.Last5.Count -gt 0 ) {
               # Print Last5 values with individual coloring and proper sub-column widths
               for ( $i = 0; $i -lt $row.Last5.Count; $i++ ) {
                    $value = $row.Last5[$i]
                    $color = Get-ValueColor -value $value -colorMap $row.ColorMap

                    if ( $i -gt 0 ) {
                         Write-Host -NoNewline " | " -ForegroundColor White
                    }

                    # Pad value to its sub-column width
                    $paddedValue = $value.ToString().PadRight($last5SubWidths[$i])
                    Write-Host -NoNewline $paddedValue -ForegroundColor $color
               }

               # Calculate remaining space after all values and separators
               $usedSpace = ($last5SubWidths | Measure-Object -Sum).Sum + (($row.Last5.Count - 1) * 3)
               $remainingSpace = ($widths.Last5 - 2) - $usedSpace

               if ( $remainingSpace -gt 0 ) {
                    Write-Host -NoNewline (" " * $remainingSpace) -ForegroundColor White
               }

               Write-Host -NoNewline " | " -ForegroundColor White

          } else {

               Write-Host -NoNewline ("{0} | " -f "-".PadRight($widths.Last5 - 2)) -ForegroundColor White

          }          Write-Host -NoNewline ("{0} " -f $row.Min.ToString().PadRight($widths.Min - 2)) -ForegroundColor $minColor
          Write-Host -NoNewline "| " -ForegroundColor White
          Write-Host -NoNewline ("{0} " -f $row.Max.ToString().PadRight($widths.Max - 2)) -ForegroundColor $maxColor
          Write-Host -NoNewline "| " -ForegroundColor White
          Write-Host ("{0} " -f $row.Avg.ToString().PadRight($widths.Avg - 2)) -ForegroundColor $avgColor
     }

     Write-Host ""

}