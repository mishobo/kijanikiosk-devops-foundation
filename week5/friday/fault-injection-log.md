# Fault Injection Log — Final Pipeline (week5/friday/Jenkinsfile)

All five stages faulted independently. Only one fault active at a time; the
fault was reverted and the pipeline confirmed green again before moving to
the next row.

| Stage faulted | Fault introduced | Expected behaviour | Observed? (Y/N) | Design rationale |
|---|---|---|---|---|
| Lint | Syntax error in source file | Build, Verify, Archive, Publish all skip | | Fail-fast: a change that isn't even well-formed should never reach a build or test resource, so nothing downstream is allowed to start. |
| Build | Invalid `npm ci` / `npm run build` flag | Verify, Archive, Publish all skip | | There is no working artifact to test, archive, or publish, so every later stage is meaningless until Build succeeds. |
| Test (in Verify) | Deliberate failing assertion | Security Audit still completes independently; Verify overall fails; Archive, Publish skip | | The two Verify branches run in parallel and don't depend on each other, so a failure in one doesn't cancel the other mid-run — but the stage as a whole still fails, which is correct: both checks must pass before anything is published. |
| Security Audit (in Verify) | Dependency pinned to a version with a known high-severity CVE | Test still completes independently; Verify overall fails; Archive, Publish skip | | A high-severity vulnerability is treated exactly as seriously as a failing test — the artifact must not be published with a known-exploitable dependency, regardless of whether the code itself is "correct". |
| Publish | Wrong `credentialsId` in `withCredentials` | Archive succeeds and the artifact is fingerprinted in Jenkins; Publish fails before `npm publish` runs; nothing appears in Nexus | | Archive and Publish are deliberately separate stages: a build that's good enough to keep as a Jenkins artifact isn't automatically good enough to be a versioned, externally-consumable release. Auth failing should stop the release, not silently retry with the wrong identity. |

## Notes per fault

### Lint fault
- Fault: <describe exact change, e.g. file/line>
- Build number: <#>
- What happened:

### Build fault
- Fault: <describe exact change>
- Build number: <#>
- What happened:

### Test fault (inside Verify)
- Fault: <describe exact change>
- Build number: <#>
- What happened:
- Confirm the Security Audit branch's timestamp range in the log to show it ran to completion despite Test failing.

### Security Audit fault (inside Verify)
- Fault: <package + version pinned, and which CVE/severity it corresponds to>
- Build number: <#>
- What happened:
- Confirm the Test branch's timestamp range in the log to show it ran to completion despite the audit failing.

### Publish fault
- Fault: <describe exact change, e.g. `credentialsId: 'wrong-id'`>
- Build number: <#>
- What happened:
- Confirm: Archive stage succeeded (artifact visible under the Jenkins build's "Artifacts" tab), but a `curl` against the Nexus search API for that version returns nothing.

All faults reverted; pipeline confirmed green again after each row (see build numbers above).
