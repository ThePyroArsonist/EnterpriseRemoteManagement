# Enterprise Remote Management (ERM)

Enterprise Remote Management (ERM) is an enterprise PowerShell framework for collecting, analyzing and validating Windows configuration data.

The project is designed around independent inventory engines that normalize Windows resources into a consistent object model before analysis is performed.

The first completed engine is the **Certificate Engine**, which inventories every certificate on a Windows system and prepares the data for validation, suitability analysis and WinRM certificate selection.

---

# Design Goals

ERM follows several architectural principles:

- Inventory first
- Normalize once
- Analyze later
- Immutable data model
- Modular analysis pipeline
- Enterprise-scale extensibility

Rather than mixing discovery and validation together, every engine follows the same lifecycle:

```

Discovery
↓

Normalization
↓

Classification
↓

Validation
↓

Suitability Analysis
↓

Recommendations
↓

Consumers

```

Each stage only performs one responsibility.

---

# Current Engines

| Engine | Status |
|---------|--------|
| Certificate Engine | Complete (v2 Inventory) |
| WinRM Engine | Planned |
| Network Engine | Existing |
| Active Directory Engine | Existing |
| System State Engine | Existing |

---

# Certificate Engine

The Certificate Engine inventories every certificate from the Windows certificate stores and converts them into a normalized ERM Certificate object.

The engine intentionally separates:

- Inventory
- Classification
- Validation
- Suitability
- Recommendation
- WinRM analysis

Each stage enriches the same immutable object.

Example:

```powershell
$Inventory = Get-ERMCertificateInformation -Raw

$Inventory.Certificates
```

---

# Object Pipeline

```

Windows Certificate

↓

ConvertTo-ERMCertificateObject

↓

Normalized Certificate Object

↓

Identity Matching

↓

Classification

↓

Validation

↓

Suitability

↓

Recommendation

↓

WinRM Selection

```

---

# Why Normalize?

Windows exposes certificates differently depending on:

- Store
- Provider
- PowerShell version
- .NET version
- Windows version

ERM converts every certificate into a single predictable schema.

This allows downstream analysis to ignore Windows implementation details.

---

# Project Structure

```

EnterpriseRemoteManagement/

Private/
Certificate engine
Analysis functions
Internal helpers

Public/
Public cmdlets

Development/
Testing tools

docs/
Architecture documentation

```

---

# Current Public Commands

```powershell
Get-ERMSystemState

Get-ERMNetworkInformation

Get-ERMActiveDirectoryInformation

Get-ERMCertificateInformation
```

Development builds may expose additional testing functions.

---

# Certificate Inventory Example

```powershell
$Inventory = Get-ERMCertificateInformation -Raw

$Inventory.Certificates.Count
```

Retrieve a certificate:

```powershell
$Inventory.Certificates[0]
```

Inspect identity:

```powershell
$Inventory.Certificates[0].Identity
```

Inspect SANs:

```powershell
$Inventory.Certificates[0].Names
```

Inspect EKUs:

```powershell
$Inventory.Certificates[0].Usage.EKU
```

Inspect classification:

```powershell
$Inventory.Certificates[0].Classification
```

Inspect identity matching:

```powershell
$Inventory.Certificates[0].IdentityMatch
```

---

# Architecture Philosophy

ERM avoids large monolithic functions.

Instead:

- one inventory function
- one classifier
- one validator
- one suitability engine
- one recommendation engine

Each component can evolve independently.

---

# Current Status

Certificate Engine v2 currently implements:

✓ Inventory

✓ Normalization

✓ Identity Matching

✓ Classification

Validation Engine (planned)

Suitability Engine (planned)

Recommendation Engine (planned)

WinRM Selection Engine (planned)

---

# Version

Current engine version:

```

Certificate Engine v2

```

The object schema is considered stable.

Future work will extend the analysis pipeline without breaking the inventory model.