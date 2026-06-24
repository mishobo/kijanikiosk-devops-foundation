# Reflection

---

## 1. At what point did you discover that two requirements were in conflict? Describe the conflict and what you learned from resolving it.

The conflict between the logrotate `create` directive and the ACL model
(Requirement 3) surfaced during the Phase 7 integration test, after I had already
written Phase 3. I had correctly set up the default ACLs on `shared/logs/` to
ensure new files inherited the right permissions. What I had not considered was
that logrotate's `create` directive does not go through the normal kernel ACL
inheritance path cleanly — it creates the file, then calls `chmod()` to set the
specified mode, and `chmod()` adjusts the ACL mask.

With `create 0640`, the mask becomes read-only for the group. The named user
ACL entry for `kk-api` (`u:kk-api:rw-`) is bounded by that mask, reducing it
to `r--`. kk-api silently loses write access to every new log file after rotation.

I found this not by reading documentation but by running the definitive test:
`sudo -u kk-api touch /opt/kijanikiosk/shared/logs/test-write.tmp` after a
forced rotation — and watching it fail with "Permission denied" while thinking
the ACL model was already correct.

What I learned: requirements that appear to be in separate domains (file rotation
is Phase 7, ACLs are Phase 3) can interact in ways that only surface when you
test the composed system. The "test after every subsystem integration" discipline
is not procedural overhead — it is where the real bugs live. I also learned
to read `getfacl` output more carefully: the `mask::` entry is the key to
understanding what ACL entries actually do, not just whether they exist.

---

## 2. Rewrite one sentence from the Nia document in the technical language you would use for Tendo. What is lost and what is gained?

**Nia's version**:
> The payments service can only accept connections from our internal network and
> cannot initiate outbound connections to the public internet.

**Tendo's version**:
> kk-payments.service has `IPAddressDeny=any` with `IPAddressAllow=localhost 10.0.0.0/8`,
> implemented as a cgroup-v2 BPF program attached to the service's network socket;
> this blocks outbound connections to all addresses outside the allowed ranges at
> the kernel packet level before they reach the network stack.

**What is lost in translation to Tendo's version**: The business consequence
disappears. Nia needs to understand what happens if this control fails — "payments
data cannot exfiltrate to attacker infrastructure" is the risk she needs to
communicate to the board. The technical version says nothing about why this
matters from a business risk perspective.

**What is gained**: Precision and auditability. Tendo can look at the unit file,
see the exact directives, and verify the claim without trusting the prose. The
mechanism is clear — it is a BPF filter, not a firewall rule, so it cannot be
bypassed by a process that opens a raw socket before systemd applies the policy.
For a security review, that distinction matters. For a board presentation, it
does not.

The translation loss is not just vocabulary — it is a loss of the *framing*
that makes the control meaningful to its audience. Neither version is more "true"
than the other; they are written for different purposes.

---

## 3. What is the single most fragile part of the script, and what would you need to know to make it robust?

The most fragile part is the **postrotate ACL re-application** in the logrotate config:

```bash
setfacl -m u:kk-api:rw,u:kk-payments:r,u:kk-logs:rw \
  /opt/kijanikiosk/shared/logs/*.log 2>/dev/null || true
```

The `|| true` at the end means this command never fails visibly. It could fail
silently for several reasons: `setfacl` is not installed, the glob `*.log`
matches no files, or the ACL subsystem is disabled on the target filesystem.
In any of those cases, the logrotate config exits successfully, the rotation
succeeds, and kk-api silently loses write access to its log files. This failure
mode is invisible until someone notices the log files have stopped being written
to — likely hours or days later.

To make it robust in a real production environment, I would need to know:

- **Is ACL support guaranteed on the target filesystem?** In cloud environments
  (AWS EBS, GCP PD), ACL support is generally enabled, but some NFS or EFS
  mounts have ACLs disabled at the mount level. If the mount options include
  `noacl`, the `setfacl` command fails silently. I would need to check the
  filesystem mount options and fail loudly if ACLs are not supported.

- **Is the rotation timing deterministic?** If log files are created and rotated
  faster than the postrotate script runs, or if multiple logrotate invocations
  run in parallel (possible in some cron configurations), there are race conditions
  where a file exists between rotation and ACL re-application in a state where
  kk-api cannot write to it. I would need to understand the log write volume and
  rotation frequency to assess whether this is a real risk.

- **Will the `setfacl` binary always be present?** The provisioning script installs
  `acl` as a prerequisite package, but the postrotate script runs days after
  provisioning. If someone removes the `acl` package, the postrotate silently
  does nothing. I would add an explicit check for the `setfacl` binary at the
  top of the postrotate block and fail the rotation if it is missing, rather
  than silently proceeding.

The deeper issue is that the `|| true` pattern, common in postrotate scripts
to avoid cron error spam, hides real failures. In production, I would replace
it with explicit error handling that logs to a dedicated file and triggers a
monitoring alert — accepting the occasional cron email in exchange for visibility
into access model failures.
