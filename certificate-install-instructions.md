# Revit certificate trust instructions

Use these steps on the target Windows machine that will run Revit.

## 1) Copy the exported certificate files

From the repository folder on the signing machine, copy these files to the target PC:

- `certificates/BeyondDynamoPackage.cer`
- `certificates/BeyondDynamoPackage.pfx`

## 2) Install the certificate as a trusted publisher / root

### Option A: Trusted Root (simplest for local dev/test)

Open an elevated PowerShell window and run:

```powershell
$cert = Get-PfxCertificate -FilePath .\BeyondDynamoPackage.pfx -Password (ConvertTo-SecureString -String 'BeyondDynamoPackage!2027' -AsPlainText -Force)
Import-PfxCertificate -FilePath .\BeyondDynamoPackage.pfx -CertStoreLocation Cert:\CurrentUser\Root -Password (ConvertTo-SecureString -String 'BeyondDynamoPackage!2027' -AsPlainText -Force)
```

### Option B: Trusted People / Current User store

```powershell
Import-PfxCertificate -FilePath .\BeyondDynamoPackage.pfx -CertStoreLocation Cert:\CurrentUser\TrustedPeople -Password (ConvertTo-SecureString -String 'BeyondDynamoPackage!2027' -AsPlainText -Force)
```

## 3) Install the certificate for code-signing trust

```powershell
Import-PfxCertificate -FilePath .\BeyondDynamoPackage.pfx -CertStoreLocation Cert:\CurrentUser\My -Password (ConvertTo-SecureString -String 'BeyondDynamoPackage!2027' -AsPlainText -Force)
```

## 4) Reopen Revit and reload the package

After the certificate is trusted, reopen Dynamo/Revit and load the package again.

> Important: the machine must trust the certificate. Without that, the package may still be blocked even if the assembly was signed correctly.
