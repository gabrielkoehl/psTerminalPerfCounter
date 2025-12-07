# Building Custom Configuration Sets

This guide explains how to create custom JSON configuration files for monitoring performance counters with the psTerminalPerfCounter module, including single-server counter configurations and multi-server environment sets.

## Overview

Configuration files define which performance counters to monitor and how to display them. They use language-independent counter IDs to ensure compatibility across different Windows locales. With version 0.3.0, you can also define "Environment" configurations to monitor multiple servers simultaneously.

## Prerequisites

- **GripDevJsonSchemaValidator** module installed (for validation)
- Understanding of Windows Performance Counters
- Access to `Get-tpcPerformanceCounterInfo` for discovering counter IDs

## Counter Configuration Files (Single Server)

Counter configuration files must:

- Be named with the prefix `tpc_` (e.g., `tpc_CustomMonitor.json`)
- Follow the JSON schema defined in `psTerminalPerfCounter\Config\schema_config.json`
- Be placed in a configured configuration path (see `Get-tpcConfigPaths` and `Add-tpcConfigPath`)

### Basic Template

```json
{
    "name": "Configuration Name",
    "description": "Description of what this configuration monitors",
    "counters": [
        {
            "title": "Counter Display Name",
            "unit": "Unit of Measurement",
            "conversionFactor": 1,
            "conversionExponent": 1,
            "type": "Number",
            "format": "both",
            "counterID": "SetID-PathID",
            "counterSetType": "SingleInstance",
            "counterInstance": "",
            "colorMap": {
                "threshold1": "Color1",
                "threshold2": "Color2"
            },
            "graphConfiguration": {
                "Samples": 70,
                "graphType": "Bar",
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

### Root Level Properties

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `name` | string | Yes | Name of the configuration |
| `description` | string | Yes | Description of what this configuration monitors |
| `counters` | array | Yes | Array of counter objects (minimum 1) |

### Counter Properties

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `title` | string | Yes | Display name for the performance counter |
| `unit` | string | Yes | Unit of measurement (e.g., "%", "MB", "KB/sec", "Threads") |
| `conversionFactor` | integer | Yes | Factor for converting raw values (min: 1). Use 1024 for byte to KB conversion |
| `conversionExponent` | integer | Yes | Exponent applied during conversion (min: 1). Usually 1 |
| `type` (deprecated) | string | Yes | Data type: `"Number"` for absolute values, `"Percentage"` for percentages |
| `format` | string | Yes | Display format: `"both"` (graph + table), `"table"`, or `"graph"` |
| `counterID` | string | Yes | Language-independent counter ID in format `"SetID-PathID"` (e.g., "238-6") |
| `counterSetType` | string | Yes | `"MultiInstance"` (multiple instances) or `"SingleInstance"` (single instance) |
| `counterInstance` | string | Yes | Instance name (e.g., "_Total") or empty string `""` for SingleInstance |
| `colorMap` | object | Yes | Threshold-based color mapping (see below) |
| `graphConfiguration` | object | Yes | Graph display settings (see below) |

### Color Map

The `colorMap` defines threshold-based coloring. Keys are numeric threshold values (as strings), values are color names.

**Important:** Thresholds are evaluated in descending order. The color is applied when the value is **greater than or equal** to the threshold.

**Example for high-is-bad metrics (CPU usage):**

```json
"colorMap": {
    "30": "Green",    // Values >= 30% are Green
    "70": "Yellow",   // Values >= 70% are Yellow
    "80": "Red"       // Values >= 80% are Red
}
```

**Example for low-is-bad metrics (Available Memory):**

```json
"colorMap": {
    "500": "Red",      // Values >= 500 MB are Red (critical low)
    "1000": "Yellow",  // Values >= 1000 MB are Yellow (warning)
    "999999": "Green"  // Values >= 999999 MB are Green (plenty available)
}
```

**Supported Colors:** White, Black, Gray, DarkGray, Red, DarkRed, Green, DarkGreen, Yellow, DarkYellow, Blue, DarkBlue, Magenta, DarkMagenta, Cyan, DarkCyan

### Graph Configuration

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `Samples` | integer | Yes | Number of data points to display (min: 70) |
| `graphType` | string | Yes | Graph type: `"Bar"`, `"Line"`, or `"Scatter"` |
| `showStatistics` | boolean | Yes | Whether to display statistics (min, max, average) |
| `yAxisStep` | number | Yes | Step size for Y-axis scale values (min: 1) |
| `yAxisMaxRows` | integer | Yes | Maximum rows for Y-axis display (min: 10) |
| `colors` | object | Yes | Color scheme with `title`, `statistics`, and `default` properties |

## Finding Counter IDs

Use the `Get-tpcPerformanceCounterInfo` function to discover counter IDs:

### Search by Counter Name

```powershell
# Find processor-related counters
Get-tpcPerformanceCounterInfo -SearchTerm "Processor"

