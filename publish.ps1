#!/usr/bin/env pwsh
# NIGHTFALL publish script
# Builds and publishes Nightfall.App (WPF, net9.0-windows10.0.19041.0) for win-x64,
# and stages the elevated helper alongside it. Run from the repository root.
#
# Requires: %LOCALAPPDATA%\dotnet-sdk\dotnet.exe
# Output:   publish/  (Nightfall.exe + Nightfall.Privileged.exe under Helper\)

param(
    [string]$Configuration = "Release",
    [string]$Runtime = "win-x64",
    [string]$OutputRoot = "$PSScriptRoot\publish",
    [switch]$SelfContained = $false
)

$ErrorActionPreference = "Stop"
$SetStrictMode = $true

$dotnet = Join-Path $env:LOCALAPPDATA "dotnet-sdk\dotnet.exe"
if (-not (Test-Path $dotnet)) {
    throw "dotnet SDK not found at $dotnet. Set up %LOCALAPPDATA%\dotnet-sdk first."
}

Write-Host "=== NIGHTFALL publish ===" -ForegroundColor Cyan
Write-Host "Configuration: $Configuration"
Write-Host "Runtime: $Runtime"
Write-Host "Self-contained: $SelfContained"
Write-Host "Output root: $OutputRoot"

# Clean output
if (Test-Path $OutputRoot) { Remove-Item $OutputRoot -Recurse -Force }
New-Item -ItemType Directory -Path $OutputRoot -Force | Out-Null

# 1) Build the core library (catches errors early)
Write-Host "`n[1/4] Building Nightfall.Core ..." -ForegroundColor Yellow
& $dotnet build "src/Nightfall.Core/Nightfall.Core.csproj" -c $Configuration -v m | Out-String | Write-Host

# 2) Build+publish the app (non-admin UI)
$appPublish = Join-Path $OutputRoot "Nightfall.App"
Write-Host "`n[2/4] Publishing Nightfall.App to $appPublish ..." -ForegroundColor Yellow
$publishArgs = @(
    "publish", "src/Nightfall.App/Nightfall.App.csproj",
    "-c", $Configuration,
    "-r", $Runtime,
    "--self-contained", ([bool]$SelfContained).ToString().ToLower(),
    "-o", $appPublish,
    "-v", "m"
)
& $dotnet @publishArgs | Out-String | Write-Host

# 3) Publish the elevated helper
$helperPublish = Join-Path $appPublish "Helper"
Write-Host "`n[3/4] Publishing Nightfall.Privileged to $helperPublish ..." -ForegroundColor Yellow
& $dotnet publish "src/Nightfall.Privileged/Nightfall.Privileged.csproj" `
    "-c=$Configuration" "-r=$Runtime" "--self-contained=$([bool]$SelfContained)" `
    "-o=$helperPublish" "-v=m" | Out-String | Write-Host

# The helper must live at <app>\Helper\Nightfall.Privileged.exe so the UI can locate it.
$helperExe = Join-Path $helperPublish "Nightfall.Privileged.exe"
if (-not (Test-Path $helperExe)) {
    throw "Elevated helper not found at $helperExe."
}
Write-Host "Helper present: True ($helperExe)" -ForegroundColor Green

# 4) Summary
Write-Host "`n=== Publish complete ===" -ForegroundColor Cyan
Get-ChildItem $OutputRoot -Recurse | Select-Object Name, Length | Format-Table -AutoSize | Out-String | Write-Host

Write-Host "`nNext steps:" -ForegroundColor Gray
Write-Host "  - Run smoke test:  $appPublish\Nightfall.exe --smoke-test" -ForegroundColor Gray
Write-Host "  - Screenshot:      $appPublish\Nightfall.exe --screenshot <out.png>" -ForegroundColor Gray
Write-Host "  - Admin-only steps (helper execution, restore point, AppX removal) require elevation." -ForegroundColor Gray
