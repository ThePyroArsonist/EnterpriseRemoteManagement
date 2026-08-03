# Certificate Engine

The ERM Certificate Engine is responsible for discovering, normalizing and analyzing every X.509 certificate present on a Windows system.

The engine is intentionally designed as a multi-stage processing pipeline. Each stage performs a single responsibility and enriches the certificate object without modifying data produced by previous stages.

---

# Goals

The Certificate Engine was designed with the following principles:

- Complete certificate inventory
- Immutable normalized object model
- Separation of discovery and analysis
- Enterprise-scale extensibility
- Consistent output regardless of Windows version
- Reusable analysis pipeline

The engine never performs validation while collecting inventory.

Instead, inventory and analysis are separated into independent stages.

---

# High-Level Architecture

```
Windows Certificate Stores
            │
            ▼
Get-ERMCertificateInventory
            │
            ▼
ConvertTo-ERMCertificateObject
            │
            ▼
Normalized Certificate Object
            │
            ▼
Get-ERMCertificateIdentityMatch
            │
            ▼
Get-ERMCertificateClassification
            │
            ▼
Validation Engine (planned)
            │
            ▼
Suitability Engine (planned)
            │
            ▼
Recommendation Engine (planned)
            │
            ▼
WinRM Evaluation (planned)
```

Each stage enriches the same object.

No stage performs work that belongs to another stage.

---

# Inventory Stage

The inventory stage is responsible for enumerating every certificate store configured by the engine.

Current stores include:

- Cert:\LocalMachine\My
- Cert:\LocalMachine\Root
- Cert:\LocalMachine\CA
- Cert:\LocalMachine\AuthRoot
- Cert:\CurrentUser\My
- Cert:\CurrentUser\Root

Each certificate is converted into the ERM object model before any analysis occurs.

---

# Normalization Stage

Normalization is performed by:

```powershell
ConvertTo-ERMCertificateObject
```

This function creates the canonical ERM Certificate object.

It performs **no validation or decision making**.

Its only responsibility is extracting certificate metadata into a predictable schema.

---

# Analysis Pipeline

After normalization, additional engines enrich the certificate.

Current pipeline:

```
Inventory
↓

Identity Matching

↓

Classification

↓

Validation (planned)

↓

Suitability (planned)

↓

Recommendation (planned)

↓

WinRM Analysis (planned)
```

Each stage writes to a dedicated property.

Example:

```text
IdentityMatch

Classification

Validation

Suitability

Recommendation

WinRM
```

This prevents stages from interfering with each other.

---

# Certificate Object

Every certificate contains the same top-level properties.

```
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

The object structure is considered stable for Certificate Engine v2.

---

# Helper Functions

The normalization layer is intentionally split into small helper functions.

## Identity

```
Get-ERMCertificateIdentity
```

Extracts:

- Subject
- Issuer
- Common Name
- Thumbprint
- Serial Number
- Friendly Name
- Version

---

## Subject Alternative Names

```
Get-ERMCertificateSAN
```

Extracts:

- DNS
- UPN
- Email
- URI
- IP Address
- Other SAN types

Also provides summary counts.

---

## Validity

```
Get-ERMCertificateValidity
```

Calculates:

- NotBefore
- NotAfter
- DaysRemaining
- Expired
- ExpiringSoon

---

## Algorithms

```
Get-ERMCertificateAlgorithms
```

Extracts:

- Public key algorithm
- Signature algorithm
- Hash algorithm
- Key length
- Weak algorithm detection
- Summary

---

## Private Key

```
Get-ERMCertificatePrivateKey
```

Determines:

- Private key exists
- Accessible
- Provider
- Provider type
- Algorithm
- Hardware backed
- Exportable

---

## Enhanced Key Usage

```
Get-ERMCertificateEKU
```

Normalizes EKUs into boolean flags instead of raw OIDs.

Examples:

- Server Authentication
- Client Authentication
- Code Signing
- Smart Card Logon
- Any Purpose

---

## Key Usage

```
Get-ERMCertificateKeyUsage
```

Normalizes key usage flags.

---

## Basic Constraints

```
Get-ERMCertificateBasicConstraints
```

Determines:

- CA certificate
- Path length
- Critical flag

---

## Certificate Template

```
Get-ERMCertificateTemplate
```

Extracts enterprise enrollment information.

Current implementation uses Microsoft's template extensions.

Future versions will include a dedicated ASN.1 parser.

---

## Policies

```
Get-ERMCertificatePolicies
```

Extracts certificate policy OIDs.

---

## Authority Information Access

```
Get-ERMCertificateAuthorityInformationAccess
```

Extracts:

- OCSP URLs
- CA Issuers URLs

---

## CRL Distribution Points

```
Get-ERMCertificateCRLDistributionPoints
```

Extracts CRL URLs.

---

## Identifiers

```
Get-ERMCertificateIdentifiers
```

Extracts:

- Subject Key Identifier
- Authority Key Identifier

---

# Identity Matching

Identity matching compares the certificate against the current computer.

Performed by:

```
Get-ERMCertificateIdentityMatch
```

Comparison includes:

- Computer Name
- DNS Host Name
- FQDN
- Subject
- Common Name
- Subject Alternative Names
- Wildcard Certificates

Outputs:

```
IdentityMatch

MatchScore

BestMatch

MatchedNames

UnmatchedNames

MatchType
```

No suitability decisions are made here.

---

# Classification

Classification categorizes the certificate without deciding whether it should be used.

Performed by:

```
Get-ERMCertificateClassification
```

Classification determines:

- Source
- Certificate Type
- Enrollment Type
- Trust
- Intended Purpose
- Tags
- Confidence
- Notes

Classification never evaluates:

- Expiration
- WinRM suitability
- Recommendation

Those belong to later pipeline stages.

---

# Immutability

Once normalized, certificate metadata is considered immutable.

Analysis engines only populate their own sections:

```
IdentityMatch

Classification

Validation

Suitability

Recommendation

WinRM
```

Existing inventory data should never be modified.

This allows future engines to operate independently.

---

# Planned Engines

## Validation Engine

Responsible for:

- Expiration
- Chain validation
- EKU validation
- Private key validation
- SAN validation
- Template validation

---

## Suitability Engine

Responsible for assigning workload suitability.

Examples:

- WinRM
- IIS
- LDAPS
- RDP
- Client Authentication

---

## Recommendation Engine

Produces remediation guidance.

Examples:

- Renew certificate
- Replace certificate
- Remove duplicate
- Missing SAN
- Weak algorithm
- Missing private key

---

## WinRM Engine

Consumes previous analysis.

Selects the preferred certificate for WinRM HTTPS binding.

This engine will no longer inspect raw certificates.

Instead it relies entirely on normalized data.

---

# Development Philosophy

Every helper function should perform one task.

Every pipeline stage should enrich one section of the object.

Inventory functions should never perform analysis.

Analysis functions should never rediscover certificate information.

Keeping these responsibilities separate allows new engines to be added without changing the inventory layer.

---

# Current Status

| Component | Status |
|-----------|--------|
| Inventory | Complete |
| Object Normalization | Complete |
| Identity Matching | Complete |
| Classification | Complete |
| Validation | Planned |
| Suitability | Planned |
| Recommendation | Planned |
| WinRM Selection | Planned |

Current engine version:

```
ERM Certificate Engine v2
```

The normalized certificate schema is considered stable and will serve as the foundation for all future certificate analysis within ERM.