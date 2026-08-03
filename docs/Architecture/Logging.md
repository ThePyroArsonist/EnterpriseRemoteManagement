# Logging

## Purpose

The Enterprise Remote Management (ERM) framework uses a centralized logging
system to provide consistent diagnostic, troubleshooting and development
information across every engine.

Logging is intended for developers and administrators.

Business logic should never write directly to the console.

Instead every component should emit structured messages through:

```powershell
Write-ERMLog
```

This allows logging behavior to evolve without modifying every detector.

---

# Logging Philosophy

Logging should answer four questions:

1. What is happening?
2. Why did it happen?
3. Was it successful?
4. How long did it take?

Good logs describe decisions.

Bad logs simply repeat code execution.

Example:

```
Enumerating LocalMachine\My certificate store.
```

Better:

```
Enumerating LocalMachine\My certificate store (expected WinRM candidate certificates).
```

---

# Log Levels

## Information

Normal execution.

Examples

- Beginning inventory
- Store enumeration
- Detector execution
- Engine completion

Example

```
Starting certificate inventory.
```

---

## Verbose

Developer diagnostics.

Examples

- Parsing SAN extension
- Reading EKU
- Chain construction
- Classification decisions

Verbose logging should never be required during normal operation.

---

## Warning

Unexpected conditions that do not prevent execution.

Examples

- Unable to open a certificate store
- Private key inaccessible
- Unknown certificate extension
- Invalid template data

Warnings should always include enough context to identify the object involved.

Good

```
Unable to parse template for certificate
Thumbprint:
XXXXXXXX
```

Bad

```
Template failed.
```

---

## Error

Operation could not continue.

Examples

- Engine initialization failed
- Invalid inventory object
- Critical parser failure

Errors should contain:

- Object involved
- Exception message
- Stack information (development builds)

---

# Logging Rules

Every public engine should log:

- Start
- Completion
- Duration
- Object count
- Errors

Example

```
Starting Certificate Engine
```

```
Completed Certificate Engine

108 certificates processed

Duration:
842 ms
```

---

# Function Logging

Complex helper functions should log major decisions.

Example

```
Parsing SAN extension
```

```
Detected DNS name

tech01.contoso.com
```

```
Detected UPN

administrator@contoso.com
```

Avoid excessive logging inside tight loops.

---

# Classification Logging

Classification should log only important decisions.

Example

```
Certificate classified as EnterpriseCA
```

```
Certificate classified as MicrosoftManaged
```

Avoid logging every individual property evaluation.

---

# Validation Logging

Validation engines should log:

- Rule executed
- Result
- Failure reason

Example

```
Validation

PASS

Server Authentication EKU present
```

```
Validation

FAIL

Private key inaccessible
```

---

# Detector Logging

Detectors should log:

- Detector start
- Object count
- Detection count
- Completion

Example

```
Running WinRM Certificate Detector

Certificates evaluated:
108

Detections:
2
```

---

# Performance Logging

Long-running operations should report timing.

Example

```
Certificate Inventory

Duration:
814 ms
```

Future engines may automatically populate timing metadata.

---

# Console Output

Console output should remain minimal.

Recommended:

```
Starting Certificate Engine...

Completed.

108 certificates analyzed.
```

Detailed diagnostics belong in the logging subsystem.

---

# Future Enhancements

Planned improvements include:

- Structured JSON logging
- Event Log integration
- ETW providers
- Log correlation IDs
- Performance tracing
- Debug sessions
- Centralized logging sinks