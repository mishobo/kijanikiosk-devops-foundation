# Reflection

## 1. Where two requirements conflicted

I hit this directly, not as a hypothetical: after the first full pipeline run, I
tested Challenge D's verification step against the payments server and it failed -
there was no environment file at all. Requirement 2 says the playbook must configure
servers "to the state the Week 3 provisioning script produced," and Week 3's script
wrote a per-service environment file referenced by `EnvironmentFile=` in the unit.
Thursday's playbook, which I built this project's playbook from, never wrote one -
its lab skeleton didn't ask for it, since that exercise focused on packages,
accounts, directories, systemd, firewall, journal, and logrotate, not secrets
delivery. Carrying Thursday's playbook forward unmodified silently dropped a
requirement that Friday's brief restores.

The conflict was between "reuse what you already built" and "meet the full Week 3
standard" - reusing Thursday's playbook as-is looked complete (it ran cleanly,
services started, `changed=0` on a second run) while actually being incomplete. I
added a templated environment file per server, referenced it from the unit file
under the writable application path rather than under the path `ProtectSystem=strict`
locks down, and re-verified with the exact command Challenge D specifies before
re-running the full pipeline. The lesson: a clean idempotent run proves the playbook
is consistent with itself, not that it's complete against the original spec. Those
are different claims, and I'd been implicitly treating the first as evidence of the
second.

## 2. The same sentence, for Tendo instead of Nia

For Nia, the document says: *"Each service can only read and write the specific
folders it needs."*

For Tendo, I'd write: *"Each service account owns a dedicated subtree with 0750
permissions, group-owned by a shared system group; `ProtectSystem=strict` combined
with an explicit `ReadWritePaths=` allowlist means the process's own filesystem
namespace only exposes that subtree plus its log directory as writable, with `/usr`,
`/boot`, and `/etc` mounted read-only regardless of the process's UID."*

What's gained for Tendo: the mechanism is verifiable. He can check the exact
directive names, know which specific paths are allowlisted, and understand this is
enforced by the kernel through systemd's namespacing, not by convention or code
discipline. What's lost for Nia: all of that detail is noise against her actual
question, which is "can one compromised service reach another's data." The Nia
version answers that directly; the Tendo version answers "how do we know," which
is a different and more useful question for someone about to review the unit file
itself.

## 3. The most fragile handoff

The SSH-readiness wait in `pipeline.sh` - the loop that polls each new server until
it accepts an SSH connection before handing off to Ansible. It works here because I
know these specific servers: a stock Ubuntu 22.04 AMI on a t3.micro finishes booting
and starts `sshd` within the fifteen-attempt, five-second-interval window I hardcoded.
That number came from watching this exact setup boot a few times, not from any
guarantee.

In a production environment this would be the first thing to break, and it would
break silently in the specific sense that matters: not as a crash, but as a race that
usually wins and occasionally doesn't. A larger instance type with more init work to
do, a golden AMI with a slower first-boot script, a region under load, a security
group that's briefly wrong before a second Terraform pass fixes it - any of these
could push boot time past the window, and the failure mode is Ansible attempting to
connect to a host that Terraform correctly reports as running but that isn't actually
ready, which looks like a flaky network issue rather than what it is.

To make this robust I'd need to know the actual boot and cloud-init completion time
distribution for the real target AMI and instance type in the real target region -
not assume my staging numbers generalize - and I'd replace the fixed retry count with
a check for a real readiness signal (cloud-init's completion marker, ideally) rather
than "SSH accepts a connection," since a server can accept SSH before it has finished
the setup Ansible is about to build on top of.
