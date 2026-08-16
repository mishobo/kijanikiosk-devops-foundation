# Peer Feedback Log

No second engineer was available in this build session/environment, so
this is a **documented self-review** per project.md's allowance ("A
documented self-review with a resolved improvement is preferable to no
feedback log"). Executed against `docs/test-plan.md`, in a fresh shell,
actually running each command rather than reading the code and assuming it
works.

## Issue 1
- **Issue:** `terraform validate` in `terraform/` failed with three parse
  errors. `variables.tf`'s `stage` variable description contained the
  literal string `${self:custom.stage}` (meant as a cross-reference to
  serverless.yml's syntax for a human reader), which Terraform's HCL parser
  tried to interpret as its own template interpolation.
- **Severity:** Blocks setup — `terraform init && terraform validate` is
  the first command in the runbook, and it failed outright.
- **Resolution:** Reworded the description to `"...serverless.yml's
  custom.stage..."` with no `${...}` syntax. Re-ran `terraform validate` →
  `Success! The configuration is valid.`
- **Evidence:** `terraform/variables.tf`, `stage` variable description.

## Issue 2
- **Issue:** Ran `kk-payments` and `scripts/run-local-chain.js` as plain
  Node processes (no minikube) end-to-end: `POST /pay` → receipt written →
  `kk-receipts` → `kk-processor` → `kk-notifier`, all four log lines
  appeared for the same `orderId` within ~120ms. This confirms the chain
  logic itself is correct, but it only ran outside Kubernetes — it does not
  exercise the `hostPath` volume the Deployment manifest relies on.
- **Severity:** Unclear documentation (not a functional bug — the code
  path this exercises is correct, but the runbook needed to be explicit
  that this local run is not equivalent to a from-Kubernetes run).
- **Resolution:** `docs/runbook.md`'s "Reproducing the system from a clean
  checkout" already gives the from-Kubernetes command sequence; confirmed
  it's consistent with what was actually run, and cross-referenced "The
  integration seam that breaks first" so a reader doesn't mistake the
  local-process run for proof the Kubernetes path works.
- **Evidence:** `/tmp/chain-test.log` from this session — `kk-receipts`,
  `kk-processor`, `kk-notifier` each logged the same `orderId
  c0819a7a-d422-4d0a-95e8-aff105867181`.

## Issue 3
- **Issue:** Confirmed the failure path deliberately: started `kk-payments`
  with `RECEIPTS_BUCKET` unset and called `/pay`. It correctly returned
  `500 {"error":"RECEIPTS_BUCKET not configured"}` instead of silently
  accepting the payment and losing the receipt. No code change needed —
  logged as a passed check, not a defect.
- **Severity:** Minor improvement (verification only).
- **Resolution:** No change required; behavior matches
  `docs/test-plan.md` section 3's expected failure-path behavior.
- **Evidence:** Manual run this session, `/pay` → `500` with the expected
  error body.

## Improvement committed
Issue 1's fix is the resolved improvement referenced by Dimension 6's
minimum-improvement standard. The bug was caught by this same self-review
pass before the infrastructure-layer branch was first committed, so the
fix is not a separate follow-up commit — it is already the content of
`terraform/variables.tf` in commit `93a7b7d` ("infra: provision
kijani-staging namespace via Terraform, configure via Ansible",
`feature/capstone-infrastructure-layer`). Verifiable by running
`terraform validate` in `terraform/` at that commit: it passes.
