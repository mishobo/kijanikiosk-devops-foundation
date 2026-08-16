# Slide Deck — KijaniKiosk Capstone (Track A)

Speaker notes in *italics*; export this file to PDF for submission
(`./scripts/md-to-pdf.sh docs/slide-deck.md "Capstone Slide Deck"`, or a
proper slide tool if you want real slide breaks for the live presentation).

---

## 1. Title
**KijaniKiosk Capstone — Track A: Infrastructure-First**
[Your name] · [Date] · github.com/mishobo/kijanikiosk-devops-foundation

---

## 2. Problem
kk-payments deploys to a single environment with no isolation between
testing and production, and the Week 10 serverless receipt chain has never
actually been fired by a real payment. *One paragraph, matches
`docs/scope.md` problem statement verbatim.*

---

## 3. Architecture
![architecture](architecture.png)
*Walk every arrow: Terraform → namespace, Ansible → ConfigMap, Jenkins →
both namespaces, kk-payments → S3 receipt, S3 event → each serverless
function, kubectl logs → error-rate monitor → gates the approval stage.*

---

## 4. Key Decision
**I chose a shared local S3 mock directory (`/tmp/kijani-s3-local`) over a
real AWS bucket for the receipt chain integration, because it requires no
cloud account for local development and keeps the demo reproducible on a
laptop with no network dependency.** The trade-off: on minikube's `docker`
driver, the Pod's filesystem and the laptop's are not the same `/tmp`,
which is a real seam failure documented in `docs/runbook.md` and fixed
with `minikube mount`. In production this would be a real S3 bucket with
IAM roles, and the seam would move from "shared /tmp directory" to
"correctly scoped IAM policy" — a different, more standard problem.

---

## 5. AI Tooling
Built with Claude (Claude Code CLI) as the primary author of first-draft
code across Terraform, Ansible, the Jenkinsfile, the serverless handlers,
and this documentation.
- **Right:** correctly identified the minikube-docker-daemon build target
  convention and the ConfigMap/bucket-name DRY pattern project.md calls out.
- **Wrong:** shipped a broken conditional in the Jenkinsfile's build stage
  and a hostPath assumption that silently breaks on minikube's docker
  driver — both caught and fixed/documented in `docs/ai-governance-log.md`.
- **Changed:** rewrote the Jenkinsfile build stage as a single shell block;
  added the runbook's "integration seam that breaks first" section instead
  of silently shipping the hostPath assumption.

---

## 6. Production Gaps
1. **No real S3/IAM** — `serverless.yml`'s `resources` block declares real
   AWS S3 buckets but nothing has run `serverless deploy` against a real
   account; remediation: provision via CI with a scoped IAM role restricted
   to the three named buckets (already least-privilege in the `iam.role.statements` block).
2. **No staging database** — `DB_HOST` in the staging ConfigMap has no
   backing Postgres instance; remediation: add a `kk-postgres` StatefulSet
   or managed RDS instance per environment before kk-payments makes real
   DB calls.
3. **Jenkinsfile not exercised against a live Jenkins controller in this
   repo's own CI** — remediation: stand up a Jenkins instance (Docker
   Compose is sufficient for a demo) and point a Pipeline job at this repo
   before the next iteration.

---

## 7. Governance Checklist (optional depth slide)
`docs/governance-checklist.md` — six controls (secrets, least privilege,
idempotency, blast radius, drift risk, human review evidence) applied to
every AI-generated file in this repo; see `docs/ai-governance-log.md` for
which controls caught which issues.
