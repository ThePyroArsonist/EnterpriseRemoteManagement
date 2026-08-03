# Object Navigation

## Purpose

The Enterprise Remote Management (ERM) framework produces normalized objects that
are intended to be explored directly from PowerShell.

Every engine returns structured objects rather than formatted text.

This allows administrators, developers and automation platforms to query only
the information they need.

---

# Starting Point

Retrieve the raw certificate inventory.

```powershell
$Inventory = Get-ERMCertificateInformation -Raw
```

The returned object contains:

```text
Metadata
Environment
Statistics
Certificates
Errors
```

View the top-level object.

```powershell
$Inventory | Format-List *
```

---

# Engine Metadata

Engine execution information.

```powershell
$Inventory.Metadata
```

Example

```text
Engine
EngineVersion
InventoryTime
CompletionTime
DurationMilliseconds
ComputerName
Stores
```

---

# Environment

Information about the computer that generated the inventory.

```powershell
$Inventory.Environment
```

Example

```text
ComputerIdentity
PowerShellVersion
OperatingSystem
```

---

# Statistics

Summary of the inventory.

```powershell
$Inventory.Statistics
```

Example

```text
TotalCertificates
StoresEnumerated
CertificatesWithPrivateKey
AccessiblePrivateKeys
ExpiredCertificates
ExpiringSoonCertificates
CACertificates
EndEntityCertificates
ServerAuthenticationCertificates
ClientAuthenticationCertificates
Stores
```

---

# Errors

Stores any inventory or parsing failures.

```powershell
$Inventory.Errors
```

If empty, the inventory completed successfully.

---

# Certificates

The normalized certificate collection.

```powershell
$Inventory.Certificates
```

Display the first certificate.

```powershell
$Inventory.Certificates[0]
```

Display every property.

```powershell
$Inventory.Certificates[0] | Format-List *
```

---

# Certificate Structure

Every normalized certificate contains the following sections.

```text
Metadata
Identity
Names
Validity
Algorithms
PrivateKey
Usage
Enrollment
Identifiers
AuthorityInformationAccess
CRLDistributionPoints
IdentityMatch
Classification
Validation
Suitability
Recommendation
WinRM
Internal
```

---

# Metadata

Inventory information.

```powershell
$Inventory.Certificates[0].Metadata
```

Contains

```text
InventoryVersion
InventoryTime
Store
StoreLocation
StoreName
```

---

# Identity

Basic certificate identity.

```powershell
$Inventory.Certificates[0].Identity
```

Contains

```text
Subject
CommonName
Issuer
Thumbprint
SerialNumber
FriendlyName
Version
```

Example

```powershell
$Inventory.Certificates[0].Identity.Thumbprint
```

---

# Names

Subject Alternative Name information.

```powershell
$Inventory.Certificates[0].Names
```

Contains

```text
DNS
UPN
Email
URI
IP
Other
Counts

HasDNSNames
HasUPN
HasEmail
HasURI
HasIPAddresses
```

Display DNS names.

```powershell
$Inventory.Certificates[0].Names.DNS
```

---

# Validity

Certificate lifetime.

```powershell
$Inventory.Certificates[0].Validity
```

Contains

```text
NotBefore
NotAfter
DaysRemaining
Expired
ExpiringSoon
```

Find expired certificates.

```powershell
$Inventory.Certificates |
Where-Object {
    $_.Validity.Expired
}
```

---

# Algorithms

Cryptographic algorithms.

```powershell
$Inventory.Certificates[0].Algorithms
```

Contains

```text
PublicKey
Signature
HashAlgorithm
KeyStrength
SignatureStrength
IsWeakKey
IsWeakHash
Summary
```

---

# PrivateKey

Private key information.

```powershell
$Inventory.Certificates[0].PrivateKey
```

Contains

```text
Present
Accessible
Algorithm
Provider
ProviderType
KeyLength
HardwareBacked
Exportable
```

Find certificates with private keys.

```powershell
$Inventory.Certificates |
Where-Object {
    $_.PrivateKey.Present
}
```

---

# Usage

Certificate usage information.

```powershell
$Inventory.Certificates[0].Usage
```

Contains

```text
EKU
KeyUsage
BasicConstraints
Policies
```

---

## Enhanced Key Usage

```powershell
$Inventory.Certificates[0].Usage.EKU
```

Example

```text
ServerAuthentication
ClientAuthentication
CodeSigning
SmartCardLogon
AnyPurpose
```

Find server authentication certificates.

```powershell
$Inventory.Certificates |
Where-Object {
    $_.Usage.EKU.ServerAuthentication
}
```

---

## Key Usage

```powershell
$Inventory.Certificates[0].Usage.KeyUsage
```

Displays parsed key usage flags.

---

## Basic Constraints

