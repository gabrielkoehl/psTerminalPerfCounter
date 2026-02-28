<br>
<div align="center">
    <img src="src\psTerminalPerfCounter\docs\en-US\src\perfcounter_logofull.png" alt="Alt Text" style="width: 20%;">
</div>

A PowerShell module for creating and using predefined performance counter configurations with real-time terminal-based visualization. This module addresses the challenge of efficiently monitoring system performance by providing ready-to-use presets tailored to specific requirements.

**Requirement:** PowerShell 7.4

## 0.3.1 Release Info

This is just a small patch version bump – no new features, nothing groundbreaking. But the amount of work was enormous, which I think the [CHANGELOG.MD](CHANGELOG.MD) speaks for itself. The last few months were all about features and functionality, and the technical debt had piled up. On top of that, the rebuild of the core classes in C# marked the point where I started using the module productively – with the result: lots of bugs and abysmal usability. Accordingly, a lot has been simplified, especially the creation of custom counter configurations. But the bulk of it was simply technical debt and bugs. I wanted to get all of this out of the way before the next big step...

...which is finally the export of entire time series for historization or visualization with PSWriteHTML <3. That will be the next minor release.

## Key Features

### Simultaneous monitoring of performance counter sets across multiple servers with a single config, including whole environments

The Environment Monitor feature allows you to monitor multiple servers simultaneously using a single JSON configuration file. Each server can have different counter configurations, and all data is collected in parallel for maximum performance.

<br>
<div align="center">

<img src="src/psTerminalPerfCounter/docs/en-US/src/example_environment.png" alt="Alt Text" style="width: 100%;">

</div>
<br>

### Language-Independent Counter IDs

The fact that Windows doesn't ship with default presets is bad enough – but the language-dependent counter names make it even worse.

This module utilizes numerical Performance Counter IDs instead of localized names. By dynamically retrieving the counter mapping directly from the local Windows Registry, this approach ensures that configurations remain valid and consistent across different Windows locales and language versions.

### Integrated Graphical Engine (as far as one can call it that)

