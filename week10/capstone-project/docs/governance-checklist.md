# Six-point AI/infrastructure governance checklist

project.md references "the Week 10 six-point governance checklist" without
reprinting it, and the original Week 10 handout is not part of this
repository (there is no `week10/friday` submission this capstone built on
top of — see `docs/scope.md`). The six controls below are the practical
checklist actually applied to AI-generated output in this build, chosen to
match the categories project.md's checklist references are clearly
gesturing at (secrets, blast radius, drift, idempotency).

1. **Secrets** — does the output hardcode or log a credential, token, or password anywhere?
2. **Least privilege** — does an IAM/RBAC statement grant more than the function/task needs?
3. **Idempotency** — can the script/playbook/config be re-applied safely, or does it assume a fresh state?
4. **Blast radius** — what happens if this runs against the wrong namespace/cluster/account?
5. **Drift risk** — is any value (name, port, bucket) duplicated in two places that could silently diverge?
6. **Human review evidence** — is there a specific, named change the reviewer made, not just approval?

See `docs/ai-governance-log.md` for entries citing these controls by number.
