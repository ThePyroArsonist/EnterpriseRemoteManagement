# ERM Certificate Engine Pipeline

## Overview

The ERM Certificate Engine is intentionally designed as a multi-stage pipeline.

Each stage has a single responsibility.

Stages never duplicate work.

Stages never modify previous analysis except by populating their own output
section.

The normalized certificate object acts as the shared contract between every
stage.

---

# Pipeline

```
Windows Certificate Store
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
            ├──────────────┐
            ▼              ▼
Identity Match      Classification
            │              │
            └──────┬───────┘
                   ▼
            Validation Engine
                   ▼
          Suitability Engine
                   ▼
        Recommendation Engine
                   ▼
          WinRM Evaluation
                   ▼
       Final Inventory Object
```

---

# Stage 1

## Inventory

Responsible Function

```
Get-ERMCertificateInventory
```

Responsibilities

- Enumerate certificate stores
- Enumerate certificates
- Build inventory statistics
- Record enumeration errors

Does NOT

- validate certificates
- classify certificates
- score certificates

---

# Stage 2

## Normalization

Responsible Function

```
ConvertTo-ERMCertificateObject
```

Purpose

Convert every X509Certificate2 object into the ERM object model.

Every downstream engine consumes this object.

Normalization is deterministic.

No decisions are made.

---

Normalizes

Identity

Names

Validity

Algorithms

Private Key

Usage

Enrollment

Identifiers

AIA

CRL

Internal Metadata

---

Never Performs

Validation

Classification

Suitability

Recommendations

WinRM analysis

---

# Stage 3

## Identity Engine

Responsible Function

```
Get-ERMCertificateIdentityMatch
```

Purpose

Determine whether the certificate belongs to the current computer.

Produces

```
Certificate.IdentityMatch
```

This stage compares

- Subject
- Common Name
- SAN
- DNS
- Wildcards
- FQDN
- NetBIOS

---

# Stage 4

## Classification Engine

Responsible Function

```
Get-ERMCertificateClassification
```

Purpose

Determine what the certificate is.

Produces

```
Certificate.Classification
```

Classification includes

Source

Certificate Type

Enrollment

Trust

Purpose

Confidence

Tags

Notes

Classification never determines

Good

Bad

Preferred

Usable

Secure

Those belong to later engines.

---

# Stage 5

## Validation Engine

(Currently Reserved)

Will populate

```
Certificate.Validation
```

Future checks

Chain validation

Revocation

Expiration

Unknown Critical Extensions

Unsupported Algorithms

Policy Validation

Signature Validation

---

# Stage 6

## Suitability Engine

(Currently Reserved)

Will populate

```
Certificate.Suitability
```

Determines

Best HTTPS certificate

Best WinRM certificate

Best IIS certificate

Best RDP certificate

Best LDAPS certificate

Best Client certificate

Multiple suitability profiles may exist simultaneously.

---

# Stage 7

## Recommendation Engine

(Currently Reserved)

Produces

```
Certificate.Recommendation
```

Examples

Renew

Replace

Ignore

Investigate

Remove

Use for WinRM

Use for IIS

Use for RDP

---

# Stage 8

## WinRM Engine

(Currently Reserved)

Produces

```
Certificate.WinRM
```

Future evaluation includes

HTTPS compatibility

Private key

Server Authentication EKU

Identity match

Chain trust

Key length

Algorithm strength

Certificate expiration

---

# Pipeline Rules

Every stage

reads

```
Certificate
```

Every stage

writes only

its own section.

Example

```
Identity Engine

writes

Certificate.IdentityMatch
```

Classification

writes

```
Certificate.Classification
```

Validation

writes

```
Certificate.Validation
```

No stage overwrites another stage.

---

# Immutability

The normalized object should be treated as immutable.

Stages may only populate their own reserved property.

Example

Valid

```
Certificate.Validation = ...
```

Invalid

```
Certificate.Identity.Subject = ...
```

or

```
Certificate.Names.DNS += ...
```

Identity never changes after normalization.

---

# Engine Expansion

Because every stage is isolated, additional engines can be inserted without
breaking compatibility.

Examples

Certificate Risk Engine

Certificate Compliance Engine

Certificate Security Baseline

Certificate Vulnerability Scanner

Certificate Chain Analyzer

PKI Health Engine

Template Analyzer

AutoEnrollment Diagnostics

Each engine simply writes to its own property.

---

# Design Principles

The Certificate Engine follows several architectural rules.

Single Responsibility

Each function performs one task.

Deterministic

Normalization always produces the same object.

Immutable

Identity information is never modified.

Composable

New engines can be inserted without changing existing ones.

Extensible

Additional analysis layers are expected over time.

Enterprise First

Designed for very large enterprise PKI environments.

PowerShell Native

No external dependencies are required.