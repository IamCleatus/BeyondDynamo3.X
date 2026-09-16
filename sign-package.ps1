param(
    [string]$ProjectPath = "src\BeyondDynamo\BeyondDynamo.csproj",
    [string]$AssemblyPath = "src\BeyondDynamo\bin\Debug\BeyondDynamo.dll",
    [string]$Subject = "CN=BeyondDynamo Package",
    [string]$CertificateThumbprint = "",
    [string]$TimestampServer = "http://timestamp.digicert.com",
    [switch]$CreateCertificateIfMissing,
    [switch]$RequireSignedAssembly
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$resolvedProjectPath = Join-Path $repoRoot $ProjectPath
$resolvedAssemblyPath = Join-Path $repoRoot $AssemblyPath

if (-not (Test-Path $resolvedProjectPath)) {
    throw "Project file not found: $resolvedProjectPath"
}

if (-not (Test-Path $resolvedAssemblyPath)) {
    throw "Assembly not found. Build the project first: $resolvedAssemblyPath"
}

$cert = $null

if ($CertificateThumbprint) {
    $cert = Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert | Where-Object { $_.Thumbprint -eq $CertificateThumbprint } | Select-Object -First 1
    if (-not $cert) {
        $cert = Get-ChildItem Cert:\LocalMachine\My -CodeSigningCert | Where-Object { $_.Thumbprint -eq $CertificateThumbprint } | Select-Object -First 1
    }
}

if (-not $cert) {
    $cert = Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert | Where-Object { $_.Subject -eq $Subject } | Select-Object -First 1
}

if (-not $cert) {
    if ($CreateCertificateIfMissing) {
        Write-Host "Creating a local code-signing certificate for $Subject"
        Write-Warning "This is a local development certificate only. It is not a public CA-issued certificate and will not provide official trust for public package distribution."
        $cert = New-SelfSignedCertificate -CertStoreLocation Cert:\CurrentUser\My -Type CodeSigningCert -Subject $Subject -KeyExportPolicy Exportable -KeyUsage DigitalSignature -FriendlyName "BeyondDynamo"
    }
    else {
        Write-Warning "No code-signing certificate found for $Subject. The assembly will remain unsigned. Revit may warn or block it."
        if ($RequireSignedAssembly) {
            throw "Signing is required but no certificate was found. Re-run with -CreateCertificateIfMissing to generate one, or provide -CertificateThumbprint for your official code-signing certificate."
        }
        return
    }
}

$certificateThumbprint = $cert.Thumbprint
Write-Host "Signing assembly with certificate: $certificateThumbprint"
Set-AuthenticodeSignature -FilePath $resolvedAssemblyPath -Certificate $cert -TimestampServer $TimestampServer | Out-Null

Write-Host "Signed successfully: $resolvedAssemblyPath"
Write-Host "Public package distribution should use a CA-issued Authenticode certificate rather than a local self-signed one."
