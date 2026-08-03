# Engine Development Guide

## Purpose

This document defines the standard process for developing new Enterprise Remote Management (ERM) engines.

Every engine within ERM should follow the same architecture, lifecycle, naming conventions, and object model.

The Certificate Engine serves as the reference implementation for all future engines.

---

# What is an Engine?

An engine is responsible for collecting, normalizing, and enriching information from a specific Windows subsystem.

Examples include:

- Certificate Engine
- Network Engine
- Identity Engine
- System Engine
- Registry Engine
- Firewall Engine
- Services Engine
- Event Log Engine
- Windows Update Engine

An engine never performs compliance checks or generates findings.

Those responsibilities belong to detectors.

---

# Standard Engine Pipeline

Every engine should follow the same lifecycle.

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
```

Each stage has exactly one responsibility.

---

# Engine Responsibilities

An engine should:

- Discover Windows resources
- Normalize platform data
- Enrich objects
- Produce immutable objects
- Expose reusable information
- Remain detector agnostic

An engine should never:

- Generate findings
- Perform compliance reporting
- Write reports
- Make configuration changes
- Modify Windows settings

---

# Folder Structure

Recommended layout:

```
Private/

    Get-ERM<Engine>Inventory.ps1

Public/

    Get-ERM<Engine>Information.ps1

Documentation/

    <Engine>.md

    <Engine>Object.md
```

Helper functions should remain private unless intended for reuse outside the engine.

---

# Public Interface

Every engine should expose a single public entry point.

Example

```powershell
Get-ERMCertificateInformation
```

Future examples

```powershell
Get-ERMNetworkInformation

Get-ERMFirewallInformation

Get-ERMRegistryInformation
```

Consumers should never call internal helper functions directly.

---

# Normalized Objects

Every engine must define a canonical object.

Example

```
Certificate Object

Network Object

Identity Object
```

The object should contain structured sections rather than flat properties.

Example

```
Metadata

Identity

Configuration

Validation

Internal
```

---

# Pipeline Enrichment

Objects are enriched as they move through the pipeline.

Example

```
Normalized Object

↓

Classification

↓

Validation

↓

Suitability

↓

Recommendation
```

Earlier stages must not be modified by later stages.

---

# Strong Typing

Prefer structured PowerShell objects.

Good

```powershell
Certificate.Validity.Expired
```

Bad

```powershell
Certificate.Status
```

Structured data is easier to consume programmatically.

---

# Logging

Every engine should use the standard ERM logging framework.

Logs should include sufficient context to troubleshoot failures.

Recommended information:

- Engine
- Function
- Object Identifier
- Error
- Timestamp

Logging should never interrupt processing of unrelated objects.

---

# Error Handling

Errors should be isolated.

If one object cannot be processed:

- Record the error
- Log the details
- Continue processing

Avoid terminating the engine unless discovery itself fails.

---

# Performance

Performance optimizations should preserve:

- Correctness
- Readability
- Testability

Optimize only after measuring.

---

# Versioning

Each normalized object should include an inventory version.

Example

```powershell
Metadata.InventoryVersion = "2.0"
```

Schema changes should increment the version and be documented.

---

# Testing

Every engine should include development tests covering:

- Discovery
- Normalization
- Classification
- Validation
- Suitability
- Recommendation

Tests should validate object structure as well as data correctness.

---

# Documentation Requirements

Every engine should include:

- Engine overview
- Object schema
- Pipeline description
- Public functions
- Examples
- Known limitations
- Version history

Documentation is part of the implementation.

---

# Naming Conventions

Use consistent PowerShell naming.

Examples

```powershell
Get-ERMCertificateInventory

ConvertTo-ERMCertificateObject

Get-ERMCertificateClassification

Get-ERMCertificateValidation
```

Use approved PowerShell verbs wherever possible.

---

# Extensibility

Design every engine with future expansion in mind.

Prefer adding new object sections over changing existing ones.

Keep object contracts stable.

---

# Framework Contract

Every ERM engine must:

- Follow the standard lifecycle
- Produce immutable normalized objects
- Remain independent of detectors
- Expose a single public entry point
- Use structured PowerShell objects
- Support logging and isolated error handling
- Include comprehensive documentation

Following these standards ensures that every engine behaves consistently and can be consumed interchangeably by detectors, reporting components, and future automation.