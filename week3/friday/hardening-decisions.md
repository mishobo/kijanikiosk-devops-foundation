# KijaniKiosk Production Server Security Posture

**Prepared for**: Nia (CEO / Board briefing)
**Prepared by**: DevOps Team
**Date**: 24 June 2026

---

## What this document covers

This document explains the security decisions made in building the production
server foundation for KijaniKiosk's payments service. Every decision was made
deliberately, tested before being accepted, and documented so it can be explained,
audited, or reversed with full context. The goal is an honest picture of what we
have protected and where gaps remain.

---

## How the server is secured

The payments service runs in the most tightly constrained environment we could
configure while keeping it functional. Think of it as a locked room inside a
locked building: the building controls who gets in from outside, and the room
controls what someone inside can do, even without authorisation.

Each control below addresses a specific risk.

| Control | What it does | Risk mitigated |
|---------|-------------|----------------|
| Dedicated service accounts | Each service runs as its own identity with no shared passwords and no login shell. | A compromised API service cannot impersonate the payments process; no service can log in directly. |
| Least-privilege file access | Each service can only read and write the specific folders it needs. Files of one service are not readable by another. | A breach in the API cannot expose payments configuration, and vice versa. |
| Process confinement | The payments service cannot load system extensions, modify system settings, or create processes with elevated rights. | An attacker with code execution inside payments cannot escalate to compromise the host. |
| Network access restriction | The payments service accepts connections only from our internal network and cannot call out to the public internet. | A compromised dependency cannot exfiltrate data to attacker-controlled infrastructure. |
| Blocked privilege escalation | The service cannot gain new permissions even if a future deployment accidentally includes an elevated file. | Closes a common attack path where a planted file grants root access. |
| Firewall with declared intent | Inbound traffic rules are written with documented purposes, replacing the history of manual edits accumulated this week. | Any future audit can verify the firewall reflects deliberate decisions, not forgotten changes. |
| Port separation | The payments port is reachable only from the internal network and the server's own loopback interface. | Forces all external traffic through the reverse proxy, where logging and rate-limiting apply. |
| Clock and hostname protection | The payments service cannot change the server clock or hostname. | Prevents timestamp manipulation to obscure fraud or affect time-sensitive transaction logic. |
| Pinned software versions | The web server is locked to a specific tested version and blocked from automatic updates. | Prevents a routine update from introducing a regression or a malicious package. |
| Persistent log retention | System logs are written to permanent storage with a size cap and rotation schedule. | Audit trails survive server restarts and disk exhaustion; supports forensic investigation. |

---

## About the payments service specifically

The payments service has a stricter security configuration than the API or
logging services. This is intentional. The extra controls on the payments service
reflect the higher sensitivity of financial transaction data and the regulatory
expectations that accompany it. Every control applied to the API service is also
applied to payments, plus additional network isolation that prevents the payments
process from making any connection outside our internal network.

These extra controls were tested individually. Any control that broke the service
was either removed or replaced with a more targeted alternative. A payment service
that is locked down but non-functional provides no security benefit.

---

## What the current posture does not protect against

Honesty about gaps is more useful to you than overclaiming. The following risks
are not fully addressed by today's foundation and should inform the roadmap
for the next sprint.

**Application-layer vulnerabilities**: The server-level controls described here
protect the operating system and process environment. They do not protect against
security bugs in the application code itself — for example, a SQL injection flaw
in the payments API or an improperly validated input that allows a user to
access another user's transaction data. Those risks require code review and
security testing at the application level, which is outside the scope of this
foundation work.

**Secrets management**: Environment files containing connection strings and
service credentials are stored on the server's filesystem, protected by file
permissions. This is substantially better than hardcoded credentials, but it
is not equivalent to a dedicated secrets manager. If the server itself is
compromised at the root level, all credentials stored this way are exposed.
A dedicated secrets vault would be the appropriate next step before a
customer-facing launch.

**Mutual authentication between services**: The API and payments services can
communicate freely over the internal network. There is no cryptographic proof
that a request reaching the payments service came from the API and not from
another process on the same host. Mutual authentication between services would
close this gap and should be part of the next sprint.

**Monitoring and alerting**: The health check written after each provisioning
run records whether services are listening on their expected ports. This is a
baseline check, not active monitoring. There is no automated alert if the
payments service stops responding, and no integration with an external monitoring
platform. This must be addressed before the service handles live transactions.

The controls in place today form the correct foundation. The gaps above are the
correct priorities for the sprint ahead.
