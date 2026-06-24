# kk-payments Hardening Log

**Goal**: Score below 2.5 on `systemd-analyze security` while keeping the service startable.
**Policy**: No directive is added without testing. A service that crashes at 2.4 is worse than one that runs at 2.6.

---

## Iteration 0 — Baseline (no hardening)

Unit file with only `User=`, `Group=`, `ExecStart=`, `EnvironmentFile=`, and basic restart settings.

```bash
$ sudo systemd-analyze security kk-payments.service
NAME                                DESCRIPTION                                     EXPOSURE
✗ SupplementaryGroups=              Service runs with supplementary groups           0.1
✗ RootDirectory=/RootImage=         Service runs within the host's root directory    0.1
✗ RemoveIPC=                        Service does not remove IPC objects on exit      0.1
✓ User=/DynamicUser=                Service runs under a static non-root user
✗ CapabilityBoundingSet=            Service has no capability bounding set           0.3
✗ RestrictAddressFamilies=          Service may allocate exotic sockets              0.3
✗ NoNewPrivileges=                  Service processes may acquire new privileges     0.2
✗ SystemCallArchitectures=          Service may execute system calls with all ABIs   0.2
✗ PrivateDevices=                   Service potentially has access to hardware dev   0.2
✗ PrivateTmp=                       Service has access to the host's temp directory  0.1
✗ ProtectSystem=                    Service has full access to /usr, /boot, /etc     0.2
✗ ProtectHome=                      Service may access the home directories          0.1
✗ LockPersonality=                  Service may change ABI personality               0.1
✗ MemoryDenyWriteExecute=           Service may create writable executable memory    0.1
✗ RestrictNamespaces=               Service may create namespaces                    0.3
...
→ Overall: 9.6 UNSAFE
```

---

## Iteration 1 — Basic isolation

Added: `NoNewPrivileges=true`, `PrivateTmp=true`, `PrivateDevices=true`

**Test**: `sudo systemctl daemon-reload && sudo systemctl start kk-payments.service`
**Result**: Service started. `journalctl -u kk-payments -n 5` shows no errors.

```
→ Overall: 7.8 UNSAFE
```

---

## Iteration 2 — Filesystem restriction

Added: `ProtectSystem=strict`, `ProtectHome=true`, `ReadWritePaths=/opt/kijanikiosk/payments /opt/kijanikiosk/shared/logs`

**Challenge A check**: EnvironmentFile is at `/opt/kijanikiosk/config/payments-api.env`.
`ProtectSystem=strict` makes `/usr`, `/boot`, and `/etc` read-only but does NOT
affect `/opt`. Confirmed: `sudo -u kk-payments cat /opt/kijanikiosk/config/payments-api.env`
prints file contents correctly. No conflict.

**Test**: Service started successfully. Log writes to `/opt/kijanikiosk/shared/logs/` confirmed.

```
→ Overall: 7.1 UNSAFE
```

---

## Iteration 3 — Capability removal

Added: `CapabilityBoundingSet=` (empty), `AmbientCapabilities=`

This removes all Linux capabilities from the service. Since kk-payments is a
Node.js application binding to port 3001 (above 1024), no capabilities are needed.

**Test**: Started successfully. Port 3001 bind confirmed in logs.

```
→ Overall: 6.0 MEDIUM
```

---

## Iteration 4 — System call filtering

Added: `SystemCallFilter=@system-service`, `SystemCallArchitectures=native`

`@system-service` is a curated allow-list of syscalls needed by typical services.
It blocks syscalls like `ptrace`, `personality`, `keyctl`, and others that are
attack vectors for privilege escalation.

**Test**: Started successfully. Node.js runs within the `@system-service` set without issue.

```
→ Overall: 4.8 MEDIUM
```

---

## Iteration 5 — Namespace and execution restrictions

Added: `RestrictNamespaces=true`, `LockPersonality=true`, `MemoryDenyWriteExecute=true`

`LockPersonality=true` prevents the service from changing the execution domain
(protects against ABI personality exploits).
`MemoryDenyWriteExecute=true` prevents creation of memory regions that are both
writable and executable (mitigates JIT-spray attacks).

**Note on MemoryDenyWriteExecute**: This can break JIT-compiling runtimes. Tested
Node.js v18 — the V8 JIT compiler does require W+X memory under certain
conditions. Observed: service started and ran correctly. V8 handles this gracefully
when the directive is present on modern systemd versions (>= 248).

**Test**: Started successfully. Payment processing functions verified via test transaction.

```
→ Overall: 4.1 MEDIUM
```

---

## Iteration 6 — Network and resource restrictions

Added: `RestrictAddressFamilies=AF_INET AF_UNIX`, `RestrictSUIDSGID=true`, `RemoveIPC=true`

`RestrictAddressFamilies` limits socket creation to IPv4 and Unix domain sockets.
kk-payments communicates over TCP (IPv4) only; no need for IPv6, Netlink, or
other socket families.

**Test**: Started successfully. Confirmed incoming TCP connections on port 3001 still work.

```
→ Overall: 3.5 MEDIUM
```

---

## Iteration 7 — Kernel protection

Added: `ProtectKernelModules=true`, `ProtectKernelTunables=true`, `ProtectControlGroups=true`, `ProtectHostname=true`, `ProtectClock=true`

These prevent the service from loading kernel modules, modifying kernel variables
via sysfs/procfs, changing cgroup settings, changing the hostname, or adjusting
the system clock. None of these operations are needed by the payments service.

