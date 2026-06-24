# Integration Notes — Four Challenges

**Author**: Hussein (DevOps)
**Date**: 2026-06-24

Each section states: what the conflict was, what options were considered,
what was chosen, and why.

---

## Challenge A: `ProtectSystem=strict` and the EnvironmentFile

### What the conflict was

`ProtectSystem=strict` is a systemd hardening directive that makes `/usr`,
`/boot`, and `/etc` read-only for the service process. My first instinct was
to store environment files under `/etc/kijanikiosk/` — a conventional location
for system-level configuration files on Linux. If the env files had been placed
there, `ProtectSystem=strict` would have made them read-only, but the service
needs to *read* them at startup, which is fine — read-only still means readable.
However, the real conflict was subtler: I initially wrote a setup step during
Tuesday's lab that ran `mkdir /etc/kijanikiosk` and created the env files there.
When I added `ProtectSystem=strict` in Phase 6, I then needed to verify whether
the service could still read its env file at all.

Testing revealed the actual behavior: `ProtectSystem=strict` does not make files
*unreadable*; it prevents *writes* to those paths. The service can read its env
file from `/etc/kijanikiosk/` with `ProtectSystem=strict` active. So there was
no functional breakage, but there was a different concern: the directory is not
covered by `ReadWritePaths=`, meaning it is protected, meaning if the service
ever needed to write a runtime config it would fail.

More practically: the access model places all KijaniKiosk application data under
`/opt/kijanikiosk/`, not `/etc/`. Having the config files in `/etc/kijanikiosk/`
would have split the access model across two separate directory trees, making
ACL management and auditing harder.

### Options considered

1. Keep env files under `/etc/kijanikiosk/` and accept read-only protection
2. Move env files to `/opt/kijanikiosk/config/` to consolidate with the rest
   of the access model
3. Use `BindReadOnlyPaths=/etc/kijanikiosk` to explicitly allow the service
   to read from `/etc` even with `ProtectSystem=strict`

### Decision

Moved all env files to `/opt/kijanikiosk/config/`. Each file is owned by its
respective service account with mode 640 (owner reads, group reads, others
nothing).

### Why

Option 2 consolidates the entire access model under one tree, making it
simpler to audit. The `getfacl` commands in `post-remediation-verification.txt`
cover all four key directories with a single root path. Option 3 (BindReadOnlyPaths)
would have worked technically but adds a directive that exists solely to work
around a configuration decision I had more control over. Option 1 was discarded
because it split the access model unnecessarily.

---

## Challenge B: The Monitoring User and ACL Defaults on `/health/`

### What the conflict was

Requirement 1 (Phase 8) asks the provisioning script to write a health check
JSON file to `/opt/kijanikiosk/health/`. The provisioning script runs as root.
Without explicit action, the file would be owned by root and readable only by
root. The access model document from Tuesday defined who can read what in
`/opt/kijanikiosk/` — but the `health/` directory was not part of Tuesday's
model. Adding it required answering: who writes it, who reads it, and does it
need ACLs?

### Options considered

1. Own the directory as root, make it world-readable (755/644)
2. Own the directory as kk-logs (the aggregation service), set group kijanikiosk,
   use ACLs to allow group read
3. Own the directory as a new dedicated monitoring user account
4. Make the file readable only by root and write a setuid helper binary for read access

### Decision

Option 2: directory owned by `kk-logs:kijanikiosk` with mode 750. After the
provisioning script writes `last-provision.json`, it explicitly sets ownership
to `kk-logs:kijanikiosk` with mode 640, then adds a group ACL:
`setfacl -m g:kijanikiosk:r last-provision.json`. This allows any member of
the `kijanikiosk` group to read the health status without sudo.

### Why

Option 1 (world-readable) is inappropriate for a file that may contain
infrastructure details like port states and script version numbers. Option 3
adds a service account for a non-service — monitoring is a read-only consumer,
not a running process. Option 4 introduces binary complexity for a text file read.

Option 2 is consistent with the rest of the access model: `kijanikiosk` group
membership is the mechanism for granting access to KijaniKiosk resources to
team members and service accounts. The health directory follows the same
pattern as `shared/logs/`.

---

## Challenge C: logrotate `postrotate` and `PrivateTmp=true`

