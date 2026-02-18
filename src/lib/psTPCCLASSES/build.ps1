$targetPath = Join-Path $PSScriptRoot "..\..\psTerminalPerfCounter\psTerminalPerfCounter\Lib"

# --- Build ---
$projectFile = Get-ChildItem -Path $PSScriptRoot -Filter "*.csproj" | Select-Object -First 1
if (-not $projectFile) {
    Write-Error "No .csproj found in script directory."
    exit 1
}

Write-Host "Building $($projectFile.Name)..." -ForegroundColor Cyan
dotnet build $projectFile.FullName -c Release

if ($LASTEXITCODE -ne 0) {
    Write-Error "Build failed."
    exit 1
}

# --- Resolve paths ---
$projectName = [System.IO.Path]::GetFileNameWithoutExtension($projectFile.Name)
$buildOutput = Join-Path $PSScriptRoot "bin\Release\net8.0"
$dllSource   = Join-Path $buildOutput "$projectName.dll"
$depsSource  = Join-Path $buildOutput "$projectName.deps.json"

# --- Validate ---
foreach ($file in @($dllSource, $depsSource)) {
    if (-not (Test-Path $file)) {
        Write-Error "File not found: $file"
        exit 1
    }
}

# --- Copy ---
New-Item -ItemType Directory -Force -Path $targetPath | Out-Null
Copy-Item -Path $dllSource  -Destination $targetPath -Force
Copy-Item -Path $depsSource -Destination $targetPath -Force

Write-Host "Deployed to: $(Resolve-Path $targetPath)" -ForegroundColor Green