param(
    [ValidateSet("2021","2022","2023","2024","2025","2026","2027")]
    [string]$RevitVersion = "2027",

    [ValidateSet("all","plugin","installer")]
    [string]$Target = "all",

    [string]$DynamoVersionOverride
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$pluginProject = Join-Path $repoRoot "src\BeyondDynamo\BeyondDynamo.csproj"
$installerProject = Join-Path $repoRoot "src\BeyondDynamoInstaller\BeyondDynamoInstaller.csproj"

$revitToDynamoPrefix = @{
    "2021" = "2.6.0"
    "2022" = "2.7.0"
    "2023" = "2.12.0"
    "2024" = "2.15.0"
    "2025" = "2.16.0"
    "2026" = "2.17.0"
    "2027" = "2.18.0"
}

function Get-NuGetPackageVersions {
    param(
        [Parameter(Mandatory = $true)]
        [string]$PackageId
    )

    $packageId = $PackageId.ToLowerInvariant()
    $uri = "https://api.nuget.org/v3-flatcontainer/$packageId/index.json"
    $response = Invoke-WebRequest -Uri $uri -UseBasicParsing -ErrorAction Stop
    $json = $response.Content | ConvertFrom-Json

    return @($json.versions)
}

function Resolve-DynamoVersion {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RevitVersion
    )

    if ($DynamoVersionOverride) {
        return $DynamoVersionOverride
    }

    $versionPrefix = $revitToDynamoPrefix[$RevitVersion]
    if (-not $versionPrefix) {
        throw "No Dynamo compatibility prefix is configured for Revit $RevitVersion. Add it to the `$revitToDynamoPrefix map in this script."
    }

    $versions = Get-NuGetPackageVersions -PackageId "DynamoVisualProgramming.Core"
    $resolved = $versions |
        Where-Object { $_ -match '^\d+\.\d+\.\d+\.\d+$' -and $_.StartsWith($versionPrefix, [System.StringComparison]::OrdinalIgnoreCase) } |
        ForEach-Object { [version]$_ } |
        Sort-Object |
        Select-Object -Last 1

    if (-not $resolved) {
        throw "No Dynamo package versions were found for Revit $RevitVersion using prefix $versionPrefix. Check the NuGet feed or update the compatibility map."
    }

    return $resolved
}

$resolvedDynamoVersion = Resolve-DynamoVersion -RevitVersion $RevitVersion

Write-Host "Building BeyondDynamo for Revit $RevitVersion"
Write-Host "Resolved Dynamo package version: $resolvedDynamoVersion"
Write-Host "Repository root: $repoRoot"

function Invoke-Build {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectPath,
        [Parameter(Mandatory = $true)][string]$Label
    )

    $logDir = Join-Path $repoRoot "artifacts\build"
    New-Item -ItemType Directory -Force -Path $logDir | Out-Null
    $binaryLog = Join-Path $logDir ("{0}-{1}.binlog" -f ([System.IO.Path]::GetFileNameWithoutExtension($ProjectPath)), $RevitVersion)

    Write-Host ""
    Write-Host "=== Building $Label ==="
    Write-Host "Build log: $binaryLog"

    $buildArgs = @(
        $ProjectPath,
        "-p:RevitVersion=$RevitVersion",
        "-p:DynamoVersion=$resolvedDynamoVersion",
        "-p:Configuration=Debug",
        "-p:EnforceCodeStyleInBuild=true",
        "-p:RunAnalyzersDuringBuild=true",
        "-p:RunAnalyzers=true",
        "-p:EnableNETAnalyzers=true",
        "-p:AnalysisLevel=latest",
        "-p:AnalysisMode=AllEnabledByDefault",
        "-p:TreatWarningsAsErrors=false",
        "-p:CodeAnalysisTreatWarningsAsErrors=false",
        "-p:GenerateFullPaths=true",
        "-bl:$binaryLog",
        "-nologo",
        "-v:normal"
    )

    & dotnet build @buildArgs

    if ($LASTEXITCODE -ne 0) {
        throw "Build failed for $Label ($ProjectPath)"
    }
}

switch ($Target) {
    "plugin" {
        Invoke-Build -ProjectPath $pluginProject -Label "BeyondDynamo plugin"
    }
    "installer" {
        Invoke-Build -ProjectPath $installerProject -Label "BeyondDynamo installer"
    }
    default {
        Invoke-Build -ProjectPath $pluginProject -Label "BeyondDynamo plugin"
        Invoke-Build -ProjectPath $installerProject -Label "BeyondDynamo installer"
    }
}

Write-Host ""
Write-Host "Build completed successfully for Revit $RevitVersion using Dynamo $resolvedDynamoVersion."
