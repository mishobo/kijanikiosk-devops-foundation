# Post-Incident Review — Pipeline targeted the wrong environment during investor demonstration

Incident date: 2026-07-24 (during the Week 5 CI pipeline demonstration)
Duration of impact: 48 seconds of staging unavailability
Severity: Sev-2 (no customer impact; reputational risk during an investor demonstration)
Author: Amina (Platform) — reviewed by Tendo

## Section 1 — Incident summary (for Nia)

During a live walkthrough for investors, our release automation was pointed at the wrong copy of the system: instead of updating the rehearsal copy it was supposed to touch, it updated the one being shown on screen. The system being demonstrated went unavailable for 48 seconds before the team restored it. No customer data or money was affected, because customers never use this copy of the system — but the people watching saw it fail, which is exactly the kind of moment this review exists to prevent.

## Section 2 — Timeline (reconstructed)

Timestamps are reconstructed from the run log retained from the demonstration and from the narrative; where a precise time could not be recovered it is marked **estimated** with the basis stated. An honest partial timeline is more useful than a fabricated precise one.

| Time (UTC) | Event | Basis |
|---|---|---|
| 09:02 | Investor walkthrough begins; staging dashboard on screen | calendar invite |
| 09:14 | Engineer triggers the deployment pipeline to show a release | pipeline run log |
| 09:14:30 **(estimated, ±30 s)** | Pipeline resolves its target from a default environment variable and begins deploying to staging — the environment on screen — instead of the intended demo sandbox | inferred: the run log shows no explicit target parameter, so the default applied at job start |
| 09:15 **(estimated, ±1 min)** | The proxy on staging begins returning errors as the deploy restarts the service under live viewing | narrative states errors appeared "within a minute" of the trigger |
| 09:15:20 | Engineer notices the dashboard erroring and recognises the wrong target | narrative; consistent with 48 s outage ending 09:15:48–09:16:08 |
| 09:15:48 **(estimated, ±20 s)** | Service restored after the deploy completed its restart; total unavailability 48 seconds | outage duration is from the proxy error-log gap, which was retained |
| 09:22 | Team confirms sandbox was never touched; walkthrough resumes | narrative |

## Section 3 — Root cause

The specific configuration gap: **the pipeline's target environment was an optional parameter with a hard-coded default of `staging`, and nothing between "trigger" and "deploy" required the target to be stated explicitly or confirmed.**

Five whys:

1. **Why did staging go down during the demonstration?** The pipeline deployed to staging and restarted its service while it was being viewed.
2. **Why did the pipeline deploy to staging?** The engineer triggered the job without passing a target, and the job's `DEPLOY_ENV` parameter defaulted to `staging`.
3. **Why did the parameter default to `staging`?** When the pipeline was built (Week 5), staging was the *only* environment, so a default was convenient and harmless; the demo sandbox was added later and the default was never revisited.
4. **Why was the default never revisited when a second environment was added?** There is no checklist or review step for "a new environment was added" — environment definitions live in the pipeline configuration, and changes to the *set of environments* are not treated as changes that require re-reviewing existing jobs.
5. **Why does the pipeline not refuse an implicit target?** Because it was designed for convenience in a single-environment world: the structural finding is that **the pipeline treats the deployment target as an inferable detail rather than as a required, validated input** — the same class of gap that would one day let it deploy to production implicitly.

Root cause (structural): a deployment system that infers its blast radius from defaults instead of requiring it as explicit, validated input. "The engineer forgot to pass the parameter" is where the analysis begins, not where it ends.

## Section 4 — Contributing factors

- **Two environments, one credential set.** The pipeline's credentials could reach both staging and the sandbox, so a wrong target was executable, not merely expressible.
- **No pre-deploy confirmation in interactive runs.** A manually triggered run behaves identically to an automated one; there is no "you are about to deploy vX to ENV" gate for human-initiated deployments.
- **Demonstration used a shared environment.** The thing on screen was also a thing the pipeline could touch; rehearsal and automation shared a blast radius.
- **Time pressure.** The trigger happened live, in front of investors, where the cost of pausing to double-check flags feels highest and is actually lowest.

## Section 5 — What went well

- **Detection was human but fast, and recovery was faster:** the engineer recognised the wrong-target deploy within seconds, and the service self-restored in 48 seconds because the deploy itself completed cleanly — the outage was a restart window, not a broken release.
- The proxy error logs were retained, which is the only reason the 48-second figure and parts of this timeline are evidence rather than memory.

## Section 6 — Action items

| # | Action | Owner (role) | Target |
|---|---|---|---|
| 1 | Make the deployment target a **required** pipeline parameter with no default: the job fails immediately with a clear message if `DEPLOY_ENV` is absent, and validates the value against an allow-list | CI pipeline maintainer (Platform) | 1 week |
| 2 | Add an interactive confirmation gate for manually triggered deploys: human-initiated runs must acknowledge a "deploying VERSION to ENV" prompt before execution; automated (webhook) runs are exempt and audited instead | CI pipeline maintainer (Platform) | 2 weeks |
| 3 | Split credentials per environment: the pipeline job for the sandbox holds only sandbox credentials, so a wrong target fails authentication instead of succeeding | Infrastructure owner (Platform/Security) | 1 month |
| 4 | Add "re-review defaults of all existing jobs" as a mandatory step in the runbook for adding or renaming an environment, enforced via a pull-request template checklist on the pipeline repository | Engineering lead (Tendo) | 2 weeks |

None of these is "be more careful": each changes the system so that the careless path either cannot execute (1, 3), requires explicit acknowledgement (2), or cannot be skipped silently (4).
