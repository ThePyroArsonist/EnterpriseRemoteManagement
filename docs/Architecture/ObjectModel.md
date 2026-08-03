# ERM Object Model

## Overview

The Enterprise Remote Management (ERM) framework is built around a normalized object model.

Every engine within ERM produces structured PowerShell objects that follow a consistent architectural pattern regardless of the underlying Windows subsystem.

Examples include:

- Certificate Objects
- Network Objects
- Active Directory Objects
- WinRM Objects
- Operating System Objects
- Hardware Objects

Although the contents of each object differ, they all follow the same design philosophy.

---

# Goals

The ERM object model exists to provide:

- Consistent object structures
- Predictable property names
- Expandable schemas
- Immutable collected data
- Independent analysis layers
- Stable APIs for automation

Consumers should never need to understand native Windows APIs to consume ERM output.

---

# Design Principles

Every ERM object should be:

Deterministic

The same input always produces the same normalized object.

Immutable

Collected information is never modified after normalization.

Self-describing

Objects contain enough metadata to explain where data originated.

Expandable

Future engines may append analysis without changing existing properties.

Serializable

Objects should be safely exported to JSON, XML or CLIXML.

PowerShell Native

Objects should behave like standard PowerShell objects.

---

# General Object Structure

Every normalized object follows the same high-level pattern.

```
Metadata

Identity

Collected Data

Analysis

Recommendations

Internal
```

Each section has a distinct responsibility.

---

# Metadata

Metadata describes the collection process rather than the resource itself.

Typical metadata includes:

- Engine Version
- Inventory Version
- Collection Time
- Source
- Store
- Computer
- Environment

Metadata should never contain analysis.

---

# Identity

Identity uniquely identifies the resource.

Examples

Certificate

```
Thumbprint
Subject
Issuer
Serial Number
```

Computer

```
Hostname
Domain
SID
```

Network

```
Interface GUID
MAC Address
```

Identity should never change after normalization.

---

# Collected Data

Collected data contains facts obtained directly from Windows.

Examples

Certificate

- Validity
- Algorithms
- Extensions
- Private Key
- EKU

Network

- IP Address
- Gateway
- DNS
- MTU

Operating System

- Build
- Version
- Architecture

Collection never includes opinions or recommendations.

---

# Analysis

Analysis is produced by downstream engines.

Examples

Identity Matching

Classification

Validation

Suitability

Compliance

Risk

Analysis engines may populate these sections but may never alter collected data.

---

# Recommendations

Recommendations contain suggested actions.

Examples

Replace

Renew

Remove

Ignore

Preferred

Investigate

Recommendations are derived entirely from analysis.

---

# Internal

Internal contains implementation details required by ERM.

Examples

Raw Windows objects

Native handles

Caching information

Collection metadata

Consumers should generally avoid depending on Internal properties.

---

# Reserved Properties

Objects may contain reserved properties that are initially `$null`.

Example

```
Validation = $null

Suitability = $null

Recommendation = $null

Compliance = $null
```

Future engines populate these properties without changing the object schema.

This guarantees backwards compatibility.

---

# Object Evolution

Normalized objects are expected to evolve over time.

New properties should be added rather than existing properties being renamed or removed.

Breaking schema changes should only occur during major version updates.

---

# Immutability

Normalization completes before any analysis begins.

After normalization:

Allowed

```
Certificate.Validation = ...
```

Allowed

```
Certificate.Classification = ...
```

Not Allowed

```
Certificate.Identity.Subject = ...
```

Not Allowed

```
Certificate.Validity.NotAfter = ...
```

Normalized data always represents the original resource.

---

# Serialization

All ERM objects are designed to serialize cleanly.

Supported formats include:

- JSON
- CLIXML
- XML
- CSV (where applicable)

Objects should avoid exposing unmanaged resources that prevent serialization.

---

# Future Object Types

The same object model will be reused across future engines.

Examples include:

Certificate Object

Network Object

Operating System Object

Domain Object

Active Directory Object

PowerShell Object

TLS Object

Compliance Object

Because every engine follows the same structure, consumers can automate against ERM consistently regardless of subsystem.

---

# Summary

The ERM object model provides a stable contract between collection engines, analysis engines and consumers.

By separating collected data from analysis and recommendations, ERM achieves:

- deterministic inventories
- immutable normalized objects
- independent engines
- long-term compatibility
- enterprise scalability

This object model forms the foundation of the entire ERM framework.