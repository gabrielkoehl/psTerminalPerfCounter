# Counter Configuration

Counter configuration for the psTerminalPerfCounter module using JSON files with the tpc_ prefix. Configuration changes are made through text editor only.

## Configuration File Requirements

All configuration files must:
- Be located in the Config folder
- Start with the prefix `tpc_` (e.g., `tpc_CPU.json`, `tpc_Memory.json`)
- Follow the JSON structure defined below

## System Overview

### Counter Types
- **Percentage**: For percentage-based counters (0-100%), uses 10% Y-axis steps by default
- **Number**: For numeric counters, uses 1 unit Y-axis steps by default

### Display Formats
- **graph**: graph display with optional statistics (default)
- **table**: Tabular display showing counter name, unit, current value, last 5 values, min, max, and average
- **both**: Shows graph first, then includes the counter in a combined table at the end

When multiple counters use "table" format, they are displayed together in a single table with dynamic column width.

### Available Colors
Red, Yellow, Green, Blue, Cyan, Magenta, White, Gray, Black, DarkRed, DarkYellow, DarkGreen, DarkBlue, DarkCyan, DarkMagenta, DarkGray

## Usage

### JSON Configuration Structure

Each configuration file follows this structure:

```json
{
    "name": "Configuration Name",
    "description": "Configuration description",
    "counters": [
        {
            "title": "Counter Display Name",
            "unit": "Unit (%, MB, MB/sec, etc.)",
            "conversionFactor": 1024,
            "conversionExponent": 3,
            "type": "Percentage|Number",
            "format": "graph|table|both",
            "counterID": "SetID-PathID",
            "counterSetType": "SingleInstance|MultiInstance",
            "counterInstance": "_Total|InstanceName|\"\"",
            "colorMap": {
                "80": "Red",
                "60": "Yellow",
                "0": "Green"
            },
            "graphConfiguration": {
                "samples": 80,
                "graphType": "Bar|Line|Scatter",
                "showStatistics": true,
                "yAxisStep": 10,
                "yAxisMaxRows": 10,
                "colors": {
                    "title": "Cyan",
                    "statistics": "Gray",
                    "default": "White"
                }
            }
        }
    ]
}
```

## Configuration Properties

### Counter Properties

- **title**: Display name for the counter
- **unit**: Unit of measurement
- **conversionFactor**: Integer factor for value conversion (minimum: 1, e.g., 1024 for Byte to KB conversion)
- **conversionExponent**: Integer exponent for conversion calculation (minimum: 1, e.g., 3 for Byte to GB conversion)
- **type**: "Percentage" or "Number"
- **format**: "graph", "table", or "both"
- **counterID**: Language-independent counter ID in format "SetID-PathID"
- **counterSetType**: "SingleInstance" or "MultiInstance"
- **counterInstance**: Instance name (e.g., "_Total", "C:", or "" for SingleInstance)
- **colorMap**: Value-based color thresholds
- **graphConfiguration**: Graph display settings

### Graph Configuration

- **samples**: Graph width (minimum: 70, typical: 80-120, values <70 set to 70 without further notification)
- **graphType**: "Bar", "Line", or "Scatter"
- **showStatistics**: Show/hide statistics below graph
- **yAxisStep**: Y-axis step size (overrides automatic calculation)
- **yAxisMaxRows**: Maximum Y-axis rows (minimum: 10, values <10 set to 10 without further notification). Useful for capping yAxis to avoid extreme large chars when already known that everything greater than X is critical
- **colors**: Title, statistics, and default colors


### Counter ID System

Counter IDs use format "SetID-PathID" (e.g., "238-6"):

- **SetID**: Performance counter set ID
- **PathID**: Counter path ID within the set

Use `Get-tpcPerformanceCounterInfo` to find counter IDs:

```powershell
Get-tpcPerformanceCounterInfo -SearchTerm "Processor"
Get-tpcPerformanceCounterInfo -SearchTerm "238-6"
```

### Color Map Structure

Color maps define thresholds and colors:

