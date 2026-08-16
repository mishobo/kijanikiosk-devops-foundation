# Test Plan

Written before the review session, per project.md's Testing and Feedback
Integration page. Covers the four areas the capstone brief specifies.

## 1. Fresh setup
Follow `README.md` → `docs/runbook.md` "Reproducing the system from a clean
checkout" verbatim, in a shell with no project-specific env vars pre-set.
Note every command that fails, every prerequisite not listed, and every
step that required guessing.

## 2. Happy path
`terraform apply` → `ansible-playbook` → deploy `kk-payments` to
`kijani-staging` → `POST /pay` → confirm a `kk-notifier` log line appears
for the same `orderId` within a few seconds.

## 3. Failure path
Deliberately break one thing and confirm the system fails the way it's
designed to, not silently:
- Set `RECEIPTS_BUCKET` to an empty string in the staging ConfigMap and
  redeploy — `/pay` should return `500 {"error":"RECEIPTS_BUCKET not
  configured"}`, not a silent no-op.
- Push a bad image tag and confirm `kubectl rollout status` fails and the
  Jenkins pipeline stage goes red before reaching the approval gate.

## 4. AI governance review
Read `docs/ai-governance-log.md` and assess: is "what it got wrong"
specific and verifiable against the actual code/diff, or vague boilerplate?
Is at least one entry tied to a named governance-checklist control?

## Reviewer
Self-review (no second engineer available in this session/environment) —
see `docs/peer-feedback-log.md` for the documented run and findings, per
project.md's documented-self-review allowance.
