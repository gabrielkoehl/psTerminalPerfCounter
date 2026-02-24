# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [-]

### Added

* CounterConfiguration (JSON)
  * unit conversion now supports configurable scaling operations by new parameter `conversionType` (multiply "M" / divide "D")
  * `MultiInstanceCounter` now requires only a single configuration; instances are automatically cloned based on the specified instance names
  * new configuration parameter `decimalPlaces` to specify the number of fractional digits for counter values
* Get-tpcPerformanceCounterInfo
  * added remoting capability

### Changed

* JSON Configs simplified. Optional style and customization parameters are outsourced to `default_template_values.json` and merged at runtime when missing. Only include mandatory and optional parameters you want to customize.

### Deprecated

### Removed

### Fixed

* Get-PerformanceCounterLookup
  * improved / fixed remoting (some functions were local, some remote,
    would crash with different system languages)
  * credential passing improved
* start-tpcMonitor
  * accepts `-ConfigPath` paramter now when remoting
  * improved / fixed remoting (some functions were local, some remote,
    would crash with different system languages)
* Get-tpcAvailableCounterConfig
  * missed changes for CounterClass Rebuild
* Show-CounterTable
  * fixed bug with conversion int -> double, when counter returns doubles -> skipped colormap
  * seperator current value not colored anymore
* several internal function calls, parameters, logic

### Security

### Code Quality

* Refactoring, removing old code base

### Known Issues



## [0.3.0] 2025-12-07

### Added

### Changed

* **Ported all classes to C#**
  * I discovered significant limitations in PowerShell classes that were showstoppers. Consequently, I decided to take the difficult path and rewrote half of the codebase.
  * Requires PowerShell 7.4 or newer

* **Counter Translation ID <> NAME**
  * Removed DLL-based lookups to drastically improve remote startup speed and fixed ID resolution for multi-instance SQL counters.

* **General Remote Call Performance**
  * **Batched Remote Queries**
    * Switched from sequential, single-counter queries to efficient batched approach. All counters for a specific server are now retrieved in a single remote call. Get-Counter can process lists, not only on path :P
  * **Stabilized Update Interval**
    * faster and more reliable. Execution time for environment monitoring dropped from >15s to ~2s.
  * **Refactored Core Logic**
    * Moved the data collection into a C# static method (GetValuesBatched) to leverage parallel processing and reduce PowerShell overhead.

### Deprecated

### Removed

### Fixed

### Security

### Code Quality

### Known Issues

* First pipe char in last 5 value table has ColorMap color instead of default

* **Wrong datat point movement in table**
  * Datapoints moving in table from right to lefft ( last 5 )

* **Bitdefender False-Positive**
  * PowerShell tried to load a malicious resource detected as CMD:Heur.BZC.ZFV.Boxter.602.098EEC9F and was blocked.

## [0.2.0] - 2025-10-11

### Added

* **Remoting**: Added capability for monitoring single remote server
  * `Start-TpcMonitor -ComputerName <COMPUTERNAME> -ConfigName <CONFIGNAME> -Credential <NULL|CredentialObject>`: Enables ad-hoc monitoring of remote servers using either integrated security or provided credentials

* **Configuration path management**: Added functions to manage custom configuration paths via TPC_CONFIGPATH environment variable
  * `Add-tpcConfigPath` - Add configuration paths with validation and path creation
  * `Remove-tpcConfigPath` - Interactive removal of configuration paths
  * `Get-tpcConfigPaths` - Retrieve all configured paths

### Changed

* **start-tpcMonitor**: Configuration parameter update
  * Changed `-config` to `-configName` and added `-configPath` to support usage of single configuration files

* **Get-tpcAvailableCounterConfig**: Multiple improvements for handling multiple folders

### Deprecated

### Removed

* Private `Get-ConfigurationFromJson` merged into `Get-CounterConfiguration.ps1`

### Fixed

* **Y-axis scaling**: Implemented compact value formatting (5000→"5.0k", 1M→"1.0M")

### Security

### Code Quality

* **Refactored variable names in GraphicalEngine for better clarity and consistency**
  * Renamed `$YAxisLabel` to `$CurrentYValue` in Show-Graph.ps1 (was misleading as it represents actual Y-axis  values, not labels)
  * Renamed `$YAxisLabel` to `$YAxisValue` in UtilityFunctions.ps1 Write-Graph function
  * Renamed `$LengthOfMaxYAxisLabel` to `$MaxYValueWidth` across all files for semantic accuracy
  * Renamed `$XAxisLabel` to `$XAxisText` to clearly indicate it's display text, not a value
  * Renamed `$TimeLabel` to `$TimeValue` as it represents time values, not labels
  * Renamed loop variable `$Label` to `$Index` in X-axis generation for clarity
  * Updated all function calls and parameter references to use consistent naming throughout the codebase

* **Parameter harmonization and documentation improvements**
  * Renamed `MaxDataPoints` parameter to `MaxHistoryPoints` in `Start-tpcMonitor` for clarity - distinguishes between historical data storage and graph display
  * Renamed internal variable `targetWidth` to `sampleCount` in `GetGraphData()` method for semantic accuracy
  * Renamed `maxDataPoints` parameter to `maxHistoryPoints` in `AddDataPoint()` method for consistency
  * Enhanced parameter documentation with clear explanations of `MaxHistoryPoints` (complete historical data) vs `Samples` (graph display points)
  * Clarified time span calculation: **Graph time span = Samples × UpdateInterval seconds**
  * Updated examples to demonstrate the relationship between update interval and graph time coverage


## [0.1.0]  - 2025-07-25