```json
"colorMap": {
    "80": "Red",      // Values <= 80 are red
    "60": "Yellow",   // Values <= 60 are yellow
    "30": "Green"      // Values <= 30 are green
}
```

Values above highest bound are red in this case

## Validation

### Schema Validation

JSON configurations are validated against `schema.json` with these constraints:

- **samples**: Integer ≥ 70
- **graphType**: "Bar", "Line", or "Scatter"
- **showStatistics**: Boolean
- **yAxisStep**: Number ≥ 1
- **yAxisMaxRows**: Integer ≥ 10
- **conversionFactor**: Integer ≥ 1
- **conversionExponent**: Integer ≥ 1
- **counterID**: Pattern "\\d+-\\d+"
- **counterSetType**: "SingleInstance" or "MultiInstance"
- **type**: "Number" or "Percentage"
- **format**: "both", "table", or "graph"

Validation requires the `GripDevJsonSchemaValidator` module.

### Runtime Validation

Counters are tested for availability before monitoring starts.

## Examples

### Basic Usage
```powershell
Start-tpcMonitor -ConfigName CPU
```

## Y-Axis Configuration

Y-axis steps are automatically determined by counter type:
- **Percentage**: 10% steps (0%, 10%, 20%, ..., 100%)
- **Number**: 1 unit steps (0, 1, 2, 3, ...)

Override automatic calculation with `yAxisStep`:
```json
"graphConfiguration": {
    "yAxisStep": 500
}
```

## Available Default Configurations

### tpc_CPU.json
- Processor Time (%) - Counter ID: 238-6, MultiInstance, Bar graph
- Processor Queue Length (Threads) - Counter ID: 2-44, SingleInstance, table

### tpc_Memory.json
- Available Memory (MB) - Counter ID: 4-1382, SingleInstance, Bar graph
- Memory Committed Bytes (%) - Counter ID: 4-1406, SingleInstance, Bar graph

### tpc_Disk.json
- Disk I/O counters automatically converted from Bytes/sec to MB/sec
- Values divided by 1MB (1048576) at runtime

## Special Configurations

### Auto-Conversion Function

The module supports automatic value conversion using `conversionFactor` and `conversionExponent` for individual counter value transformations:

**Formula**: `convertedValue = originalValue / (conversionFactor ^ conversionExponent)`

**Common Use Cases**:
- **Bytes to KB**: `conversionFactor: 1024, conversionExponent: 1`
- **Bytes to MB**: `conversionFactor: 1024, conversionExponent: 2`
- **Bytes to GB**: `conversionFactor: 1024, conversionExponent: 3`
- **Custom scaling**: Any integer factor and exponent ≥ 1

**Requirements**:
- Both `conversionFactor` and `conversionExponent` must be integers ≥ 1
- The `unit` field must be manually set to reflect the converted unit (e.g., "GB", "MB")
- Values are converted at runtime before display

**Example - Converting Bytes to GB**:
```json
{
    "title": "Memory Usage",
    "unit": "GB",
    "conversionFactor": 1024,
    "conversionExponent": 3,
    "type": "Number",
    "counterID": "4-1234"
}
```

### Counter Instance Types

- **_Total**: Aggregate of all instances
- **Specific Instance**: Named instance (e.g., "C:", "Ethernet")
- **Wildcard (*)**: NOT ALLOWED

### Language Independence

Uses numeric counter IDs instead of localized names for cross-language compatibility.

## Creating Custom Configurations

1. **Find Counter IDs**: `Get-tpcPerformanceCounterInfo -SearchTerm "Counter Name"`
2. **Create JSON File**: Config folder with `tpc_` prefix
3. **Follow Schema**: Include all required properties
4. **Test**: `Get-tpcAvailableCounterConfig -testcounters`



### Finding Counter IDs

```powershell
# Search for network counters
Get-tpcPerformanceCounterInfo -SearchTerm "Network Interface"

# Search for specific counters
Get-tpcPerformanceCounterInfo -SearchTerm "Bytes sent/sec"
```
