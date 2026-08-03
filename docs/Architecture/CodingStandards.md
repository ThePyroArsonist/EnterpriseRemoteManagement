# Coding Standards

## Purpose

This document defines the coding standards used throughout the Enterprise Remote Management (ERM) framework.

These standards ensure that all engines, detectors, helper functions, and public commands maintain a consistent structure, style, and level of quality.

Code consistency is considered a feature of the framework.

---

# General Principles

Code should be:

- Readable
- Predictable
- Deterministic
- Self-documenting
- Testable
- Maintainable

Readability always takes precedence over cleverness.

---

# Approved Verbs

Use PowerShell-approved verbs.

Examples

```
Get
Set
New
Remove
ConvertTo
ConvertFrom
Test
Invoke
Write
Read
```

Avoid custom verbs.

---

# Function Naming

Use the ERM prefix consistently.

Examples

```powershell
Get-ERMCertificateInventory

ConvertTo-ERMCertificateObject

Test-ERMWinRMConfiguration

New-ERMDetectionObject
```

Function names should clearly describe a single responsibility.

---

# Single Responsibility

Functions should perform one task.

Good

```powershell
Get-ERMCertificateSAN
```

Bad

```powershell
Get-ERMCertificateEverything
```

---

# Comment-Based Help

Every public function should include:

- Synopsis
- Description
- Parameters
- Outputs
- Examples
- Notes

Private helper functions should include help where complexity warrants it.

---

# Parameter Design

Use:

```powershell
[CmdletBinding()]
```

Prefer explicit parameter types.

Example

```powershell
[string]

[bool]

[int]

[datetime]

[psobject]
```

Avoid untyped parameters unless flexibility is required.

---

# Object Design

Prefer structured objects over flat objects.

Good

```powershell
Certificate.PrivateKey.Accessible
```

Bad

```powershell
CertificatePrivateKeyAccessible
```

Related data should be grouped logically.

---

# Error Handling

Wrap external operations in `try/catch`.

Log meaningful context.

Continue processing where appropriate.

Avoid empty catch blocks unless failure is explicitly acceptable.

---

# Logging

Use the standard ERM logging framework.

Log:

- Function
- Object Identifier
- Error Message
- Timestamp

Do not expose secrets or sensitive information.

---

# Pipeline Compatibility

Public commands should support PowerShell pipeline behavior where appropriate.

Return objects rather than formatted text.

Avoid using `Write-Host` outside development and testing code.

---

# Formatting

Use consistent indentation.

Align hash tables for readability.

Keep line lengths reasonable.

Separate logical sections with blank lines.

---

# Naming Conventions

Variables

```powershell
$Certificate

$Inventory

$Results
```

Avoid abbreviations unless universally understood.

Functions should use PascalCase.

Properties should use PascalCase.

---

# Immutability

Normalized objects should not be modified in place except by adding new enrichment sections during the defined engine lifecycle.

Existing data should not be overwritten.

---

# Strong Typing

Prefer explicit types over loosely typed values.

Represent state using Boolean values rather than strings.

Example

```powershell
Accessible = $true
```

instead of

```powershell
Accessible = "Yes"
```

---

# Return Values

Functions should return objects.

Avoid returning formatted text.

Formatting belongs to the presentation layer.

---

# Testing

Every new function should be validated for:

- Expected Input
- Invalid Input
- Empty Input
- Error Conditions
- Output Schema

Testing should verify both correctness and object structure.

---

# Documentation

Code and documentation evolve together.

Every significant feature should include corresponding documentation updates.

Documentation is considered part of the implementation.

---

# Backward Compatibility

Avoid breaking object contracts.

When schema changes are required:

- Increment versions
- Document changes
- Preserve compatibility where practical

---

# Review Checklist

Before committing code, verify:

- Uses approved PowerShell verbs
- Has a single responsibility
- Includes error handling
- Uses structured objects
- Returns objects instead of formatted output
- Logs meaningful errors
- Follows naming conventions
- Includes documentation
- Passes testing
- Preserves existing object contracts

---

# Framework Philosophy

The ERM framework values:

1. Correctness
2. Reliability
3. Maintainability
4. Consistency
5. Performance

Readable, predictable code is preferred over complex optimizations.

Every contribution should make the framework easier to understand for the next developer.