```powershell
$Inventory.Certificates[0].Usage.BasicConstraints
```

Example

```text
CertificateAuthority
HasPathLengthConstraint
PathLengthConstraint
Critical
```

---

## Policies

```powershell
$Inventory.Certificates[0].Usage.Policies
```

Displays certificate policy OIDs.

---

# Enrollment

Enrollment information.

```powershell
$Inventory.Certificates[0].Enrollment
```

Contains

```text
Present
Template
Classification
Purpose
EnterprisePKI
AutoEnrollmentLikely
RecommendedForWinRM
Notes
```

---

# Identifiers

Certificate identifiers.

```powershell
$Inventory.Certificates[0].Identifiers
```

Contains

```text
SubjectKeyIdentifier
AuthorityKeyIdentifier
```

---

# Authority Information Access

```powershell
$Inventory.Certificates[0].AuthorityInformationAccess
```

Displays parsed AIA URLs.

---

# CRL Distribution Points

```powershell
$Inventory.Certificates[0].CRLDistributionPoints
```

Displays parsed CRL locations.

---

# IdentityMatch

Computer identity matching.

```powershell
$Inventory.Certificates[0].IdentityMatch
```

Contains

```text
ComputerName
DNSHostName
Domain
FQDN
CandidateNames
MatchedNames
UnmatchedNames

IdentityMatch
MatchType
MatchScore
BestMatch

SubjectMatch
CommonNameMatch
SANMatch
WildcardMatch
```

Find certificates matching the local computer.

```powershell
$Inventory.Certificates |
Where-Object {
    $_.IdentityMatch.IdentityMatch
}
```

---

# Classification

Classification results.

```powershell
$Inventory.Certificates[0].Classification
```

Contains

```text
Source
CertificateType
Enrollment
Trust
Purpose
Tags
Confidence
Notes
```

Display classification.

```powershell
$Inventory.Certificates[0].Classification | Format-List *
```

Display source classification.

```powershell
$Inventory.Certificates[0].Classification.Source
```

Display certificate tags.

```powershell
$Inventory.Certificates[0].Classification.Tags
```

Find Microsoft-managed certificates.

```powershell
$Inventory.Certificates |
Where-Object {
    $_.Classification.Source.MicrosoftManaged
}
```

---

# Validation

Reserved for future validation engine.

Currently returns:

```powershell
$null
```

---

# Suitability

Reserved for future suitability engine.

Currently returns:

```powershell
$null
```

---

# Recommendation

Reserved for future recommendation engine.

Currently returns:

```powershell
$null
```

---

# WinRM

Reserved for future WinRM evaluation engine.

Currently returns:

```powershell
$null
```

---

# Internal

Internal implementation information.

```powershell
$Inventory.Certificates[0].Internal
```

Contains

```text
Thumbprint
Store
RawCertificate
```

The RawCertificate property contains the original
System.Security.Cryptography.X509Certificates.X509Certificate2 object.

This property is intended for advanced troubleshooting and should not be used
for normal inventory operations.

---

# Common Queries

## List certificate subjects

```powershell
$Inventory.Certificates.Identity.Subject
```

---

## List thumbprints

```powershell
$Inventory.Certificates.Identity.Thumbprint
```

---

## Certificates with private keys

```powershell
$Inventory.Certificates |
Where-Object {
    $_.PrivateKey.Present
}
```

---

## Certificates matching this computer

```powershell
$Inventory.Certificates |
Where-Object {
    $_.IdentityMatch.IdentityMatch
}
```

---

## Expired certificates

```powershell
$Inventory.Certificates |
Where-Object {
    $_.Validity.Expired
}
```

---

## Certificates expiring soon

```powershell
$Inventory.Certificates |
Where-Object {
    $_.Validity.ExpiringSoon
}
```

---

## Server Authentication certificates

```powershell
$Inventory.Certificates |
Where-Object {
    $_.Usage.EKU.ServerAuthentication
}
```

---

## Client Authentication certificates

```powershell
$Inventory.Certificates |
Where-Object {
    $_.Usage.EKU.ClientAuthentication
}
```

---

## Root CA certificates

```powershell
$Inventory.Certificates |
Where-Object {
    $_.Classification.CertificateType.IsRootCA
}
```

---

## Enterprise CA certificates

```powershell
$Inventory.Certificates |
Where-Object {
    $_.Classification.Source.EnterpriseCA
}
```

---

## Microsoft-managed certificates

```powershell
$Inventory.Certificates |
Where-Object {
    $_.Classification.Source.MicrosoftManaged
}
```

---

# Object Philosophy

Every engine within ERM returns structured PowerShell objects.

Consumers should query object properties rather than parsing formatted output.

This design enables:

- Automation
- Reporting
- Filtering
- Exporting
- Future engine expansion

while maintaining a stable object model across framework versions.