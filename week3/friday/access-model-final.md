# KijaniKiosk Access Model — Final (Week 3 Friday)

**Updated from Tuesday's lab** to include the `health/` directory and logrotate interaction notes.

---

## Service Account Summary

| Account     | UID | Primary Group  | Shell              | Purpose                          |
|-------------|-----|----------------|--------------------|----------------------------------|
| kk-api      | 998 | kijanikiosk    | /usr/sbin/nologin  | Runs the API application process |
| kk-payments | 997 | kijanikiosk    | /usr/sbin/nologin  | Runs the payments service        |
| kk-logs     | 996 | kijanikiosk    | /usr/sbin/nologin  | Log aggregation and health output|

System group `kijanikiosk` (GID 1001) — all service accounts are members.  
No service account has a login shell or home directory outside `/opt/kijanikiosk`.

---

## Directory Tree

```
/opt/kijanikiosk/               root:kijanikiosk   755
├── api/                        kk-api:kijanikiosk  750
├── payments/                   kk-payments:kijanikiosk 750
├── config/                     root:kijanikiosk    750
│   ├── api.env                 kk-api:kijanikiosk  640
│   ├── payments-api.env        kk-payments:kijanikiosk 640
│   └── logs.env                kk-logs:kijanikiosk 640
├── shared/
│   ├── logs/                   kk-logs:kijanikiosk 2775 (setgid)
│   │   └── *.log               kk-logs:kijanikiosk 660 + ACLs (see below)
│   └── cache/                  root:kijanikiosk    755
└── health/                     kk-logs:kijanikiosk 750  ← NEW
    └── last-provision.json     kk-logs:kijanikiosk 640 + ACL (see below)
```

---

## ACL Model — `/opt/kijanikiosk/shared/logs/`

### Why ACLs are needed
Standard Unix permissions allow only one owner and one group. The logs directory
requires three distinct access levels simultaneously:
- `kk-api` must **write** (appends log entries)
- `kk-payments` must **read** (audit correlation — cannot write to prevent log tampering)
- `kk-logs` must **read/write** (owns the aggregation process)
- `kijanikiosk` group members must **read** (monitoring and ops access)

### Directory ACL (applied by `setfacl`)

```
# file: opt/kijanikiosk/shared/logs/
# owner: kk-logs
# group: kijanikiosk
# flags: -s-
user::rwx
user:kk-api:rwx          # write access for log appending + traverse
user:kk-payments:r-x     # read-only for audit correlation
user:kk-logs:rwx         # owner, full access
group::r-x
group:kijanikiosk:r-x    # group members can read + traverse
mask::rwx
other::---
default:user::rwx
default:user:kk-api:rw-  # new files inherit kk-api write access
default:user:kk-payments:r--  # new files inherit kk-payments read access
default:user:kk-logs:rw-
default:group::r--
default:mask::rw-
default:other::---
```

### Setgid bit (2775)
The setgid bit ensures any file created inside `logs/` inherits the
`kijanikiosk` group, even if created by `kk-api`. This works in conjunction
with the default ACLs.

---

## ACL Model — `/opt/kijanikiosk/health/` (NEW — added Friday)

### Why this directory was added to the model
Requirement 1 (Phase 8) writes a health check JSON file after each provisioning
run. The provisioning script runs as root. Without explicit ACL configuration,
the file would be readable only by root, preventing the monitoring system and
Amina's regular account from reading health status without sudo.

### Decision: who owns it, who reads it
- **Owner**: `kk-logs:kijanikiosk` — kk-logs is the aggregation service and
  logically the "owner" of health/monitoring data.
- **Mode**: `640` — owner reads/writes, group reads, others nothing.
- **ACL**: group `kijanikiosk` gets read access via ACL on both the directory
  and files, so any team member in the group can read health status.
- **No write ACL for kk-api or kk-payments** — only the provisioning script
  (root) and kk-logs should ever write health data.

