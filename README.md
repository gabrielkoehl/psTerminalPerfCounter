# psTerminalPerfCounter


<br>
<div align="center">

<img src="docs/en-US/src/example_memory.png" alt="Alt Text" style="width: 50%;">

</div>
<br>
A PowerShell module for creating and using predefined performance counter configurations with real-time terminal-based visualization. This module addresses the challenge of efficiently monitoring system performance by providing ready-to-use presets tailored to specific requirements. It also currently supports remote server checks.

With version 0.3.0, the module now supports full remote monitoring for multiple servers simultaneously using "Environment" configurations! It also introduces a new batched query engine for high performance.

**Requirement:** PowerShell 7.4 or newer is required.

<div align="center">
<img src="docs/en-US/src/logo.png" alt="Alt Text" style="width: 20%;">
<br>
<a href="https://dbavonnebenan.de" style="font-size:1.2em;">-- dbavonnebenan.de --</a>
</div>

## Key Features

### Simultaneous monitoring of performance counter sets across multiple servers with a single config

-- PICTURE --

### Language-Independent Counter IDs

This module utilizes numerical Performance Counter IDs instead of localized names. By dynamically retrieving the counter mapping directly from the local Windows Registry, this approach ensures that configurations remain valid and consistent across different Windows locales and language versions.

### Integrated Graphical Engine ( As far as one can call it that )

Initially, the graphical capabilities (powered by [PSConsoleGraph](https://github.com/PrateekKumarSingh/PSConsoleGraph)) were the driving force behind this module. While still beautiful and effective for individual servers, visualizing complex environments pushed the engine to its limits.

As a result, I have shifted the focus towards robust Console Table outputs for daily administration of multiple systems. Looking ahead, I plan to leverage PSWriteHTML for generating visual reports.

### Configuration-Driven Monitoring

JSON-based configuration files define:

- Performance counters to monitor
- Display formats (graph, table, or both)
- Color mapping based on thresholds
- Update intervals and data retention
- Statistical calculations

You can configure any combination of performance counters that your system provides

## Documentation

- **[Start-tpcMonitor](docs/en-US/Start-tpcMonitor.md)** - Main monitoring function for single servers
- **[Start-tpcEnvironmentMonitor](docs/en-US/Start-tpcEnvironmentMonitor.md)** - Main monitoring function for whoe environments
- **[Get-tpcConfigPaths](docs/en-US/Get-tpcConfigPaths.md)** - List configured pathes containing configurations
- **[Add-tpcConfigPath](docs/en-US/Add-tpcConfigPath.md)** - Adds custom path contianing configurations
- **[Remove-tpcConfigPath](docs/en-US/Remove-tpcConfigPath.md)** - Removes custom pathes
- **[Get-tpcAvailableCounterConfig](docs/en-US/Get-tpcAvailableCounterConfig.md)** - shows all available confiogurations from all pathes
- **[Get-tpcPerformanceCounterInfo](docs/en-US/Get-tpcPerformanceCounterInfo.md)** - shows detailed information about performance counters

- **[Building Custom Configuration Sets](docs/en-US/Building_Custom_ConfigurationSets.md)** - How to create custom configurations including Environments
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
Start-tpcMonitor -ConfigName "Memory"

# Extended memory monitoring for leak investigation
Start-tpcMonitor -ConfigName "Memory" -UpdateInterval 2
```

### Disk Performance

```powershell
# Monitor disk I/O with extended data retention
Start-tpcMonitor -ConfigName "Disk" -UpdateInterval 1 -MaxDataPoints 150
```

## Available Commands

| Command | Description |
|---------|-------------|
| `Start-tpcMonitor` | Main monitoring function with real-time display |
| `Start-tpcEnvironmentMonitor` | Monitor multiple servers simultaneously (Environment) |
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

For detailed information on creating custom JSON configuration files, see the [Building Custom Configuration Sets Guide](docs/en-US/Building_Custom_ConfigurationSets.md). The guide covers:

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