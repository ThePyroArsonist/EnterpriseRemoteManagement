# Roadmap

## Vision

Enterprise Remote Management is designed as a modular assessment framework for
Windows enterprise environments.

Rather than focusing on a single technology, ERM builds normalized inventory
objects that independent engines can analyze.

The long-term goal is to provide enterprise-grade configuration assessment,
security validation and remediation guidance.

---

# Current Status

## Core Framework

Status

Complete (v1)

Includes:

- Modular architecture
- Engine pipeline
- Immutable inventory objects
- Detection framework
- Structured logging
- Documentation foundation

---

## Certificate Engine

Status

Feature Complete (v1)

Implemented:

- Certificate inventory
- SAN parsing
- Identity matching
- Template detection
- Private key inspection
- Algorithm analysis
- EKU parsing
- Policy parsing
- Authority Information Access
- CRL Distribution Points
- Certificate classification

Remaining work:

- Validation Engine
- Suitability Engine
- Recommendation Engine
- WinRM Selection Engine
- Enterprise Template Parser v2

---

# Planned Engines

## WinRM Engine

Purpose

Evaluate WinRM configuration.

Planned features

- Listener enumeration
- HTTPS validation
- Authentication configuration
- Encryption settings
- Certificate binding validation

---

## Network Engine

Purpose

Collect network configuration.

Planned inventory

- Interfaces
- DNS
- Gateways
- Routes
- Adapters
- VLAN information

---

## Active Directory Engine

Purpose

Collect enterprise identity information.

Planned features

- Domain membership
- Forest information
- Sites
- Trusts
- Domain Controllers
- Functional levels

---

## PowerShell Engine

Purpose

Evaluate PowerShell environment.

Planned features

- Version
- Language mode
- Execution policy
- Modules
- PSRemoting

---

## Operating System Engine

Purpose

Collect operating system inventory.

Planned features

- Installed features
- Services
- Scheduled tasks
- Installed roles
- Licensing

---

## Security Engine

Purpose

Evaluate host security posture.

Potential checks

- Credential Guard
- Device Guard
- BitLocker
- Defender
- Firewall
- Secure Boot
- TPM
- LAPS

---

## Compliance Engine

Purpose

Evaluate enterprise standards.

Examples

- CIS Benchmarks
- Internal standards
- WinRM compliance
- PKI compliance

---

## Detection Framework

Status

Foundation Complete

Future detectors include

- Expired certificates
- Weak cryptography
- Missing private keys
- Duplicate certificates
- Incorrect EKUs
- Certificate chain issues
- WinRM certificate suitability
- ADCS misconfiguration
- Auto-enrollment failures

---

# Version 2 Goals

Certificate Engine

- ASN.1 template parser
- Extension framework
- Chain validation
- Revocation evaluation
- Trust scoring
- Policy engine
- Rich recommendation engine

Framework

- Engine dependency graph
- Parallel execution
- Object versioning
- Performance metrics
- Plugin model
- Configuration profiles

---

# Long-Term Vision

ERM is intended to become an enterprise assessment platform.

Future capabilities may include:

- Multi-engine inventory collection
- Unified object model
- Detection pipeline
- Compliance reporting
- Risk scoring
- Automatic remediation guidance
- Historical comparisons
- Scheduled assessments
- HTML reports
- JSON exports
- REST API integration
- CI/CD validation
- Desired State Configuration integration

---

# Guiding Principles

Every new feature should satisfy the following goals:

- Modular
- Immutable
- Testable
- Enterprise-focused
- Well documented
- Easily extensible
- Independent of user interface
- Suitable for automation

Architecture decisions should prioritize long-term maintainability over short-term convenience.

---

# Current Development Priority

1. Complete Certificate Engine v1
2. Validation Engine
3. Suitability Engine
4. Recommendation Engine
5. WinRM Selection Engine
6. Detector expansion
7. WinRM Engine
8. Active Directory Engine
9. Network Engine
10. Security Engine
11. Reporting Engine
12. Enterprise Template Parser v2