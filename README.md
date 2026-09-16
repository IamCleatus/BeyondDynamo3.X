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
2. Sign the resulting assembly if your environment enforces certificate validation:

   ```powershell
   powershell -ExecutionPolicy Bypass -File .\sign-package.ps1 -ProjectPath "src\BeyondDynamo\BeyondDynamo.csproj" -AssemblyPath "src\BeyondDynamo\bin\Debug\BeyondDynamo.dll" -Subject "CN=BeyondDynamo Package" -CreateCertificateIfMissing
   ```

3. Copy the compiled `BeyondDynamo.dll` to the Dynamo extension folder used by that Revit installation.
4. Place the XML extension definition file alongside the DLL if it is not already copied by the build output.

When Windows or Revit checks the assembly certificate before loading a package, a trusted local code-signing certificate helps avoid certificate warnings or blocked package loading.

### Official CA signing for public package distribution

For public upload, official Authenticode signing is recommended. A self-signed cert is only suitable for local testing and developer environments. It does not provide the public trust level required for a package that will be hosted online or downloaded by third parties.

Recommended flow:

1. Purchase an Authenticode code-signing certificate from a CA such as:
   - DigiCert
   - Sectigo / Comodo
   - GlobalSign
   - GoGetSSL
2. Install the certificate into your personal or machine certificate store.
3. Export or locate the certificate with the private key.
4. Sign the DLL using the official cert thumbprint:

   ```powershell
   powershell -ExecutionPolicy Bypass -File .\sign-package.ps1 -ProjectPath "src\BeyondDynamo\BeyondDynamo.csproj" -AssemblyPath "src\BeyondDynamo\bin\Debug\BeyondDynamo.dll" -CertificateThumbprint "YOUR_CERT_THUMBPRINT" -TimestampServer "http://timestamp.digicert.com"
   ```

5. Rebuild and repackage the final zipped package after signing.
6. Upload the package only after the assembly and the package archive are both signed and timestamped.

Important:

- `New-SelfSignedCertificate` is for local testing only.
- Public package hosting should always use a CA-issued Authenticode certificate.
- The timestamp server should come from the issuing CA and should be supported by the certificate chain.

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