# Find specific counter path
Get-tpcPerformanceCounterInfo -SearchTerm "% Processor Time"

# Find memory-related counters
Get-tpcPerformanceCounterInfo -SearchTerm "Memory"
```

### Validate a Counter ID

```powershell
# Verify a specific counter ID
Get-tpcPerformanceCounterInfo -SearchTerm "238-6"
```

The output includes:

- **ID**: Composite counter ID in format `"SetID-PathID"` (use this in `counterID`)
- **SetType**: `SingleInstance` or `MultiInstance` (use this in `counterSetType`)
- **Instances**: Available instances for MultiInstance counters (use in `counterInstance`)

## Step-by-Step Example

### 1. Identify the Counter

```powershell
Get-tpcPerformanceCounterInfo -SearchTerm "Processor Time"
```

**Output:**

```
ID      CounterSet   Path                    SetType        Instances
--      ----------   ----                    -------        ---------
238-6   Processor    % Processor Time        MultiInstance  _Total, 0, 1, 2, 3
```

### 2. Create Configuration File

Create `tpc_MyCustomCPU.json`:

```json
{
    "name": "Custom CPU Monitor",
    "description": "Focused CPU monitoring with custom thresholds",
    "counters": [
        {
            "title": "Processor Time",
            "unit": "%",
            "conversionFactor": 1,
            "conversionExponent": 1,
            "type": "Percentage",
            "format": "both",
            "counterID": "238-6",
            "counterSetType": "MultiInstance",
            "counterInstance": "_Total",
            "colorMap": {
                "30": "Green",
                "70": "Yellow",
                "80": "Red"
            },
            "graphConfiguration": {
                "Samples": 70,
                "graphType": "Bar",
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

### 3. Validate Configuration

```powershell
# Place file in a configured path
Get-tpcConfigPaths

# Validate the configuration
Get-tpcAvailableCounterConfig -Raw | Where-Object { $_.ConfigName -eq "MyCustomCPU" }
```

### 4. Test the Configuration

```powershell
# Test counter availability
Get-tpcAvailableCounterConfig -TestCounters | Where-Object { $_.ConfigName -eq "MyCustomCPU" }

# Run monitoring
Start-tpcMonitor -ConfigName "MyCustomCPU"
```

## Real-World Examples

### Example 1: Single Instance Counter (Memory)

```json
{
    "title": "Available Memory",
    "unit": "MB",
    "conversionFactor": 1,
    "conversionExponent": 1,
    "type": "Number",
    "format": "both",
    "counterID": "4-1382",
    "counterSetType": "SingleInstance",
    "counterInstance": "",
    "colorMap": {
        "500": "Red",
        "1000": "Yellow",
        "999999": "Green"
    },
    "graphConfiguration": {
        "Samples": 100,
        "graphType": "Bar",
        "showStatistics": true,
        "yAxisStep": 500,
        "yAxisMaxRows": 10,
        "colors": {
            "title": "Green",
            "statistics": "Gray",
            "default": "White"
        }
    }
}
```

### Example 2: Multi-Instance Counter with Conversion (Disk I/O)

```json
{
    "title": "Disk Read KB/sec",
    "unit": "KB/sec",
    "conversionFactor": 1024,
    "conversionExponent": 1,
    "type": "Number",
    "format": "both",
    "counterID": "234-220",
    "counterSetType": "MultiInstance",
    "counterInstance": "_Total",
    "colorMap": {
        "200": "Red",
        "500": "Yellow",
        "1000": "Green"
    },
    "graphConfiguration": {
        "Samples": 100,
        "graphType": "Line",
        "showStatistics": true,
        "yAxisStep": 200,
        "yAxisMaxRows": 10,
        "colors": {
            "title": "Blue",
            "statistics": "Gray",
            "default": "White"
        }
    }
}
```

**Note:** The counter returns bytes/sec, so `conversionFactor: 1024` converts to KB/sec.

### Example 3: Queue Length Counter

```json
{
    "title": "Processor Queue Length",
    "unit": "Threads",
    "conversionFactor": 1,
    "conversionExponent": 1,
    "type": "Number",
    "format": "both",
    "counterID": "2-44",
    "counterSetType": "SingleInstance",
    "counterInstance": "",
    "colorMap": {
        "1": "Green",
        "2": "Yellow",
        "5": "Red"
    },
    "graphConfiguration": {
        "Samples": 70,
        "graphType": "Bar",
        "showStatistics": true,
        "yAxisStep": 1,
        "yAxisMaxRows": 10,
        "colors": {
            "title": "Yellow",
            "statistics": "Gray",
            "default": "White"
        }
    }
}
```

## Environment Configuration (Multi-Server)

The Environment Monitor (`Start-tpcEnvironmentMonitor`) allows you to monitor multiple servers and their specific counters simultaneously.

### Environment File Structure

Environment files are JSON files that define a collection of servers and the counter configurations to run on each.

**Key Requirements:**

- Can be placed anywhere, but it's good practice to keep them in a dedicated folder (e.g., `_remoteconfigs`).
- Must adhere to the expected JSON structure.

### Environment Template

```json
{
    "name": "Production SQL Environment",
    "description": "Crucial SQL Server Instances",
    "interval": 2,
    "secretvaultname": "SecretStore",
    "credentialname": "integrated",
    "servers": [
        {
            "computername": "SQL-PROD-01",
            "comment": "Primary Node",
            "counterConfig": ["CPU", "Memory"]
        },
        {
            "computername": "SQL-PROD-02",
            "comment": "Secondary Node",
            "counterConfig": ["CPU"]
        },
        {
            "computername": "APP-SRV-01",
            "comment": "Application Server",
            "counterConfig": ["Disk"]
        }
    ]
}
```

**Note:** The `secretvaultname` and `credentialname` fields are optional and enable integration with PowerShell SecretStore for secure credential management. If omitted, the module will use the current user's credentials for remote connections.

### Environment Properties

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `name` | string | Yes | Name of the environment environment settings |
| `description` | string | Yes | Brief description of the environment |
| `interval` | integer | Yes | Default update interval in seconds (can be overridden at runtime) |
| `secretvaultname` | string | No | Name of the PowerShell SecretStore vault to use for credential retrieval (optional) |
| `credentialname` | string | No | Name of the credential stored in the SecretStore vault (optional, e.g., "integrated" for integrated Windows authentication) |
| `servers` | array | Yes | List of server objects to monitor |

### Server Object Properties

| Property | Type | Description |
|----------|------|-------------|
| `computername` | string | DNS name or IP of the target server |
| `comment` | string | Friendly description (e.g., role of the server) |
| `counterConfig` | array | List of **Counter Configuration Names** (e.g., "CPU", "Memory") to monitor on this server. These must match existing `tpc_*.json` configuration names. |

### Running the Environment Monitor

Once you have created your environment JSON file (e.g., `MyEnv.json`), start the monitor:

```powershell
# Using the included example configuration
Start-tpcEnvironmentMonitor -ConfigPath "src\psTerminalPerCounter\psTerminalPerfCounter\Config\ENV_SERVER_EXAMPLE.json"

# Using a custom environment configuration
Start-tpcEnvironmentMonitor -ConfigPath "C:\Configs\MyEnv.json"

# Override the interval from the JSON config
Start-tpcEnvironmentMonitor -ConfigPath "C:\Configs\MyEnv.json" -UpdateInterval 5
```

### Example Environment Configuration (ENV_SERVER_EXAMPLE.json)

The module includes a complete example environment configuration at `src\psTerminalPerCounter\psTerminalPerfCounter\Config\ENV_SERVER_EXAMPLE.json`:

```json
[
     {
          "name": "SQL_ENVIRONMENT_001",
          "description": "SQL Server Environment Production",
          "interval": 2,
          "secretvaultname": "SecretStore",
          "credentialname": "integrated",
          "servers": [
               {
                    "computername": "LAB-NODE2",
                    "comment": "Sql Server Node B Production",
                    "counterConfig": [
                         "CPU",
                         "DISK"
                    ]
               },
               {
                    "computername": "LAB-NODE1",
                    "comment": "Sql Server Node A Production",
                    "counterConfig": [
                         "CPU",
                         "DISK"
                    ]
               },
               {
                    "computername": "LAB-DC01",
                    "comment": "Domain Controller",
                    "counterConfig": [
                         "CPU",
                         "Memory"
                    ]
               },
               {
                    "computername": "LAB-NODE3",
                    "comment": "Sql Server Single Node Dev",
                    "counterConfig": [
                         "CPU",
                         "DISK",
                         "Memory"
                    ]
               }
          ]
     }
]
```

This example demonstrates:
- Multiple servers with different counter configurations
- SecretStore integration for credential management
- Mixed counter configurations per server (CPU, DISK, Memory)
- Descriptive comments for each server

## JSON Schema Validation

All configurations are validated against the schema located at:

```
psTerminalPerfCounter\Config\schema_config.json
```

**Important:** The schema file should not be modified as it ensures configuration compatibility with the module. The schema enforces:

- Required properties
- Data types
- Minimum values
- Allowed enumerations

If validation fails, `Get-tpcAvailableCounterConfig` will show detailed error messages including:

- Error description
- JSON path to the problematic field
- Line number in the configuration file

## Configuration Paths - Management

Configurations can be stored in multiple locations:

```powershell
# View configured paths
Get-tpcConfigPaths

# Add custom path
Add-tpcConfigPath -Path "C:\MyConfigs"

# Remove custom path
Remove-tpcConfigPath -Path "C:\MyConfigs"
```

The module searches all configured paths for files matching the pattern `tpc_*.json` (excluding templates).

## Best Practices

1. **Naming Convention**: Use descriptive names with the `tpc_` prefix (e.g., `tpc_SQLServer_Memory.json`)

2. **Template Files**: Files containing "template" in the basename are automatically excluded from loading

3. **Counter Instance Selection**:
   - Use `"_Total"` for aggregated metrics across all instances
   - Use specific instance names (e.g., `"0"`, `"C:"`) for individual monitoring
   - Leave empty `""` for SingleInstance counters

4. **Conversion Factors**:
   - Use `1` for no conversion
   - Use `1024` for bytes to KB
   - Use `1048576` (1024) for bytes to MB
   - Adjust `conversionExponent` if needed (usually `1`)

5. **Graph Configuration**:
   - Higher `Samples` values show more history but may slow rendering
   - Choose `graphType` based on data: `Bar` for discrete values, `Line` for trends
   - Adjust `yAxisStep` to match your metric scale

6. **Color Maps**:
   - Define at least 3 threshold levels (low, medium, high)
   - Ensure thresholds match the expected value range
   - Consider inverse thresholds for "low-is-bad" metrics

7. **Testing**:
   - Always test with `-TestCounters` before production use
   - Verify counter availability on target systems
   - Check that color thresholds make sense with actual values

## Troubleshooting

### Configuration Not Found

- Ensure filename starts with `tpc_`
- Verify file is in a configured path (`Get-tpcConfigPaths`)
- Check that filename doesn't contain "template"

### JSON Validation Errors

- Install `GripDevJsonSchemaValidator` module
- Review error messages from `Get-tpcAvailableCounterConfig`
- Compare with example configurations in `psTerminalPerfCounter\Config\`

### Counter Not Available

- Verify counter ID with `Get-tpcPerformanceCounterInfo`
- Check that counter exists on target system
- Ensure correct `counterSetType` and `counterInstance`
- Review `LastError` property from `Get-tpcAvailableCounterConfig -TestCounters`

### Display Issues

- Increase `yAxisMaxRows` for better vertical resolution
- Adjust `yAxisStep` to match value range
- Increase `Samples` for longer history (may impact performance)

## Reference Configurations

See the following configurations in `psTerminalPerfCounter\Config\` for complete examples:

- `tpc_CPU.json` - CPU monitoring with MultiInstance counters
- `tpc_Memory.json` - Memory monitoring with SingleInstance counters
- `tpc_Disk.json` - Disk I/O with conversion factors and Line graphs

## Related Commands

- **[Start-tpcEnvironmentMonitor](Start-tpcEnvironmentMonitor.md)** - Run multi-server environment monitors
- **[Start-tpcMonitor](Start-tpcMonitor.md)** - Use configurations
- **[Get-tpcPerformanceCounterInfo](Get-tpcPerformanceCounterInfo.md)** - Find counter IDs
- **[Get-tpcAvailableCounterConfig](Get-tpcAvailableCounterConfig.md)** - Validate configurations
- **[Get-tpcConfigPaths](Get-tpcConfigPaths.md)** - Manage configuration paths
- **[Add-tpcConfigPath](Add-tpcConfigPath.md)** - Add custom paths
