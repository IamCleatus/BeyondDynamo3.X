param(
    [ValidateSet("2021","2022","2023","2024","2025","2026","2027")]
    [string]$RevitVersion = "2027",

    [string]$PackageRoot = "packages",
    [string]$OutputFolder = "packages\upload"
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$packagePath = Join-Path $repoRoot ("{0}\{1}-{2}" -f $PackageRoot, "BeyondDynamo", $RevitVersion)
$outputPath = Join-Path $repoRoot $OutputFolder

if (-not (Test-Path $packagePath)) {
    throw "Package folder not found: $packagePath. Run build-package.ps1 first."
}

New-Item -ItemType Directory -Force -Path $outputPath | Out-Null

$zipPath = Join-Path $outputPath ("BeyondDynamo-v{0}.zip" -f $RevitVersion)
if (Test-Path $zipPath) {
    Remove-Item $zipPath -Force
}

$viewExtensionDefinitionPath = Join-Path $packagePath "viewExtensions\BeyondDynamo_ViewExtensionDefinition.xml"
if (-not (Test-Path $viewExtensionDefinitionPath)) {
    throw "Expected extension definition not found: $viewExtensionDefinitionPath"
}

$definitionXml = [xml](Get-Content -Raw -Path $viewExtensionDefinitionPath)
if ($definitionXml.ViewExtensionDefinition.AssemblyPath -ne "..\bin\BeyondDynamo.dll") {
    throw "Package viewExtensions path is incorrect: $($definitionXml.ViewExtensionDefinition.AssemblyPath)"
}

Compress-Archive -Path $packagePath -DestinationPath $zipPath -Force

Write-Host "Created package artifact: $zipPath"
Write-Host "This is the folder to upload locally: $outputPath"
Write-Host "Package source used: $packagePath"
Write-Host "Verified viewExtensions assembly path: $($definitionXml.ViewExtensionDefinition.AssemblyPath)"
