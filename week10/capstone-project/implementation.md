# Implementation Summary & Walkthrough

Track A (Infrastructure-First) capstone, built on top of the Week 9
`kk-payments` Kubernetes deployment. This document is a guided tour of what
was built, why, and how to walk through it — `README.md` is the
reference doc; this is the narrative version.

## What problem this solves

Before this capstone, `kk-payments` had one environment (`kijani-project`,
production) and the Week 10 serverless receipt chain existed only as a
brief, never actually wired to a real payment. Two gaps, closed here:

1. **No staging environment** — every change to `kk-payments` was tested
   against production configuration, with no isolation and no automated
   gate before a deploy reached production.
2. **The receipt chain never fired for real** — nothing in the Kubernetes
   layer wrote the S3 object that `kk-receipts` is supposed to react to.

Full problem statement, success criteria, and what's deliberately out of
scope: `docs/scope.md`.

## The four layers, in build order

### 1. Infrastructure — `terraform/`, `ansible/`
- `terraform/main.tf` provisions the `kijani-staging` namespace, isolated
  from `kijani-project`. The Kubernetes provider is pinned explicitly to
  the `minikube` context (`variables.tf`'s `kube_context`) rather than
  trusting whatever the ambient kubeconfig's current-context happens to
  be — this repo has previously had that context point at a foreign
  cluster, so pinning it is a deliberate, defensive default.
- `ansible/playbook.yml` renders `kk-payments`'s staging ConfigMap from
  `ansible/templates/kk-payments-configmap.yaml.j2` + `group_vars/staging.yml`
  — same keys as production, different values (`DB_HOST`, `LOG_LEVEL`,
  `RECEIPTS_BUCKET`).
- **Single source of truth for names:** the receipts bucket name is
  declared once in `ansible/group_vars/staging.yml`
  (`kijani-payments-receipts-staging`) and read by three places that must
  never disagree: the ConfigMap Ansible renders, `serverless.yml`'s
  `custom.receiptsBucket`, and this doc's walkthrough commands below.

### 2. Delivery — `Jenkinsfile`, `scripts/smoke-test.sh`
On a merge to `main`, the pipeline runs, in order:
`build image` → `terraform apply` → `ansible-playbook` → `deploy to
kijani-staging` → `smoke test` → **production approval gate** → `deploy
to kijani-project`.

The gate is a plain `input` step that is the *next pipeline stage after*
the smoke-test stage — Jenkins never reaches it if the smoke test stage
failed, which is how "only offers the approval gate after the smoke test
passes" is enforced, without any extra conditional logic. The gate records
an `APPROVAL_REASON` and the approving user in the build log.

`scripts/smoke-test.sh` does two things against staging: confirms
`/health` reports `ok`, and — the more meaningful check — calls
`POST /pay` and confirms a receipt file actually landed in the local S3
mock. A smoke test that only pings `/health` would pass even if the
receipt-writing code path were completely broken; this one exercises the
actual integration seam the capstone is about.

### 3. Runtime — `k8s/`, `kk-payments-image/`
- `k8s/kk-payments-deployment.yaml` and `kk-payments-service.yaml`
  deliberately have **no `namespace` field**. The exact same file is
  applied to both `kijani-staging` and `kijani-project` via
  `kubectl apply -f ... -n <namespace>` — this is what "same Deployment
  manifest used for both environments" means in practice, not two
  near-identical copies that can drift.
- `kk-payments-image/server.js` gained a `POST /pay` endpoint. It computes
  a total (reusing `payments.js` from Week 9), builds a receipt object,
  and calls `receipts.js`'s `writeReceipt()`, which does a local-S3-mock
  `PutObject` — writes a JSON file to `$S3_LOCAL_ROOT/<bucket>/receipt-<id>.json`.
  This is the exact write that fires the serverless chain.
- Every request also emits one structured JSON log line
  (`{timestamp, status_code, duration_ms, correlation_id, ...}`), which is
  what the monitoring layer (below) consumes.

### 4. Intelligence / Observability — `serverless/`, `monitoring/`
- `serverless/serverless.yml` declares three S3-triggered functions:
  `kk-receipts` (validates, forwards) → `kk-processor` (adds a tax line) →
  `kk-notifier` (logs the final structured summary). Bucket names are
  declared once in `custom.*` and reused in both `provider.environment`
  and the `resources` block, so the AWS resource and the function's env
  var can't diverge.
- `serverless/handlers/*.js` are the actual function bodies — plain,
  testable Node modules with no framework lock-in in the handler logic
  itself, only in how they're invoked.
- `scripts/run-local-chain.js` is a small local runtime: it `fs.watch`es
  the three local S3 mock directories and calls the same handler modules
  directly when a new file appears. This is what makes the chain
  demoable without a full `serverless-offline` + `serverless-s3-local`
  stack running — real alternative, not a stub (see `docs/runbook.md` for
  when to use `npm run offline` instead).
- `monitoring/error-rate.js` reads `kk-payments`' structured logs from
  stdin, keeps lines within a trailing window (default 120s), and applies
  the same condition a Prometheus rule would:
  `sum(rate(5xx[2m])) / sum(rate(total[2m])) > 0.05`. This is Track A's
  **Option B** (log-based), used instead of Option A (Prometheus) because
  no Prometheus instance exists in this environment — `monitoring/README.md`
  shows both forms side by side. It writes `error-rate-summary.json` and
  exits non-zero on alert, which is what lets the Jenkins smoke-test stage
  use it as a real gate rather than an informational check.

## Walkthrough: watch a payment become a notified receipt

This is the sequence to actually run live (see `docs/runbook.md` for the
full from-Kubernetes version with minikube in the loop; this is the fast,
local version for exploring the code):

```bash
cd week10/capstone-project

# terminal 1 — the payments service
RECEIPTS_BUCKET=kijani-payments-receipts-staging \
NODE_ENV=staging APP_PORT=13099 node kk-payments-image/server.js

# terminal 2 — the receipt chain watcher
node scripts/run-local-chain.js staging

# terminal 3 — fire a payment
curl -X POST http://127.0.0.1:13099/pay \
  -H 'Content-Type: application/json' \
  -d '{"items":[{"name":"Coffee","price":150,"quantity":2}]}'
```

Expected: terminal 1 logs one JSON line for the `/pay` request (`status_code:201`).
Terminal 2 logs three lines in order — `kk-receipts` → `kk-processor` →
`kk-notifier` — all carrying the same `orderId`, the last one showing
`totalWithTax` (16% VAT added) and a `chainLatencyMs` in the low hundreds.
This exact run was captured during the build and is cited as evidence in
`docs/peer-feedback-log.md` Issue 2.

## What's genuinely tested vs. what's a documented gap

**Actually run and verified during the build** (not just written and
assumed correct):
- `terraform validate` — caught and fixed a real HCL parse bug (a
  `${self:custom.stage}` literal inside a Terraform `description` string
  that the parser tried to interpret as its own interpolation syntax).
- `ansible-playbook --syntax-check` — clean.
- The full receipt chain, end-to-end, as a plain Node process — confirmed
  correct several times over.
- The failure path — `RECEIPTS_BUCKET` unset returns `500`, not a silent
  dropped receipt.
- Both required PDFs (`scope.pdf`, `reflection.pdf`) — page count verified
  programmatically with `pypdf`, not eyeballed.

**Documented, not run, and why** — see `docs/runbook.md` "The integration
seam that breaks first" and the README's "Known limitations":
- The from-Kubernetes path (kk-payments as an actual Pod, chain firing
  across the minikube-VM-to-laptop filesystem boundary) was not run in
  this environment. The `hostPath` volume approach in
  `k8s/kk-payments-deployment.yaml` has a known gap on minikube's `docker`
  driver, fixed with `minikube mount` — documented rather than silently
  shipped.
- No real Jenkins controller executed the `Jenkinsfile` — it's a real,
  syntactically-structured pipeline matching the Week 5/7 house style, not
  smoke-tested against a live Jenkins instance.
- No real AWS account — the serverless chain runs against the local S3
  mock, per `docs/scope.md`'s explicit out-of-scope call.

## Governance and process artifacts

- `docs/ai-governance-log.md` — three entries in the required eight-field
  format, each describing an actual mistake made and caught during this
  build (a Jenkinsfile shell-logic bug, the hostPath/minikube-driver
  assumption above, and the PDF page-count miss), not hypothetical
  examples.
- `docs/governance-checklist.md` — the six-point checklist project.md
  references but doesn't reprint (reconstructed here, since no
  `week10/friday` submission exists in this repo to source it from).
- `docs/test-plan.md` / `docs/peer-feedback-log.md` — a documented
  self-review (no second engineer was available in this session), with
  three findings backed by commands actually run, not narrated.

## Git history

Six feature branches (`feature/capstone-infrastructure-layer`,
`-runtime-configuration`, `-serverless-chain`, `-delivery-pipeline`,
`-docs`, `-ai-governance`), each merged `--no-ff` into
`feature/deployment-pipeline` with a conventional commit message, tagged
`v1.0.0` (annotated). Everything is local — nothing has been pushed or
opened as a PR/Issue on GitHub yet. One honestly-flagged gap: every commit
landed in a single session rather than spread across multiple calendar
days (`docs/reflection.md`, "second pass" answer names this directly).
