@{

# Script module or binary module file associated with this manifest.
RootModule = 'psTerminalPerfCounter.psm1'

# Version number of this module.
ModuleVersion = '0.3.1'

# Supported PSEditions
CompatiblePSEditions = @('Core')

# ID used to uniquely identify this module
GUID = '25ce61b2-11d0-420c-bc9f-7a95ae56a316'

# Author of this module
Author = 'Gabriel Köhl'

# Company or vendor of this module
CompanyName = 'dbavonnebenan.de'

# Copyright statement for this module
Copyright = '(c) 2026 Gabriel Köhl. All rights reserved.'

# Description of the functionality provided by this module
Description = 'A PowerShell module for displaying real-time graphs of Windows Performance Counters directly in the terminal console. This module provides an easy way to visualize system performance metrics without requiring external graphing tools or GUI applications by using templates and multilanguage support.'

# Minimum version of the PowerShell engine required by this module
PowerShellVersion = '7.4'

# Name of the PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# ClrVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
# RequiredModules = @('')

# Assemblies that must be loaded prior to importing this module
RequiredAssemblies = @('Lib\psTPCCLASSES.dll')

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
# FormatsToProcess = @()

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
# NestedModules = @()

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport = '*'

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
CmdletsToExport = '*'

# Variables to export from this module
VariablesToExport = '*'

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
AliasesToExport = '*'

# DSC resources to export from this module
# DscResourcesToExport = @()

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
# FileList = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = @('PerformanceCounter', 'Monitoring', 'Terminal', 'Console', 'Graph', 'Visualization', 'Windows', 'Performance', 'System', 'Diagnostics', 'Real-time', 'CPU', 'Memory', 'Disk', 'Counter', 'PowerShell', 'Troubleshooting', 'Analytics')

        # A URL to the license for this module.
        LicenseUri = 'https://github.com/gabrielkoehl/psTerminalPerfCounter/blob/main/LICENSE'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/gabrielkoehl/psTerminalPerfCounter'

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        ReleaseNotes = 'Version 0.2.0: Major update featuring remote server monitoring capabilities. Monitor remote servers via -ComputerName parameter with credential support. Added configuration path management (Add/Remove/Get-tpcConfigPath). Enhanced Start-tpcMonitor with -ConfigName/-ConfigPath parameters. Improved Y-axis scaling with compact formatting (5k, 1M). Comprehensive code quality improvements and parameter harmonization throughout the module.'

        # Prerelease string of this module
        # Prerelease = 'preview'

        # Flag to indicate whether the module requires explicit user acceptance for install/update/save
        # RequireLicenseAcceptance = $false

        # External dependent modules of this module
        # ExternalModuleDependencies = @()

    } # End of PSData hashtable

} # End of PrivateData hashtable

# HelpInfo URI of this module
HelpInfoURI = 'https://github.com/gabrielkoehl/psTerminalPerfCounter/blob/main/README.md'

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}
