# Enterprise Remote Management (ERM) Architecture

## Overview

Enterprise Remote Management (ERM) is an enterprise-focused PowerShell framework for collecting, normalizing, analyzing, and evaluating Windows infrastructure.

Rather than exposing raw operating system data directly, ERM converts every information source into a normalized object model that can be processed consistently by multiple analysis engines.

The framework is designed around several core principles:

- Deterministic collection
- Immutable normalized objects
- Independent analysis engines
- Expandable architecture
- Enterprise scalability
- PowerShell-native implementation

The result is a framework that separates data collection from analysis, allowing new engines to be introduced without modifying existing functionality.

---

# Architecture

```
                    Windows
                       │
        ┌──────────────┼──────────────┐
        │              │              │
        ▼              ▼              ▼
 Certificates      Network        Active Directory
        │              │              │
        └──────────────┼──────────────┘
                       ▼
               Collection Engines
                       │
                       ▼
              Normalized Objects
                       │
       ┌───────────────┼───────────────┐
       ▼               ▼               ▼
 Identity Engine  Classification  Validation
       │               │               │
       └───────────────┼───────────────┘
                       ▼
              Suitability Engines
                       │
                       ▼
           Recommendation Engines
                       │
                       ▼
               Final ERM Objects
```

---

# Design Philosophy

ERM follows a layered architecture.

Each layer performs exactly one responsibility.

Layers never duplicate work performed by another layer.

Each stage receives normalized objects and produces additional analysis.

No stage modifies information produced by an earlier stage.

---

# Collection Layer

Collection is responsible for retrieving information from Windows.

Examples include:

- Certificate Stores
- Active Directory
- Network Configuration
- WinRM Configuration
- Operating System
- Hardware
- PowerShell
- Domain Membership

Collection never performs analysis.

Its only responsibility is obtaining information.

---

# Normalization Layer

Normalization converts platform-specific objects into ERM objects.

Example

```
X509Certificate2

↓

ERM Certificate Object
```

After normalization every engine works exclusively with ERM objects.

The original Windows object is preserved internally when required but is never modified.

---

# Analysis Layer

Analysis engines enrich normalized objects.

Examples include:

Identity Matching

Classification

Validation

Suitability

Recommendations

Compliance

Risk

Analysis engines never change normalized data.

They only populate their own reserved properties.

---

# Immutable Object Model

One of the core architectural principles is immutability.

Once normalization has completed, identity information never changes.

For example

```
Certificate.Identity.Subject
```

must remain identical for the lifetime of the object.

Analysis engines may add

```
Certificate.Validation
```

or

```
Certificate.Classification
```

but must never modify

```
Certificate.Identity
```

This guarantees deterministic behaviour across the entire pipeline.

---

# Pipeline Architecture

ERM uses a sequential processing pipeline.

```
Discovery

↓

Normalization

↓

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

Each stage has one responsibility.

Each stage can be independently tested.

Each stage can be independently replaced.

---

# Engine Independence

Every engine operates independently.

For example

The Validation Engine does not perform classification.

The Classification Engine does not generate recommendations.

The Recommendation Engine does not determine identity.

Responsibilities never overlap.

This greatly simplifies maintenance and testing.

---

# Reserved Object Properties

Normalized objects contain reserved properties for future engines.

Example

```
Validation
Suitability
Recommendation
WinRM
Compliance
Risk
```

Initially these properties may be `$null`.

As additional engines are introduced they become populated without changing the object schema.

This allows backwards-compatible expansion.

---

# Enterprise First

ERM is designed for enterprise environments.

Architectural decisions prioritize:

- Predictable behaviour
- Large inventories
- Multiple certificate authorities
- Active Directory environments
- Hybrid cloud environments
- Long-term maintainability

Consumer-oriented shortcuts are intentionally avoided.

---

# Error Handling

Collection failures should never terminate an inventory.

Instead:

- Errors are recorded
- Collection continues
- Partial inventories remain usable

This approach maximizes usable information during enterprise diagnostics.

---

# Logging

Every engine may emit diagnostic information through the shared logging subsystem.

Logging is intended to support:

- Troubleshooting
- Engine development
- Inventory diagnostics
- Performance analysis

Logging never changes engine behaviour.

---

# Extensibility

New engines should require no modification to existing engines.

Examples include:

Certificate Compliance Engine

Certificate Risk Engine

Network Compliance Engine

TLS Configuration Engine

Security Baseline Engine

PKI Health Engine

WinRM Configuration Engine

Each new engine simply reads the normalized object and writes to its own reserved property.

---

# Testing Philosophy

Each engine should be testable in isolation.

Example:

Normalization tests verify object construction.

Classification tests verify classification only.

Validation tests verify validation only.

This separation significantly reduces regression risk.

---

# Long-Term Vision

ERM is intended to become a modular enterprise diagnostics framework.

Future capabilities include:

- Compliance analysis
- Risk assessment
- Configuration drift detection
- PKI diagnostics
- WinRM automation
- Security baselines
- Reporting
- Remediation guidance

All future functionality will build upon the same normalized object model and immutable pipeline architecture established by the Certificate Engine.