Initially, the graphical capabilities (powered by [PSConsoleGraph](https://github.com/PrateekKumarSingh/PSConsoleGraph)) were the driving force behind this module. While still beautiful and effective for individual servers, visualizing complex environments pushed the engine to its limits.

As a result, I have shifted the focus towards robust Console Table outputs for daily administration of multiple systems. Looking ahead, I plan to leverage PSWriteHTML for generating visual reports.

### Configuration-Driven Monitoring

JSON-based configuration files define:

- Performance counters to monitor
- Display formats (graph, table, or both)
- Color mapping based on thresholds
- Update intervals and data retention
- Statistical calculations

You can configure any combination of performance counters that your system provides, greatly simplified with mandatory and optional default values.

## Installation

```powershell

# Install module
Install-Module -Name psTerminalPerfCounter

# Import the module
Import-Module psTerminalPerfCounter

```

## Quick Start with Default Configs

I've deleted all previous documentation since it was useless. Things change constantly at this stage and the docs were, thanks to AI, way too much. If you've made it this far you can use Get-Help and just try things out :)

### Single Server Monitoring

See [tpc_CPU.json](src\psTerminalPerfCounter\psTerminalPerfCounter\Config\tpc_CPU.json) for details of the used configuration.

```powershell
# Load config for localhost
Start-tpcMonitor -ConfigName "CPU"
```

```powershell
# Load config for remote host 'LAB/NODE1' with integrated security
Start-tpcMonitor -ConfigName "CPU" -ComputerName 'Lab-NODE1'
```

```powershell
# Load config for remote host 'LAB/NODE1' with different credentials (but AD)
Start-tpcMonitor -ConfigName "CPU" -ComputerName 'Lab-NODE1' -Credential $(Get-Credential)
```

### Environment Monitoring

See [ENV_SERVER_EXAMPLE.json](example_configs\ENV_SERVER_EXAMPLE.json) for the used environment config. Everything is configured in this environment file.

```powershell
 Start-tpcEnvironmentMonitor -EnvConfigPath "example_configs\ENV_SERVER_EXAMPLE.json"
```

**Credential Management:** (under construction)
* Environment configurations support integration with PowerShell SecretStore for secure credential management. Use the `secretvaultname` and `credentialname` fields in your environment JSON to specify stored credentials for remote server access. Currently PowerShell SecretVault and connector is tested.

### Analysing Performance Counters (needed for building your own sets)

```powershell
# Find counter with composite ID translation and available instances (can take a while with less selective wildcards)
Get-tpcPerformanceCounterInfo -SearchTerm 'Network Interface'
```

```powershell
# Translate composite ID to counter path with all counter information
Get-tpcPerformanceCounterInfo -SearchTerm '1820-544'
```

```powershell
<#
    Find counter with composite ID translation and available instances on a remote machine.
    This is very important when building configs, since the configurations reside on the
    executing server using IDs that are translated at runtime. Besides the counter path (name),
    you can also analyse the available instances for multi-instance counters here.
#>
Get-tpcPerformanceCounterInfo -SearchTerm 'Network Interface' -ComputerName 'LAB-NODE1'
```
<br>
<div align="center">
    <img src="src\psTerminalPerfCounter\docs\en-US\src\example_getcounter.png" alt="Alt Text" style="width: 80%;">
</div>
<br>

```powershell
# Add custom configuration paths – you don't want to lose your custom configs with an update :P (a user-scoped environment variable TPC_CONFIGPATH is set)
Add-tpcConfigPath 'C:\Temp'
```

```powershell
# List custom configuration paths
Get-tpcConfigPaths
```

```powershell
# Remove custom configuration path
Remove-tpcConfigPath
```

### Validating Configurations

```powershell
# Validate all configurations in all registered configuration paths and list parameters
Test-tpcAvailableCounterConfig
```

```powershell
# Validate a single configuration file and list parameters
Test-tpcAvailableCounterConfig -configFilePath 'src\psTerminalPerfCounter\psTerminalPerfCounter\Config\tpc_Disk.json'
```

## Documentation

- **[Start-tpcMonitor](src/psTerminalPerfCounter/docs/en-US/Start-tpcMonitor.md)** - Main monitoring function for single servers
- **[Start-tpcEnvironmentMonitor](src/psTerminalPerfCounter/docs/en-US/Start-tpcEnvironmentMonitor.md)** - Main monitoring function for whole environments
- **[Get-tpcConfigPaths](src/psTerminalPerfCounter/docs/en-US/Get-tpcConfigPaths.md)** - List configured paths containing configurations
- **[Add-tpcConfigPath](src/psTerminalPerfCounter/docs/en-US/Add-tpcConfigPath.md)** - Add custom path containing configurations
- **[Remove-tpcConfigPath](src/psTerminalPerfCounter/docs/en-US/Remove-tpcConfigPath.md)** - Remove custom paths
- **[Test-tpcAvailableCounterConfig](src/psTerminalPerfCounter/docs/en-US/Test-tpcAvailableCounterConfig.md)** - Show all available configurations from all paths
- **[Get-tpcPerformanceCounterInfo](src/psTerminalPerfCounter/docs/en-US/Get-tpcPerformanceCounterInfo.md)** - Show detailed information about performance counters

## Acknowledgments

Special thanks to:

- [Prateek Singh](https://github.com/PrateekKumarSingh/PSConsoleGraph) for the foundational graphical engine that powers the terminal visualization with a lot of customization options

## License

This project is licensed under the MIT License. See the `LICENSE` file for details.

The integrated graphical engine is based on PSConsoleGraph, also under MIT License.

## Contributing

Contributions are welcome! Please feel free to submit issues, feature requests, or pull requests.

<br>
<div align="center">
<a href="https://dbavonnebenan.de">
<img src="src/psTerminalPerfCounter/docs/en-US/src/logo.png" alt="Alt Text" style="width: 20%;">
</a>
</div>