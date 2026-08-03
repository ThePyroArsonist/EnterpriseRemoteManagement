# Design Principles

## Purpose

The Enterprise Remote Management (ERM) framework is designed around a small set of engineering principles that apply to every engine, detector, and reporting component.

These principles define **how code should be written**, **how data should flow**, and **how new functionality should be added**.

The goal is to build a framework that remains understandable, testable, and extensible as it grows.

---

# Core Philosophy

ERM is not a collection of PowerShell scripts.

It is a modular data-processing framework.

Every component has a single responsibility.

```
Discovery
    ↓
Normalization
    ↓
Classification
    ↓
Validation
    ↓
Suitability
    ↓
Recommendation
    ↓
Detection
    ↓
Reporting
```

No stage should perform work that belongs to another stage.

---

# Single Responsibility

Every function should have one job.

Examples

Good

```
Get-ERMCertificateSAN
```

Extracts SAN information only.

Good

```
Get-ERMCertificatePrivateKey
```

Collects private key metadata only.

Bad

```
Get-ERMCertificateInformation
```

- Reads certificates
- Validates them
- Scores them
- Generates recommendations
- Produces reports

Large "do everything" functions become difficult to understand and impossible to test.

---

# Immutable Data

Normalization produces the canonical ERM object.

That object is treated as immutable.

Pipeline stages enrich the object rather than replacing existing data.

Example

```
Certificate
```

↓

```
Certificate.Classification
```

↓

```
Certificate.Validation
```

↓

```
Certificate.Suitability
```

↓

```
Certificate.Recommendation
```

The original normalized data should never be rewritten.

Benefits include:

- deterministic behavior
- easier debugging
- reproducible analysis
- simplified testing

---

# Separation of Concerns

Every stage has clearly defined responsibilities.

| Stage | Responsibility |
|--------|----------------|
| Discovery | Find platform objects |
| Normalization | Extract platform data |
| Classification | Identify object type |
| Validation | Verify correctness |
| Suitability | Evaluate workload fitness |
| Recommendation | Rank candidates |
| Detection | Generate findings |
| Reporting | Present results |

No stage should perform work belonging to another.

---

# Data Before Decisions

ERM separates data collection from decision making.

Example

Normalization collects

```
HasPrivateKey = True
```

Validation determines

```
Private key inaccessible
```

Suitability determines

```
Cannot be used for WinRM
```

Keeping these responsibilities separate prevents duplicated logic throughout the framework.

---

# Deterministic Processing

Given identical input, every engine should produce identical output.

There should be no hidden state and no random behavior.

This guarantees:

- repeatable testing
- reliable automation
- predictable reports
- consistent compliance results

---

# Idempotency

Running an engine multiple times should produce the same result unless the underlying system has changed.

Example

```
Get-ERMCertificateInformation
```

Run today.

Run again one minute later.

Results should be identical except for collection timestamps.

---

# Platform Abstraction

ERM objects abstract away Windows-specific implementation details.

Example

Windows certificate

↓

ERM Certificate Object

Consumers should work with ERM objects rather than raw .NET or PowerShell platform types whenever possible.

This allows engines to evolve without affecting downstream consumers.

---

# Composability

Each engine should be usable independently or combined with other engines.

Examples

```
Get-ERMCertificateInformation
```

```
Get-ERMNetworkInformation
```

```
Get-ERMIdentityInformation
```

A detector can consume one engine or many.

Example

```
Certificate Engine
        +
Identity Engine
        +
Network Engine

↓

WinRM Detector
```

---

# Reusable Components

Shared functionality belongs in reusable helper functions.

Avoid duplicated logic.

Good

```
Get-ERMCertificateIdentityMatch
```

Reusable by:

- WinRM
- HTTPS
- IIS
- SQL Server
- RDP
- LDAP

Bad

Implementing hostname matching separately inside every detector.

---

# Object-Oriented Design

ERM communicates through structured PowerShell objects.

Avoid parsing formatted text whenever possible.

Good

```
Certificate.Validity.DaysRemaining
```

Bad

```
Certificate.Validity -match "Expires in"
```

Structured objects enable reliable scripting and automation.

---

# Strong Typing

Use explicit object structures wherever practical.

Example

```
Certificate.PrivateKey.Accessible
```

instead of

```
"Accessible"
```

Explicit properties improve:

- discoverability
- IntelliSense
- validation
- maintainability

---

# Enterprise Logging

Errors should be logged with sufficient context.

Example

- Thumbprint
- Certificate Subject
- Store
- Function
- Exception

Logs should explain what failed without exposing sensitive information.

---

# Graceful Degradation

One failure should not stop an entire engine.

Example

One malformed certificate should not prevent inventory of the remaining certificates.

Instead:

- log the error
- continue processing
- record the failure

---

# Extensibility

Every engine should be designed for future expansion.

Examples

Current

```
Certificate
```

Future

```
Firewall
Registry
PowerShell
Applications
Services
Event Logs
Windows Update
Hardware
Networking
Identity
```

New engines should require minimal framework changes.

---

# Detector Independence

Detectors should never enumerate Windows resources directly.

Instead

```
Detector

↓

Consumes ERM Engine Output
```

This eliminates duplicate discovery logic across detectors.

---

# Reporting Independence

Reporting components consume completed engine output.

They should never:

- classify
- validate
- score
- recommend

Reports present information—they do not generate it.

---

# Documentation First

Every engine should include documentation covering:

- architecture
- object model
- lifecycle
- public functions
- pipeline stages
- examples

Documentation is considered part of the implementation.

---

# Testing

Every engine should be independently testable.

Example

```
ConvertTo-ERMCertificateObject
```

can be tested without running the classification engine.

Likewise,

```
Get-ERMCertificateClassification
```

can be tested using previously normalized objects.

This isolation simplifies debugging and future development.

---

# Performance

Performance improvements should never reduce correctness.

Priority order:

1. Correctness
2. Reliability
3. Maintainability
4. Performance

Optimization should be evidence-based rather than speculative.

---

# Backward Compatibility

Normalized object structures should evolve carefully.

When changes are required:

- preserve existing properties where practical
- version object schemas
- document breaking changes

Stable object models allow detectors and automation to evolve independently.

---

# Framework Goals

Every ERM component should strive to be:

- Modular
- Deterministic
- Immutable
- Idempotent
- Composable
- Extensible
- Strongly Typed
- Object-Oriented
- Independently Testable
- Enterprise Ready

These principles ensure that every engine behaves consistently, every detector remains reusable, and the framework can continue to grow without increasing complexity.