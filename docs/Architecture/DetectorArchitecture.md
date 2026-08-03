# Detector Architecture

## Purpose

Detectors are responsible for transforming engine output into actionable findings.

Unlike engines, detectors do not enumerate Windows resources.

Instead, they consume normalized ERM objects produced by one or more engines.

This separation allows discovery, analysis, and reporting to evolve independently.

---

# Responsibilities

A detector should:

- consume one or more engine outputs
- evaluate configuration or compliance
- generate findings
- calculate severity
- recommend remediation
- produce detection objects

A detector should never:

- enumerate Windows resources
- collect platform information
- parse raw Windows APIs
- duplicate engine logic

---

# Data Flow

```

Windows

↓

Engine

↓

Normalized Objects

↓

Detector

↓

Findings

↓

Report

```

---

# Example

Certificate Engine

↓

Certificate Objects

↓

WinRM Detector

↓

Finding

```

No suitable certificate available for WinRM HTTPS.

```

The detector never opens certificate stores.

---

# Multiple Engine Support

Detectors may consume multiple engines.

Example

```

Certificate Engine

↓

Network Engine

↓

Identity Engine

↓

WinRM Detector

```

The detector correlates information rather than collecting it.

---

# Detection Object

Each detector returns a standardized finding.

Example

```

Detection

    Name

    Category

    Severity

    Result

    Confidence

    Recommendation

    References

    Evidence

```

Detections are immutable and may be exported directly.

---

# Severity

Recommended severity levels

- Informational
- Low
- Medium
- High
- Critical

Severity reflects operational impact rather than implementation complexity.

---

# Confidence

Confidence indicates how certain the detector is.

Example

100

Direct evidence.

80

Strong inference.

50

Partial evidence.

20

Weak indication.

---

# Recommendation

Recommendations should be:

- actionable
- specific
- reproducible

Example

Good

```

Issue a Server Authentication certificate containing the computer FQDN.

```

Bad

```

Certificate problem.

```

---

# Evidence

Every finding should include evidence supporting the conclusion.

Examples

- Certificate thumbprint
- Store
- Subject
- SAN
- Identity mismatch
- Missing EKU

Evidence should allow the finding to be independently verified.

---

# Detector Independence

Detectors should remain independent of each other.

One detector should never call another detector.

If shared logic is required, it belongs in an engine or helper function.

---

# Extensibility

Future detectors may include:

- WinRM
- RDP
- IIS
- LDAP
- SQL Server
- Hyper-V
- Active Directory
- Defender
- BitLocker
- Firewall
- Credential Guard

All detectors should follow the same architecture.

---

# Design Goals

Every detector should be:

- Stateless
- Deterministic
- Independent
- Evidence Based
- Explainable
- Testable
- Reusable

Detectors transform engine data into operational intelligence without becoming responsible for data collection.