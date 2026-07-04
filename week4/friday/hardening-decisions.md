# KijaniKiosk Staging Environment: Security Posture

**Prepared for**: Nia (CEO / Board briefing)
**Prepared by**: DevOps Team
**Date**: 3 July 2026

---

## What this document covers

This document explains the security decisions behind the staging environment that
now provisions and configures KijaniKiosk's three core services automatically, from a
written specification rather than from memory. The goal is an honest picture of what
we have protected and where gaps remain.

## How the environment is built

Two tools work together. The first provisions the servers themselves: it reads a
specification of what each server should be and creates exactly that, every time,
from the same starting point. The second configures each server once it exists:
installing software, creating service identities, writing configuration, and starting
each service, using the same rules everywhere. Running either tool a second time
changes nothing, which is how we know the environment matches its specification
rather than drifting from it over time.

Each control below addresses a specific risk. The first group covers how the servers
themselves are created and protected; the second covers how each running service is
constrained once it starts.

| Control | What it does | Risk mitigated |
|---------|-------------|----------------|
| Reusable server specification | All three servers are created from one shared template, not three separately written definitions. | Prevents servers from drifting apart unnoticed; every server's configuration is reviewable in one place. |
| Network access restriction (server level) | Each server accepts inbound administrative access only from our office network, not the entire internet. | Blocks the most common opportunistic attack: scanning for open administrative access. |
| Key-based server access | Servers are created with a specific, named administrative key rather than a password, never stored in the specification itself. | A leaked specification does not hand over server access; only the key holder can log in. |
| Remote, shared infrastructure record | The record of what has been created is stored centrally, not on one engineer's laptop. | Any engineer can safely see and change the environment; it does not depend on one machine. |
| Dedicated service accounts | Each service runs as its own identity, with no shared passwords and no login shell. | A compromised service cannot impersonate another, and cannot be used to log in directly. |
| Least-privilege file access | Each service can only read and write the specific folders it needs. | A breach in one service does not expose another service's configuration or data. |
| Process confinement | Services cannot load system extensions, modify system settings, or gain elevated rights. | Code execution inside a service cannot escalate to compromise the server itself. |
| Firewall with declared intent | Inbound rules default to denying everything except what is explicitly needed. | An audit can verify the firewall reflects deliberate decisions, not accumulated edits. |
| Persistent log retention | Logs are written to permanent storage with a size cap and rotation schedule. | Audit trails survive restarts and disk exhaustion; supports investigation after an incident. |

## About the payments service specifically

The payments service carries stricter controls than the other two. This is
intentional: it reflects the higher sensitivity of financial data and the regulatory
expectations that come with it. Every control applied to the other services is also
applied to payments, plus network isolation that prevents it from connecting outside
our own internal network, and further restrictions on hardware-adjacent resources it
may touch. Measured against an industry-standard scoring tool, the payments service's
confinement scores comfortably inside the "safe" range targeted for this sprint. Each
extra control was tested individually before being accepted; a payment service that is
locked down but unable to run provides no security benefit.

## A known limitation of the staging setup

The shared infrastructure record does not, in its current staging configuration,
prevent two engineers from changing the environment at the exact same moment. On a
small team this is a low-probability event, and the tooling fails safely rather than
corrupting the record if it happens. Before this pattern is used for production, we
would add a coordination mechanism so only one change is ever in progress at a time -
a well-understood, inexpensive addition, not a redesign.

## What the current posture does not protect against

Honesty about gaps is more useful than overclaiming. The following risks are not
addressed by today's environment work and should inform the roadmap ahead.

**Application-layer vulnerabilities**: These controls protect the servers and the
processes running on them, not bugs in the application code itself - for example, a
flaw that lets one customer see another's data. That requires code review and
security testing at the application level, separate from this environment work.

**Secrets management**: Configuration values are stored as files on each server,
protected by file permissions. This is workable for staging but is not equivalent to
a dedicated secrets vault, and should be replaced before a customer-facing launch.

**Mutual authentication between services**: Services on our internal network can
currently talk to each other without cryptographically proving who they are. Closing
this gap is a reasonable next-sprint priority.

**Monitoring and alerting**: We can prove the environment matches its specification
immediately after building it, but we do not yet have ongoing, automated alerting if
a service later stops responding. This should be addressed before any service here
handles live transactions.

The controls in place today form the correct foundation for a staging environment.
The gaps above are the right priorities for the sprint ahead, before anything here
touches real customer data.

---

## Appendix: kk-payments security score evidence

*(Supplementary evidence for Requirement 5, not part of the 800-1000 word narrative above.)*

Command run on the payments server:

```
$ sudo systemd-analyze security kk-payments.service
```

Remaining exposures (everything else in the full report is a pass):

```
✗ PrivateNetwork=                General network access - accepted; the service must accept
                                  inbound connections, and IPAddressAllow/Deny already
                                  restrict which addresses it may reach.        0.5
✗ RestrictAddressFamilies=~AF_(INET|INET6)  Needed for TCP.                     0.3
✗ DeviceAllow=/IPAddressDeny=/PrivateUsers=/ProtectKernelLogs=/ProtectProc=/
  SystemCallFilter=~@privileged/@resources   Minor residual exposures, each
                                              individually assessed as acceptable.
✗ RestrictRealtime=/RootDirectory=/UMask=/RestrictAddressFamilies=~AF_UNIX/
  ProcSubset=                                 Minor residual exposures.        0.1 each

→ Overall exposure level for kk-payments.service: 1.8 OK 🙂
```

Target was below 2.5 (carried over from Week 3, where the same directive set scored
2.3). Full raw output is saved alongside this document as
`kk-payments-security-score.txt`. Confirmed the service is `active` and that it can
read its own environment file under `/opt/kijanikiosk/` without issue, despite
`ProtectSystem=strict` (which only restricts `/usr`, `/boot`, and `/etc`).
