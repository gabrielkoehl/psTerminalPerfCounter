﻿# Config Path Management
$script:TPC_CONFIG_PATH_VAR = "TPC_CONFIGPATH"
$script:DEFAULT_CONFIG_PATH = Join-Path $PSScriptRoot -ChildPath "Config"
$script:JSON_SCHEMA_FILE    = Join-Path $script:DEFAULT_CONFIG_PATH -ChildPath "schema.json"

# Dot source public/private functions
$classes            = @(Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Classes/*.ps1') -Recurse -ErrorAction Stop)
$public             = @(Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Public/*.ps1')  -Recurse -ErrorAction Stop)
$private            = @(Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Private/*.ps1') -Recurse -ErrorAction Stop)
$GraphicalEngine    = @(Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath 'GraphicalEngine/*.ps1') -Recurse -ErrorAction Stop)

foreach ($import in @($classes + $public + $private + $GraphicalEngine)) {
    try {
        . $import.FullName
    } catch {
        throw "Unable to dot source [$($import.FullName)]"
    }
}

Export-ModuleMember -Function $public.Basename
