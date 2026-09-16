param(
    [ValidateSet("2021","2022","2023","2024","2025","2026","2027")]
    [string]$RevitVersion = "2027"
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectFile = Join-Path $repoRoot "src\BeyondDynamo\BeyondDynamo.csproj"
$packageRoot = Join-Path $repoRoot "packages\BeyondDynamo"
$packageBin = Join-Path $packageRoot "bin"
$projectBin = Join-Path $repoRoot "src\BeyondDynamo\bin\Debug"
$packageZip = Join-Path $repoRoot "packages\BeyondDynamo-v3.0.0.zip"

New-Item -ItemType Directory -Force -Path $packageBin | Out-Null

Write-Host "Building BeyondDynamo for Revit $RevitVersion"
& dotnet build $projectFile -p:RevitVersion=$RevitVersion -p:Configuration=Debug -nologo -v:minimal

if ($LASTEXITCODE -ne 0) {
    throw "Build failed for Revit $RevitVersion."
}

$dllSource = Join-Path $projectBin "BeyondDynamo.dll"
$xmlSource = Join-Path $projectBin "BeyondDynamo_ViewExtensionDefinition.xml"
$dllTarget = Join-Path $packageBin "BeyondDynamo.dll"
$xmlTarget = Join-Path $packageBin "BeyondDynamo_ViewExtensionDefinition.xml"

Copy-Item $dllSource $dllTarget -Force
Copy-Item $xmlSource $xmlTarget -Force

Write-Host "Package contents ready at: $packageRoot"

if (Test-Path $packageZip) {
    Remove-Item $packageZip -Force
}

Compress-Archive -Path (Join-Path $packageRoot "*") -DestinationPath $packageZip -Force

Write-Host "Dynamo package archive created: $packageZip"
