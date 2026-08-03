# Detector Development Guide

## Purpose

This document defines the standards for developing detectors within the Enterprise Remote Management (ERM) framework.

Detectors consume normalized engine objects and transform them into actionable findings.

Unlike engines, detectors never communicate directly with Windows.

The Certificate Engine and future WinRM Detector serve as the reference implementation for this architecture.

---

# What is a Detector?

A detector evaluates one or more normalized engine objects to determine whether a specific condition exists.

Examples include:

- WinRM HTTPS
- RDP Configuration
- IIS HTTPS
- LDAP TLS
- SQL Server Encryption
- BitLocker Compliance
- Firewall Configuration
- Windows Update Compliance
- Local Administrator Audit

A detector never discovers Windows resources.

---

# Detector Pipeline

Every detector follows the same execution model.

```
Engine Output

↓

Evaluation

↓

Evidence Collection

↓

Recommendation

↓

Detection Object
```

The detector consumes data rather than producing it.

---

# Responsibilities

A detector should:

- Consume normalized engine objects
- Evaluate configuration
- Correlate multiple engines
- Produce standardized Detection Objects
- Generate recommendations
- Calculate confidence

A detector should never:

- Read Windows resources
- Enumerate certificates
- Query Active Directory
- Parse registry values
- Duplicate engine logic
- Modify configuration

---

# Input

Detectors consume normalized ERM objects.

Example

```powershell
$Certificates

$Network

$Identity

$System
```

All inputs should already be normalized and classified.

---

# Evaluation

Detectors should evaluate facts rather than collecting them.

Example

Good

```powershell
if ($Certificate.PrivateKey.Accessible)
```

Bad

```powershell
Get-ChildItem Cert:\...
```

---

# Correlation

Detectors may combine information from multiple engines.

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

Each engine remains independent.

---

# Evidence

Every finding should include supporting evidence.

Examples

- Certificate Thumbprint
- Store
- Subject
- SAN
- Identity Match
- EKUs
- Private Key Status

Evidence should consist of facts, not conclusions.

---

# Recommendations

Recommendations should explain how to resolve the finding.

Good

```
Issue an Enterprise CA certificate containing the system FQDN and Server Authentication EKU.
```

Bad

```
Certificate is wrong.
```

Recommendations should be specific and actionable.

---

# Confidence

Every detector should estimate confidence.

Suggested guidance:

| Score | Meaning |
|--------|---------|
| 100 | Direct evidence |
| 90 | Highly certain |
| 75 | Strong inference |
| 50 | Partial evidence |
| 25 | Weak indication |
| 0 | Unknown |

Confidence reflects certainty—not severity.

---

# Severity

Recommended values:

- Informational
- Low
- Medium
- High
- Critical

Severity reflects operational impact.

---

# Stateless Design

Detectors should be stateless.

Running a detector twice against identical engine output should produce identical Detection Objects.

---

# Error Handling

Errors should affect only the current evaluation.

If one object cannot be evaluated:

- Record the failure
- Log the reason
- Continue evaluating remaining objects

---

# Performance

Prefer filtering engine objects over repeatedly scanning collections.

Example

```powershell
$Candidates = $Certificates |
    Where-Object {
        $_.Usage.EKU.ServerAuthentication
    }
```

Avoid unnecessary rescanning.

---

# Documentation

Every detector should include:

- Purpose
- Inputs
- Outputs
- Evaluation Rules
- Evidence
- Recommendations
- Examples
- Limitations

---

# Testing

Each detector should include tests covering:

- Success
- Failure
- Warning
- Unknown
- Empty Input
- Invalid Input

Detectors should be independently testable.

---

# Framework Contract

Every detector within ERM must:

- Consume normalized engine objects
- Produce Detection Objects
- Remain deterministic
- Remain stateless
- Avoid Windows enumeration
- Include evidence
- Include recommendations
- Support isolated testing

Following these standards ensures detectors remain reusable, predictable, and independent from engine implementation.