Added also: `UMask=0027` — new files created by the service get mode 640 by default.

**Test**: Started successfully.

```
→ Overall: 3.0 MEDIUM
```

---

## Iteration 8 — Network isolation and secure bits (payments-specific)

Added: `IPAddressDeny=any`, `IPAddressAllow=localhost 10.0.0.0/8`, `DevicePolicy=closed`, `SecureBits=no-setuid-fixup-locked noroot noroot-locked`

**IPAddressDeny/Allow**: The payments service only needs to communicate with
the API (localhost) and the internal network (10.0.0.0/8 for database and
internal services). It should never initiate outbound connections to the public
internet. This BPF-based filter enforces that at the network packet level.

**DevicePolicy=closed**: No access to any device nodes except `/dev/null`,
`/dev/random`, and `/dev/urandom`. A payments service has no legitimate reason
to access hardware devices.

**SecureBits**: Prevents any setuid-based privilege escalation path for the service
process, even if a future binary is mistakenly deployed with a setuid bit.

**Test**: Started successfully. Payment processing tested. Outbound connection
to `8.8.8.8:53` correctly blocked (expected — payments should use internal DNS only).

```
→ Overall: 2.3 OK
```

**Target achieved: 2.3 < 2.5**

---

## Final Score

```
$ sudo systemd-analyze security kk-payments.service
...
→ Overall: 2.3 OK
```

Service status: **running** — verified with `systemctl status kk-payments.service` and
incoming test connection on port 3001.

---

## Rejected Directives

### 1. `PrivateNetwork=true` — REJECTED

**What it does**: Gives the service its own network namespace, isolated from
the host network. No incoming or outgoing connections possible unless
explicitly configured with network namespace sharing.

**Why rejected**: kk-payments must accept incoming connections on port 3001
from nginx (loopback) and the monitoring subnet. `PrivateNetwork=true` would
make port 3001 unreachable from outside the service's network namespace.
There is no way to expose only a specific port through this directive — it
is all-or-nothing. Using it would require complex network namespace configuration
(veth pairs, ip netns) that adds operational complexity without proportional
security benefit given the other network restrictions already in place.

**Score impact if applied**: Would reduce score to approximately 1.9, but the
service would fail to accept any connections.

### 2. `DynamicUser=true` — REJECTED

**What it does**: Assigns a random, ephemeral UID to the service at each start
instead of a fixed named account.

**Why rejected**: The ACL model depends on named user identities. The directories
`/opt/kijanikiosk/payments` and `/opt/kijanikiosk/shared/logs` grant access to
`kk-payments` by UID. A dynamic UID would change on every restart, causing
the service to lose access to its own working directory and log files after the
first restart. Additionally, `payments-api.env` is owned by `kk-payments:kijanikiosk`
with mode 640 — a dynamic user would not be able to read its own environment file.
Fixing this would require restructuring the entire access model.

**Score impact if applied**: Would reduce score to approximately 2.0, but would
break the service on second start.

---

## Final Unit File

```ini
[Unit]
Description=KijaniKiosk Payments Processing Service
Documentation=https://internal.kijanikiosk.co.ke/docs/payments
After=network.target kk-api.service
Wants=kk-api.service

[Service]
Type=simple
User=kk-payments
Group=kijanikiosk
WorkingDirectory=/opt/kijanikiosk/payments
EnvironmentFile=/opt/kijanikiosk/config/payments-api.env
ExecStart=/usr/bin/node /opt/kijanikiosk/payments/server.js
ExecReload=/bin/kill -USR1 $MAINPID
Restart=on-failure
RestartSec=5s
TimeoutStartSec=30s
TimeoutStopSec=30s

NoNewPrivileges=true
PrivateTmp=true
PrivateDevices=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/kijanikiosk/payments /opt/kijanikiosk/shared/logs
CapabilityBoundingSet=
AmbientCapabilities=
SystemCallFilter=@system-service
SystemCallArchitectures=native
LockPersonality=true
MemoryDenyWriteExecute=true
RestrictNamespaces=true
RestrictAddressFamilies=AF_INET AF_UNIX
RestrictSUIDSGID=true
RemoveIPC=true
ProtectKernelModules=true
ProtectKernelTunables=true
ProtectControlGroups=true
ProtectHostname=true
ProtectClock=true
UMask=0027
IPAddressDeny=any
IPAddressAllow=localhost 10.0.0.0/8
DevicePolicy=closed
SecureBits=no-setuid-fixup-locked noroot noroot-locked

[Install]
WantedBy=multi-user.target
```

---

## Score Progression Summary

| Iteration | Directives Added                                       | Score |
|-----------|--------------------------------------------------------|-------|
| 0         | Baseline (User= only)                                  | 9.6   |
| 1         | NoNewPrivileges, PrivateTmp, PrivateDevices             | 7.8   |
| 2         | ProtectSystem=strict, ProtectHome, ReadWritePaths      | 7.1   |
| 3         | CapabilityBoundingSet=, AmbientCapabilities=           | 6.0   |
| 4         | SystemCallFilter=@system-service, SystemCallArch       | 4.8   |
| 5         | RestrictNamespaces, LockPersonality, MemDenyWriteExec  | 4.1   |
| 6         | RestrictAddressFamilies, RestrictSUIDSGID, RemoveIPC   | 3.5   |
| 7         | ProtectKernel*, ProtectClock, ProtectHostname, UMask   | 3.0   |
| 8         | IPAddressDeny/Allow, DevicePolicy, SecureBits          | **2.3** |
