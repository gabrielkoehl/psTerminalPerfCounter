# psTerminalPerfCounter

![Monitoring Example](docs/src/example_memory.png)

A PowerShell module for creating and using predefined performance counter configurations with real-time terminal-based visualization. This module addresses the challenge of efficiently monitoring system performance by providing ready-to-use presets tailored to specific requirements.

Initiated from my role as SQL Server consultant since I always want to use what's available, namely PowerShell

<div align="center">
<img src="docs/src/logo.png" alt="Alt Text" style="width: 30%;">

[-- BLOG -- ](https://dbavonnebenan.de)
</div>



## Documentation

- **[Start-tpcMonitor](docs/en-US/Start-tpcMonitor.md)** - Main monitoring function with real-time display
- **[Get-tpcAvailableCounterConfig](docs/en-US/Get-tpcAvailableCounterConfig.md)** - List available configuration templates
- **[Get-tpcPerformanceCounterInfo](docs/en-US/Get-tpcPerformanceCounterInfo.md)** - Get detailed information about performance counters
- **[Counter Configuration Guide](docs/en-US/CounterConfiguration.md)** - Guide for creating and customizing JSON configurations
- **[Development Status](docs/en-US/DevelopmentStatus.md)** - Whats next?



## Key Features

### Language-Independent Counter IDs

This module uses performance counter IDs, which is very helpful if you administer various systems. This approach was inspired from [PowerShell.One](https://powershell.one/tricks/performance/performance-counters) and ensures configurations work consistently across different Windows locales.

### Integrated Graphical Engine ( As far as one can call it that )

The module includes an updated graphical engine based on [PSConsoleGraph](https://github.com/PrateekKumarSingh/PSConsoleGraph). Some pull requests have been integrated and refined to provide stable terminal-based visualization capabilities.

### Configuration-Driven Monitoring

JSON-based configuration files define:

- Performance counters to monitor
- Display formats (graph, table, or both)
- Color mapping based on thresholds
- Update intervals and data retention
- Statistical calculations

You can configure any combination of performance counters that your system provides

## Installation

```powershell

# Install module
Install-Module -Name psTerminalPerfCounter -AllowPrerelease

# Install required dependencies if automatic fails
Install-Module GripDevJsonSchemaValidator

# Import the module
Import-Module psTerminalPerfCounter

```

## Quick Start

### Basic CPU Monitoring

```powershell
# Start CPU monitoring with default settings
Start-tpcMonitor

# Monitor with custom update interval
Start-tpcMonitor -ConfigName "Cpu" -UpdateInterval 2
```

### Memory Monitoring

```powershell
# Monitor memory performance
Start-tpcMonitor -ConfigName "Memory" -MaxDataPoints 200

# Extended memory monitoring for leak investigation
Start-tpcMonitor -ConfigName "Memory" -UpdateInterval 2 -MaxDataPoints 300
```

### Disk Performance

```powershell
# Monitor disk I/O with extended data retention
Start-tpcMonitor -ConfigName "Disk" -UpdateInterval 1 -MaxDataPoints 150

# Detailed disk monitoring for I/O bottlenecks
Start-tpcMonitor -ConfigName "Disk" -UpdateInterval 1 -MaxDataPoints 200
```


## Available Commands

| Command | Description |
|---------|-------------|
| `Start-tpcMonitor` | Main monitoring function with real-time display |
| `Get-tpcAvailableCounterConfig` | List available configuration templates |
| `Get-tpcPerformanceCounterInfo` | Get detailed information about performance counters |

## Configuration Templates

The module includes currently 3 predefined templates for common monitoring scenarios:

- **CPU** (`tpc_CPU.json`): Processor utilization and queue length monitoring
- **Memory** (`tpc_Memory.json`): Memory usage, page faults, and virtual memory statistics
- **Disk** (`tpc_Disk.json`): Disk I/O, queue length, and transfer rates

Each template includes:

- Performance counter definitions with IDs
- Display configuration (graphs, tables, colors)
- Threshold-based color mapping
- Statistical analysis settings

## Example Output

![Monitoring Example](docs/src/example_cpu.png)

*Example of real-time CPU monitoring with graphical display*

## Configuration Structure

```json
{
    "name": "CPU Performance",
    "description": "CPU utilization and queue monitoring",
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

### Configuration Properties

- **conversionFactor**: Factor used to convert raw counter values (e.g., 1024 for bytes to KB conversion)
- **conversionExponent**: Exponent applied during conversion calculations
- **type**: Data type - "Number" for absolute values, "Percentage" for percentage values
- **format**: Display format - "both" (graph and table), "table" only, or "graph" only
- **counterID**: Language-independent performance counter ID (format: "set-counter")
- **colorMap**: Threshold-based color mapping for visual alerts
- **Samples**: Number of data points to display in graphs
- **yAxisStep**: Step size for Y-axis scale values
- **yAxisMaxRows**: Maximum rows for Y-axis display



## Acknowledgments

Special thanks to:

- [PowerShell.One](https://powershell.one/tricks/performance/performance-counters) for the excellent research on performance counter IDs and locale-independent monitoring techniques
- [Prateek Singh](https://github.com/PrateekKumarSingh/PSConsoleGraph) for the foundational graphical engine that powers the terminal visualization


## License

This project is licensed under the MIT License. See the `LICENSE` file for details.

The integrated graphical engine is based on PSConsoleGraph, also under MIT License.

## Contributing

Contributions are welcome! Please feel free to submit issues, feature requests, or pull requests.