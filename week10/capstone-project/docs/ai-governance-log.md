# AI Governance Log

Eight-field format per project.md Page 2. All entries are from the actual
capstone build session (Claude Code, agentic CLI mode) — the AI wrote
essentially all first-draft code in this repository, so this log documents
what was caught and changed during that same session rather than a
separate after-the-fact review.

---

### Entry 1

- **Date:** 2026-08-16
- **Tool used:** Claude (Claude Code CLI, Sonnet 5)
- **Task description:** Write the `Jenkinsfile` "Build image" stage: build the `kk-payments` Docker image into minikube's Docker daemon so the Deployment's `imagePullPolicy: IfNotPresent` can find it without a registry.
- **What was provided to the AI:** The Week 8/9 convention of building images directly into `minikube docker-env`, and the requirement that the pipeline run without manual steps.
- **What the AI produced:** A stage with two `sh` steps: an unconditional `docker build` against the host Docker daemon, followed by a fallback line `minikube image load ... || eval $(minikube docker-env) && docker build ...`.
- **What it got right:** Correctly identified that the image needs to land in minikube's daemon, not the host's, for `IfNotPresent` to work.
- **What it got wrong:** The first `docker build` ran against the *host* daemon (wrong target), and the fallback line's operator precedence (`||` and `&&` on one line) meant the `docker build` after `&&` only ran if `minikube image load` failed — silently building a stale/host-side image on the common path where nothing failed yet. This would have made every staging deploy pick up the previous image tag. Checked against governance checklist control 3 (idempotency) — the stage was not safely re-runnable and its "success" path didn't do what the stage name claimed.
- **What was changed before applying the output:** Replaced both lines with a single `sh` block that runs `eval $(minikube docker-env)` and `docker build` in the same shell invocation, so every run builds into the correct daemon with no conditional fallback to reason about. See `Jenkinsfile`, "Build image" stage.

---

### Entry 2

- **Date:** 2026-08-16
- **Tool used:** Claude (Claude Code CLI, Sonnet 5)
- **Task description:** Design the `kk-payments-deployment.yaml` mechanism for sharing the local S3 mock directory (`/tmp/kijani-s3-local`) between `kk-payments` (running as a Pod) and the serverless receipt chain (running on the host), so a `/pay` call in Kubernetes actually fires the chain.
- **What was provided to the AI:** The requirement that "kk-payments in staging writes to the kk-payments-receipts-staging bucket and the receipt chain fires correctly," and the existing local-S3-mock convention (`S3_LOCAL_ROOT`) from earlier weeks.
- **What the AI produced:** A `hostPath` volume mount at `/tmp/kijani-s3-local` in the Deployment spec, on the (unstated) assumption that the Pod's host filesystem is the same as the developer's laptop filesystem.
- **What it got right:** `hostPath` is the correct primitive for sharing a host directory with a Pod in general, and the env var / mount path naming stayed consistent with the rest of the stack.
- **What it got wrong:** On minikube's default `docker` driver, "host" from the Pod's perspective is the minikube VM/container, not the laptop — so the hostPath silently points at a *different* `/tmp/kijani-s3-local` than the one the serverless chain watches on the laptop. The chain would appear to "not fire" with no error anywhere, and nothing in the manifest or a first read of it reveals why. Checked against governance checklist control 4 (blast radius) and control 5 (drift risk) — this is exactly the class of seam failure project.md warns about (ConfigMap-name / bucket-name mismatches), just one level deeper (filesystem instead of a name).
- **What was changed before applying the output:** Did not change the manifest (hostPath is still the right primitive for a from-Kubernetes demo), but added an explicit "The integration seam that breaks first" section to `docs/runbook.md` documenting the failure mode and the fix (`minikube mount`), plus a same-process fallback for demoing the chain without minikube in the loop. Documented as a known limitation rather than silently shipped.

---

### Entry 3

- **Date:** 2026-08-16
- **Tool used:** Claude (Claude Code CLI, Sonnet 5)
- **Task description:** Export `docs/scope.md` to a one-page PDF per project.md's "1 page PDF + PNG diagram" deliverable format, using `pandoc scope.md -o scope.pdf` as project.md suggests.
- **What was provided to the AI:** The scope document content and the one-page constraint from the rubric (Dimension 1, Exemplary: "Scope document is one page").
- **What the AI produced:** Ran `pandoc scope.md -o scope.pdf` directly.
- **What it got right:** Correctly diagnosed the resulting `pdflatex not found` error and pivoted to an HTML-intermediate + headless-Chrome-print-to-pdf approach without needing a new LaTeX install.
- **What it got wrong:** The first PDF produced from that pivot was 2 pages, not 1 — default browser print margins and font size don't respect a "one page" intent on their own, and the AI did not check page count before treating the task as done.
- **What was changed before applying the output:** Added `docs/pdf-style.css` (tighter margins, smaller base font/line-height, compact heading spacing) and verified page count programmatically with `pypdf` (`len(reader.pages) == 1`) before accepting the result, rather than eyeballing the rendered PDF. Wrapped the fixed process in `scripts/md-to-pdf.sh` for reuse on `docs/reflection.md`.
