# psTerminalPerfCounter

Initiated from my role as SQL Server consultant since I always want to use what's available, namely PowerShell
<br>
<div align="center">

<img src="docs/en-US/src/example_memory.png" alt="Alt Text" style="width: 50%;">

</div>
<br>
A PowerShell module for creating and using predefined performance counter configurations with real-time terminal-based visualization. This module addresses the challenge of efficiently monitoring system performance by providing ready-to-use presets tailored to specific requirements. It also currently supports remote server checks.

From version 0.2.0 onward, there is already a lot of (commented out) code for monitoring multiple remote servers, but I introduced some hard‑to‑work‑around constraints due to my preference for classes, since classes cannot be streamed across sessions. Therefore, the 0.2.0 release focuses on completing bug fixes and QoL improvements.



<div align="center">
<img src="docs/en-US/src/logo.png" alt="Alt Text" style="width: 20%;">
<br>
<a href="https://dbavonnebenan.de" style="font-size:1.2em;">-- dbavonnebenan.de --</a>
</div>

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

## Documentation

- **[Start-tpcMonitor](docs/en-US/Start-tpcMonitor.md)** - Main monitoring function
- **[Get-tpcConfigPaths](docs/en-US/Get-tpcConfigPaths.md)** - List configured pathes containing configurations
- **[Add-tpcConfigPath](docs/en-US/Add-tpcConfigPath.md)** - Adds custom path contianing configurations
- **[Remove-tpcConfigPath](docs/en-US/Remove-tpcConfigPath.md)** - Removes custom pathes
- **[Get-tpcAvailableCounterConfig](docs/en-US/Get-tpcAvailableCounterConfig.md)** - shows all available confiogurations from all pathes
- **[Get-tpcPerformanceCounterInfo](docs/en-US/Get-tpcPerformanceCounterInfo.md)** - shows detailed information about performance counters

- **[Building Custom Configs](docs/en-US/Building_Custom_Configs.md)** - How to create custom configurations
- **[DevelopmentStatus](DevelopmentStatus.md)** - Whats next?

## Installation

```powershell

# Install module
Install-Module -Name psTerminalPerfCounter

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

<br>
<div align="center">
<img src="docs/en-US/src/example_cpu.png" alt="Alt Text" style="width: 50%;">

*Example of real-time CPU monitoring with graphical display*
</div>

## Creating Custom Configurations

For detailed information on creating custom JSON configuration files, see the [Building Custom Configs Guide](docs/en-US/Building_Custom_Configs.md). The guide covers:

- Configuration file structure and naming conventions
- Finding counter IDs with `Get-tpcPerformanceCounterInfo`
- Step-by-step configuration creation
- Real-world examples (CPU, Memory, Disk)
- JSON schema validation
- Best practices and troubleshooting

Quick example:

```powershell
# Find counter IDs
Get-tpcPerformanceCounterInfo -SearchTerm "Processor Time"

# Create tpc_MyConfig.json in a configured path
# See docs/en-US/Building_Custom_Configs.md for complete templates

# Validate configuration
Get-tpcAvailableCounterConfig -TestCounters
```

## Acknowledgments

Special thanks to:

- [Prateek Singh](https://github.com/PrateekKumarSingh/PSConsoleGraph) for the foundational graphical engine that powers the terminal visualization

## License

This project is licensed under the MIT License. See the `LICENSE` file for details.

The integrated graphical engine is based on PSConsoleGraph, also under MIT License.

## Contributing

Contributions are welcome! Please feel free to submit issues, feature requests, or pull requests.