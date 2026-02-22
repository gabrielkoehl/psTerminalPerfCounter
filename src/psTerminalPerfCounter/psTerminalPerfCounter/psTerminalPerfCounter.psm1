# Script Handling
$ErrorActionPreference = "Stop"

# Config Path Management
$script:TPC_CONFIG_PATH_VAR             = "TPC_CONFIGPATH"
$script:DEFAULT_CONFIG_PATH             = Join-Path $PSScriptRoot -ChildPath "Config"
$script:JSON_SCHEMA_CONFIG_FILE         = Join-Path $script:DEFAULT_CONFIG_PATH -ChildPath "schema_config.json"
$script:JSON_SCHEMA_ENVIRONMENT_FILE    = Join-Path $script:DEFAULT_CONFIG_PATH -ChildPath "schema_environment.json"
$script:JSON_DEFAULT_TEMPLATE_FILE      = Join-Path $script:DEFAULT_CONFIG_PATH -ChildPath "default_template_values.json"

# Loading Logger (Singleton)
$script:logger = [psTPCCLASSES.PowerShellLogger]::Instance

# Dot source public/private functions
$public             = @(Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Public/*.ps1')  -Recurse -ErrorAction Stop)
$private            = @(Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Private/*.ps1') -Recurse -ErrorAction Stop)
$GraphicalEngine    = @(Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath 'GraphicalEngine/*.ps1') -Recurse -ErrorAction Stop)

foreach ($import in @($public + $private + $GraphicalEngine)) {
    try {
        . $import.FullName
    } catch {
        throw "Unable to dot source [$($import.FullName)]"
    }
}

Export-ModuleMember -Function $public.Basename
