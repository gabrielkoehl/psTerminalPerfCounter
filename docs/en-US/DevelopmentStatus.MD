## Development Status V 0.1.0

This module is actively developed with the following features planned

### Planned Features

- 🔄 Proper implementation of custom config path or possibility to load single configuration
- 🔄 Possibility to override configurations with single values while starting monitoring
- 🔄 Continuous data export to file
  - 🔄 Excel export with ImportExcel module integration
  - 🔄 PSWriteHtml ( It has automatically refreshing pages, possibly for visualization or complex reports )
- 🔄 Additional performance counter templates
- 🔄 User-friendly usage of SQL Server counters through dynamic instance implementation

### Testing & Feedback

Currently, testing capabilities are limited to a narrow set of environments. **Please report any issues or compatibility problems** you encounter. The past few days have been focused on documentation and feature implementation, with several improvements identified and addressed.

Any feedback, bug reports, or feature requests are highly appreciated as the module continues to evolve.

## Known Issues

Currently identified issues that are being addressed:

- **Y-axis scaling display issue**: When Y-axis scale values become too long, the graph frame shifts position
  - **Workaround**: Use `conversionFactor` and `conversionExponent` parameter in configuration to shorten the axix values

- **Graph width vs samples configuration vs maxsamples**: The relationship between maxSamples parameter, graph width and samples is not intuitive
  - **Current behavior**: Graph width is controlled `Samples` property in configuration, translated in Class to `TargetWidth`  what describes graph padding. `MaxSamples` in main function are the max hold historical datapoints in class property `HistoricalData` and affects the average values, but only 5 are used in output (hardcoded). I only really noticed it when writing the readme
  - **Planned improvement**: Improve
