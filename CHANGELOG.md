# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]

### Added

* **Y-axis scaling**: Implemented compact value formatting (5000→"5.0k", 1M→"1.0M")

### Changed

### Deprecated

### Removed

### Fixed

### Security

### Code Quality

#### Refactored variable names in GraphicalEngine for better clarity and consistency

* Renamed `$YAxisLabel` to `$CurrentYValue` in Show-Graph.ps1 (was misleading as it represents actual Y-axis  values, not labels)
* Renamed `$YAxisLabel` to `$YAxisValue` in UtilityFunctions.ps1 Write-Graph function
* Renamed `$LengthOfMaxYAxisLabel` to `$MaxYValueWidth` across all files for semantic accuracy
* Renamed `$XAxisLabel` to `$XAxisText` to clearly indicate it's display text, not a value
* Renamed `$TimeLabel` to `$TimeValue` as it represents time values, not labels
* Renamed loop variable `$Label` to `$Index` in X-axis generation for clarity
* Updated all function calls and parameter references to use consistent naming throughout the codebase

## [0.1.0]  - 2025-07-25