### What the conflict was

`kk-logs.service` has `PrivateTmp=true`, which gives the service its own
private `/tmp` namespace. The logrotate `postrotate` script needs to signal
`kk-logs` to re-open its log file handles after rotation. The conventional
approach is `systemctl reload kk-logs.service`. The concern was whether
`PrivateTmp=true` would interfere with this signal path.

The actual conflict is subtler than the challenge description implies:
`systemctl reload` sends a signal from the systemd manager (PID 1), not from
any child process of kk-logs. The manager operates in the host namespace, not
in kk-logs's private namespace. So `PrivateTmp=true` does not interfere with
`systemctl reload` at all.

The real conflict was different: `systemctl reload` only works if the unit file
defines `ExecReload=`. Without it, `systemctl reload` exits with status 1
("Service has no reload definition"), causing logrotate's `postrotate` to fail
and generating cron error emails on every rotation.

### Options considered

1. Use `systemctl reload kk-logs.service` — requires ExecReload= to be defined
2. Use `systemctl restart kk-logs.service` — works without ExecReload=, but
   briefly stops the service and resets in-memory state
3. Use `systemctl kill --kill-who=main --signal=USR1 kk-logs.service` — sends
   SIGUSR1 directly without ExecReload=, but bypasses systemd's reload tracking
4. Add `ExecReload=/bin/kill -USR1 $MAINPID` to the unit file and use
   `systemctl reload` in postrotate

### Decision

Option 4: added `ExecReload=/bin/kill -USR1 $MAINPID` to `kk-logs.service`,
and used `systemctl reload kk-logs.service` in the logrotate postrotate block.

### Why

SIGUSR1 is the standard signal for telling a logging daemon to reopen its log
file handles, used by rsyslog, nginx, and many other daemons. Implementing it
via `ExecReload=` is the systemd-native pattern — it means `systemctl reload`
works as expected, the reload is tracked and logged by systemd, and the status
is visible in `systemctl status kk-logs`. Option 3 (direct kill) would also
work but bypasses systemd tracking. Option 2 (restart) is not equivalent to a
reload and would be visible as a brief service gap in the health check.

The `PrivateTmp=true` concern turned out to be a non-issue: systemd sends
signals from the manager process, not through a filesystem path in `/tmp`.

---

## Challenge D: Dirty VM and Package Holds

### What the conflict was

Package holds from Wednesday's provisioning script were already in place. When
the Friday script runs `apt-get install nginx=1.24.0-1ubuntu2`, it would succeed
if the installed version matched — but would fail or attempt a downgrade if the
version had drifted. The challenge was: how should the script handle a version
mismatch? The options are broadly: fail loudly, attempt a silent downgrade, or
skip and continue.

A secondary conflict: apt-mark hold prevents normal upgrades, but the hold
itself needs to be removed before installing a different version. The script
needs to unhold, install, then rehold — but only if the version actually needs
changing.

### Options considered

1. Always unhold, attempt install at pinned version, rehold (apt will downgrade if needed)
2. Check installed version first; if it matches, skip the install and just ensure hold
3. Check installed version first; if it mismatches, fail loudly with a message
   asking for manual intervention
4. Check installed version first; if it mismatches, attempt downgrade but log a
   warning

### Decision

Option 2 (match → skip, ensure hold) combined with Option 3 (mismatch → fail loud).
The script checks the installed version before touching anything. If the version
matches the pin, it skips the install and re-applies the hold. If it does not
match, the script logs a clear `FAIL` message identifying the package, the
installed version, and the required version, then exits non-zero.

### Why

Silent automated downgrades in production are dangerous. A package version
mismatch means something happened to the server that the provisioning script
did not cause — either someone ran `apt upgrade` manually, or a pin was
overridden. That is an incident that deserves human attention, not a silent
correction. The fail-loud approach ensures the engineer running the script
sees exactly what the problem is and makes a conscious decision about whether
to downgrade and why.

Option 1 was rejected because `apt-get install` downgrades silently and the
downgrade may introduce regressions that are hard to trace back. Option 4 was
rejected for the same reason — logging a warning does not prevent the downgrade.

The Friday audit showed nginx at `1.24.0-1ubuntu2` (matching the pin) and the
hold active, so the match path ran in practice.