```
# file: opt/kijanikiosk/health/
# owner: kk-logs
# group: kijanikiosk
user::rwx
group::r-x
group:kijanikiosk:r-x
mask::r-x
other::---
default:group::r--
default:group:kijanikiosk:r--
```

```
# file: opt/kijanikiosk/health/last-provision.json
# owner: kk-logs
# group: kijanikiosk
user::rw-
group::r--
group:kijanikiosk:r--
mask::r--
other::---
```

---

## Logrotate Interaction with ACL Model

**The problem**: When logrotate rotates a log file, it creates a new empty file
using its `create` directive. This file creation goes through the kernel's
`creat()` syscall, which *does* inherit default ACLs from the parent directory.
However, logrotate then calls `chmod()` to apply the mode specified in `create`,
which adjusts the ACL mask.

**Why `create 0640` breaks kk-api write access**:
With `create 0640`, the ACL mask is set to `0040` (group read). The named user
ACL entry `u:kk-api:rw-` is limited to `r--` by the mask. kk-api can no longer
write to the rotated log file.

**Our solution**: Use `create 0660` to set the ACL mask to `0060` (group rw).
This allows `u:kk-api:rw-` to remain effective. Then in `postrotate`, explicitly
re-apply named user ACLs to ensure clean state regardless of mask interaction:

```bash
setfacl -m u:kk-api:rw,u:kk-payments:r,u:kk-logs:rw \
  /opt/kijanikiosk/shared/logs/*.log 2>/dev/null || true
```

**Definitive verification command** (run after `sudo logrotate --force /etc/logrotate.d/kijanikiosk`):
```bash
sudo -u kk-api touch /opt/kijanikiosk/shared/logs/test-write.tmp \
  && echo "PASS: kk-api can write after logrotate" \
  || echo "FAIL: kk-api cannot write to shared/logs"
```

---

## Config File Access Model

Each environment file is owned by the service account that reads it:

| File                   | Owner       | Mode | Readable by            |
|------------------------|-------------|------|------------------------|
| api.env                | kk-api      | 640  | kk-api only            |
| payments-api.env       | kk-payments | 640  | kk-payments only       |
| logs.env               | kk-logs     | 640  | kk-logs only           |

No cross-service env file access. `kk-payments` cannot read `api.env` and
vice versa. This prevents a compromised payments process from reading API secrets.

**Verification** (must pass before testing unit files):
```bash
sudo -u kk-payments cat /opt/kijanikiosk/config/payments-api.env   # should print contents
sudo -u kk-payments cat /opt/kijanikiosk/config/api.env            # should print "Permission denied"
```

---

## getfacl Output for Key Directories (post-provisioning)

### /opt/kijanikiosk/shared/logs/
```
# file: opt/kijanikiosk/shared/logs/
# owner: kk-logs
# group: kijanikiosk
# flags: -s-
user::rwx
user:kk-api:rwx
user:kk-payments:r-x
user:kk-logs:rwx
group::r-x
group:kijanikiosk:r-x
mask::rwx
other::---
default:user::rwx
default:user:kk-api:rw-
default:user:kk-payments:r--
default:user:kk-logs:rw-
default:group::r--
default:mask::rw-
default:other::---
```

### /opt/kijanikiosk/config/
```
# file: opt/kijanikiosk/config/
# owner: root
# group: kijanikiosk
user::rwx
group::r-x
group:kijanikiosk:r-x
mask::r-x
other::---
```

### /opt/kijanikiosk/api/
```
# file: opt/kijanikiosk/api/
# owner: kk-api
# group: kijanikiosk
user::rwx
group::r-x
mask::r-x
other::---
```

### /opt/kijanikiosk/health/
```
# file: opt/kijanikiosk/health/
# owner: kk-logs
# group: kijanikiosk
user::rwx
group::r-x
group:kijanikiosk:r-x
mask::r-x
other::---
default:group::r--
default:group:kijanikiosk:r--
default:mask::r--
default:other::---
```
