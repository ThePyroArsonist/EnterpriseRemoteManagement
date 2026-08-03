# Detection Object

## Purpose

The Detection Object is the standardized output produced by every ERM detector.

It represents a single finding derived from one or more engine outputs.

Detections are designed to be:

- immutable
- portable
- machine readable
- human readable
- report friendly

Every detector should return Detection Objects rather than custom PowerShell objects.

---

# Philosophy

Engines collect information.

Detectors analyze information.

Reports present information.

The Detection Object is the contract between those layers.

```
Windows

↓

Engine

↓

Normalized Object

↓

Detector

↓

Detection Object

↓

Report
```

---

# Object Structure

A Detection Object consists of the following logical sections.

```
Metadata
Category
Result
Severity
Confidence
Evidence
Recommendation
References
Internal
```

Each section has a specific purpose.

---

# Metadata

Metadata identifies the detector and when the finding was produced.

Example

```
Metadata

    DetectionId

    Detector

    DetectorVersion

    DetectionTime

    ComputerName
```

Purpose

- auditing
- traceability
- version tracking

---

# Category

Category describes what type of issue was detected.

Example

```
Certificate

Network

Identity

Firewall

Registry

PowerShell

Windows Update

Services
```

Subcategories may also be used.

Example

```
Certificate

↓

WinRM

↓

Identity Matching
```

---

# Result

Result describes the outcome of the evaluation.

Recommended values

```
Pass

Fail

Warning

Informational

Unknown
```

Results should be deterministic.

---

# Severity

Severity indicates operational impact.

Recommended values

```
Informational

Low

Medium

High

Critical
```

Severity answers:

"How serious is this finding?"

Severity does not indicate confidence.

---

# Confidence

Confidence indicates certainty.

Range

```
0 - 100
```

Suggested interpretation

| Score | Meaning |
|--------|---------|
| 100 | Direct evidence |
| 90 | Highly certain |
| 75 | Strong inference |
| 50 | Partial evidence |
| 25 | Weak indication |
| 0 | Unknown |

Confidence allows future detectors to express uncertainty without changing severity.

---

# Summary

Summary is a concise human-readable description.

Example

```
No certificate suitable for WinRM HTTPS was found.
```

Summary should be understandable without reading the remainder of the object.

---

# Description

Description provides additional technical detail.

Example

```
A certificate matching the computer identity could not be located.
The available certificates either lack a Server Authentication EKU,
have no accessible private key, or do not contain the system FQDN.
```

---

# Evidence

Evidence explains why the detector reached its conclusion.

Evidence should always reference normalized engine data.

Example

```
Certificate Thumbprint

Store

Subject

Issuer

SAN

Identity Match

Server Authentication EKU

Private Key

Expiration
```

Evidence should never contain interpretation.

It contains facts.

---

# Recommendation

Recommendation explains how to resolve the finding.

Recommendations should be:

- actionable
- reproducible
- specific

Good

```
Issue a certificate from the enterprise CA containing the system FQDN
and the Server Authentication EKU.
```

Bad

```
Fix the certificate.
```

---

# References

References identify objects involved in the finding.

Examples

```
Certificate Thumbprint

Network Adapter GUID

User SID

Firewall Rule Name

Service Name
```

These references allow findings to be traced back to engine output.

---

# Internal

Internal contains implementation information that should not normally appear in reports.

Examples

```
EngineVersion

RuleId

ExecutionTime

CorrelationData
```

Internal information supports troubleshooting and future debugging.

---

# Example Detection Object

```powershell
[PSCustomObject]@{

    Metadata = [PSCustomObject]@{

        DetectionId = [guid]::NewGuid()

        Detector = "WinRMDetector"

        DetectorVersion = "1.0"

        DetectionTime = Get-Date

        ComputerName = $env:COMPUTERNAME

    }

    Category = [PSCustomObject]@{

        Area = "Certificate"

        Component = "WinRM"

        Rule = "SuitableCertificate"

    }

    Result = "Fail"

    Severity = "High"

    Confidence = 100

    Summary = "No suitable WinRM certificate was found."

    Description = "The system does not contain a certificate meeting all WinRM HTTPS requirements."

    Evidence = [PSCustomObject]@{

        CertificatesEvaluated = 8

        MatchingCertificates = 0

    }

    Recommendation = @(
        "Issue a certificate from the enterprise CA.",
        "Include Server Authentication EKU.",
        "Include the computer FQDN in the SAN."
    )

    References = [PSCustomObject]@{

        CertificateThumbprints = @()

    }

    Internal = [PSCustomObject]@{

        RuleVersion = "1.0"

    }

}
```

---

# Design Principles

Detection Objects should be:

- Immutable
- Strongly Typed
- Deterministic
- Self-Contained
- Machine Readable
- Human Readable
- Report Friendly
- Easily Serialized

---

# Serialization

Detection Objects should serialize cleanly to:

- PowerShell Objects
- JSON
- XML
- CSV (flattened)
- Markdown
- HTML

No detector should require custom serialization logic.

---

# Correlation

Multiple detections may reference the same engine objects.

Example

```
Certificate

↓

WinRM Detector

↓

HTTPS Detector

↓

LDAP Detector
```

Each detector produces independent Detection Objects while referencing the same normalized Certificate Object.

---

# Future Expansion

Additional properties may be added in future schema versions provided they remain backward compatible.

Examples include:

- Compliance Mapping
- MITRE ATT&CK References
- CIS Controls
- Microsoft Security Baselines
- CVE References
- Remediation Scripts
- Documentation Links

---

# Framework Contract

Every detector within ERM must return Detection Objects following this schema.

This guarantees that all reporting, compliance, automation, and orchestration components can consume findings consistently regardless of which detector produced them.