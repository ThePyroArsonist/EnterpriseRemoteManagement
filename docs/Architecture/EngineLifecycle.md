# ERM Engine Lifecycle

## Purpose

Every Enterprise Remote Management (ERM) engine follows the same lifecycle.

The objective is to ensure every engine is:

- deterministic
- immutable
- composable
- independently testable
- reusable by future detectors

The Certificate Engine is the reference implementation for this architecture.

---

# Philosophy

An engine should never attempt to do everything at once.

Instead, each stage has one responsibility.

```
Raw Data
    │
    ▼
Normalization
    │
    ▼
Classification
    │
    ▼
Validation
    │
    ▼
Suitability
    │
    ▼
Recommendation
    │
    ▼
Detection Engine
```

Each stage enriches the object.

No stage modifies data produced by earlier stages.

---

# Stage 1 — Discovery

Purpose:

Locate every object that may be analyzed.

Examples:

Certificate Engine

- Enumerate certificate stores
- Read X509 certificates

Network Engine

- Enumerate adapters
- Enumerate IP configuration

Identity Engine

- Enumerate users
- Enumerate groups

Output:

Raw platform objects.

---

# Stage 2 — Normalization

Purpose:

Convert platform-specific objects into ERM objects.

Examples:

Windows certificate

↓

ERM Certificate Object

Windows NIC

↓

ERM Network Object

Normalization never makes decisions.

It simply extracts information.

Examples:

Subject

Issuer

SAN

Algorithms

Private Key

Validity

Template

Extensions

Metadata

---

# Stage 3 — Classification

Purpose

Determine what the object represents.

Classification answers questions like:

What is this?

Examples

Certificate

- Enterprise CA
- Microsoft Managed
- Third Party
- Self Signed

Network

- Physical
- Virtual
- Wireless
- VPN

Identity

- Domain
- Local
- Managed

Classification should never determine health.

It only categorizes.

---

# Stage 4 — Validation

Purpose

Determine correctness.

Examples

Certificate

- expired
- weak algorithm
- invalid chain
- missing SAN
- inaccessible key

Network

- duplicate IP
- invalid gateway

Identity

- disabled
- expired
- locked

Validation reports facts.

It does not make recommendations.

---

# Stage 5 — Suitability

Purpose

Determine whether the object is suitable for a workload.

Example

WinRM HTTPS

Questions include:

Has private key?

Server Authentication?

Identity matches computer?

Trusted?

Chain valid?

Key accessible?

Suitability returns a score and explanation.

Suitability is workload specific.

Future examples

LDAP

Kerberos

HTTPS

Code Signing

VPN

Smart Card

---

# Stage 6 — Recommendation

Purpose

Choose the preferred object.

Example

If several certificates satisfy WinRM requirements:

Certificate A

92%

Certificate B

81%

Certificate C

74%

Recommendation selects Certificate A.

Recommendation never changes the certificate.

It only ranks candidates.

---

# Stage 7 — Detection

Purpose

Produce findings.

Detection engines consume completed objects.

Example

Certificate object

↓

WinRM Detector

↓

Finding:

No suitable WinRM certificate.

or

Recommended certificate expires in 9 days.

Detection engines never enumerate certificates.

They consume engine output.

---

# Stage 8 — Reporting

Purpose

Produce human-readable output.

Examples

JSON

PowerShell objects

Markdown

Compliance reports

REST API

The reporting layer never modifies objects.

---

# Immutability

The normalized object is treated as immutable.

Each pipeline stage only appends information.

Example

```

Identity

↓

Classification

↓

Validation

↓

Suitability

↓

Recommendation

```

Earlier properties should never be rewritten.

This guarantees deterministic processing.

---

# Pipeline Independence

Every stage can execute independently.

Example

```

$Certificate =
ConvertTo-ERMCertificateObject

```

Only normalization.

```

$Certificate =
ConvertTo-ERMCertificateObject

$Certificate.Classification =
Get-ERMCertificateClassification

```

Normalization + Classification.

```

$Certificate =
ConvertTo-ERMCertificateObject

...

$Certificate.WinRM =
Get-ERMCertificateSuitability

```

Entire pipeline.

---

# Future Engines

Every ERM engine should follow this lifecycle.

Examples

System Engine

Identity Engine

Network Engine

PowerShell Engine

Domain Engine

Compatibility Engine

Windows Update Engine

Event Log Engine

Application Engine

Firewall Engine

Service Engine

Registry Engine

Hardware Engine

Each engine produces:

- normalized objects

- immutable enrichment

- reusable detection data

---

# Design Goals

Every engine should be:

- deterministic

- idempotent

- immutable

- reusable

- composable

- independently testable

- workload agnostic

- PowerShell object based

- detector friendly

The result is a consistent framework where every engine behaves identically regardless of the underlying Windows subsystem.