# BeyondDynamo

A Dynamo extension that adds productivity tools for graph cleanup, selection handling, node operations, and workspace management.

![Beyond Dynamo Banner](/pictures/BeyondDynamoBanner.png)

This project has been modernized to an SDK-style .NET Framework setup and is targeted for the Revit/Dynamo ecosystem from 2021 through 2027.

## Compatibility

The project is designed to compile against the .NET Framework 4.8 runtime used by Revit add-ins, while selecting the correct Dynamo package version for the target Revit release.

Supported Revit targets:

- 2021
- 2022
- 2023
- 2024
- 2025
- 2026
- 2027

## Build the project

From the repository root:

```powershell
powershell -ExecutionPolicy Bypass -File .\build-revit.ps1 -RevitVersion 2024
```

Or build a specific part:

```powershell
powershell -ExecutionPolicy Bypass -File .\build-revit.ps1 -RevitVersion 2027 -Target plugin
powershell -ExecutionPolicy Bypass -File .\build-revit.ps1 -RevitVersion 2027 -Target installer
```

You can also run the build directly with MSBuild:

```powershell
dotnet build .\src\BeyondDynamo\BeyondDynamo.csproj -p:RevitVersion=2027 -nologo -v:minimal
dotnet build .\src\BeyondDynamoInstaller\BeyondDynamoInstaller.csproj -p:RevitVersion=2027 -nologo -v:minimal
```

## Install for Revit

1. Build the plugin project for the target Revit version.
2. Copy the compiled `BeyondDynamo.dll` to the Dynamo extension folder used by that Revit installation.
3. Place the XML extension definition file alongside the DLL if it is not already copied by the build output.

Typical install locations for Dynamo-based Revit installs:

- `C:\Program Files\Autodesk\Revit 202x\AddIns\DynamoForRevit\...`
- `C:\Program Files\Autodesk\Dynamo\DynamoCore\...`
- or the Dynamo root used by your specific Revit release and install configuration

The actual installation location depends on your Revit/Dynamo setup and whether you are installing for Sandbox, Revit, or another host application.

## Extension definition file

The extension registration file is:

- `src/BeyondDynamo/BeyondDynamo_ViewExtensionDefinition.xml`

This file should be deployed with the compiled assembly where Dynamo recognizes view extensions.

## Notes

- This version is intended to preserve the original functionality while modernizing the project structure.
- The Revit target is selected by the `RevitVersion` property, which maps to the matching Dynamo package version.
- If you need to build for a different Revit year, change the command to the correct value, for example `2021`, `2022`, `2025`, or `2027`.

## Latest build

Find the latest build artifacts in the `latestBuild` folder and the project source under `src/`.

