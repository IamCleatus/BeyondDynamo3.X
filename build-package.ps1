param(
    [string]$RevitVersions = "2021,2022,2023,2024,2025,2026,2027",

    [string]$PackageName = "BeyondDynamo",
    [string]$PackageVersion = "3.0.0"
)

$ErrorActionPreference = "Stop"

$allowedRevitVersions = @("2021","2022","2023","2024","2025","2026","2027")

$resolvedVersions = @()
foreach ($entry in ($RevitVersions -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })) {
    if ($entry -notin $allowedRevitVersions) {
        throw "Unsupported Revit version '$entry'. Supported versions: $($allowedRevitVersions -join ', ')"
    }
    $resolvedVersions += $entry
}

if (-not $resolvedVersions) {
    $resolvedVersions = $allowedRevitVersions
}

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectFile = Join-Path $repoRoot "src\BeyondDynamo\BeyondDynamo.csproj"
$packageRoot = Join-Path $repoRoot "packages"
$projectBin = Join-Path $repoRoot "src\BeyondDynamo\bin\Debug"
$packageSignScript = Join-Path $repoRoot "sign-package.ps1"

$dynamoVersionMap = @{
    "2021" = "2.6.0.8481"
    "2022" = "2.7.0.9206"
    "2023" = "2.12.0.5650"
    "2024" = "2.15.0.5383"
    "2025" = "2.16.0.2501"
    "2026" = "2.17.0.3493"
    "2027" = "2.18.0.4827"
}

function New-DynamoPackageManifest {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RevitYear,

        [Parameter(Mandatory = $true)]
        [string]$DynamoVersion,

        [Parameter(Mandatory = $true)]
        [string]$PackageName,

        [Parameter(Mandatory = $true)]
        [string]$PackageVersion
    )

    $manifest = [ordered]@{
        name = $PackageName
        version = $PackageVersion
        description = "Dynamo view extension for Revit $RevitYear compatibility"
        author = "IamCleatus"
        license = "MIT"
        repository_url = "https://github.com/IamCleatus/BeyondDynamo3.X"
        keywords = @("dynamo", "revit", "view-extension", "productivity")
        dependencies = @{}
        revit_version = $RevitYear
        dynamo_version = $DynamoVersion
        package_type = "extension"
    }

    return ($manifest | ConvertTo-Json -Depth 10)
}

foreach ($revitVersion in $resolvedVersions) {
    $packageDir = Join-Path $packageRoot ("{0}-{1}" -f $PackageName, $revitVersion)
    $binDir = Join-Path $packageDir "bin"
    $viewExtensionDir = Join-Path $packageDir "viewExtensions"

    if (Test-Path $packageDir) {
        Remove-Item -Recurse -Force $packageDir
    }

    New-Item -ItemType Directory -Force -Path $binDir | Out-Null
    New-Item -ItemType Directory -Force -Path $viewExtensionDir | Out-Null

    Write-Host "Building BeyondDynamo for Revit $revitVersion"
    & dotnet build $projectFile -p:RevitVersion=$revitVersion -p:Configuration=Debug -p:GenerateFullPaths=true -nologo -v:minimal

    if ($LASTEXITCODE -ne 0) {
        throw "Build failed for Revit $revitVersion."
    }

    $dllSource = Join-Path $projectBin "BeyondDynamo.dll"
    $xmlSource = Join-Path $projectBin "BeyondDynamo_ViewExtensionDefinition.xml"

    if (-not (Test-Path $dllSource)) {
        throw "Expected build output not found: $dllSource"
    }

    if (-not (Test-Path $xmlSource)) {
        throw "Expected extension definition not found: $xmlSource"
    }

    Copy-Item $dllSource (Join-Path $binDir "BeyondDynamo.dll") -Force

    $viewExtensionDefinitionPath = Join-Path $viewExtensionDir "BeyondDynamo_ViewExtensionDefinition.xml"
    $extensionDefinitionXml = [xml](Get-Content -Raw -Path $xmlSource)
    $extensionDefinitionXml.ViewExtensionDefinition.AssemblyPath = "..\bin\BeyondDynamo.dll"
    $extensionDefinitionXml.ViewExtensionDefinition.TypeName = "BeyondDynamo.BeyondDynamoExtension"
    $extensionDefinitionXml.Save($viewExtensionDefinitionPath)

    if ($extensionDefinitionXml.ViewExtensionDefinition.AssemblyPath -ne "..\bin\BeyondDynamo.dll") {
        throw "Extension definition assembly path was not set correctly for package $packageDir."
    }

    $pkgJsonPath = Join-Path $packageDir "pkg.json"
    $manifestJson = New-DynamoPackageManifest -RevitYear $revitVersion -DynamoVersion $dynamoVersionMap[$revitVersion] -PackageName $PackageName -PackageVersion $PackageVersion
    Set-Content -Path $pkgJsonPath -Value $manifestJson -Encoding UTF8

    if (Test-Path $packageSignScript) {
        Write-Host "Signing package assembly for Revit $revitVersion"
        & powershell -ExecutionPolicy Bypass -File $packageSignScript -ProjectPath "src\BeyondDynamo\BeyondDynamo.csproj" -AssemblyPath "src\BeyondDynamo\bin\Debug\BeyondDynamo.dll" -Subject "CN=BeyondDynamo Package" -CreateCertificateIfMissing
    }

    Write-Host "Package ready at: $packageDir"
}

Write-Host ""
Write-Host "Completed package layout generation for supported Revit versions: $($resolvedVersions -join ', ')"
