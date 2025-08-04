# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]

### Added

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

* Private `Get-ConfigurationFromJson` merged into `Get-PerformanceConfig.ps1`

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
