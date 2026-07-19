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
- Fault: `src/payments.js` — removed the closing `}` of `calculateTotal`, producing an unclosed block (commit `e48c124`).
- Build number: #9 (fault) / #10 (revert, confirmed green)
- What happened: ESLint failed to parse the file — `15:1 error Parsing error: Unexpected token`. Build, Verify (both Test and Security Audit branches), Archive, and Publish all logged `Stage "<name>" skipped due to earlier failure(s)`. Pipeline result: FAILURE.

### Build fault
- Fault: `package.json` — changed the `build` script from `node scripts/build.js` to `node scripts/build-missing.js`, a nonexistent file (commit `59d5690`).
- Build number: #11 (fault) / #12 (revert, confirmed green)
- What happened: Lint passed. `npm run build` exited with `Error: Cannot find module '.../scripts/build-missing.js'`, `code: 'MODULE_NOT_FOUND'`. Verify, Archive, and Publish all skipped ("Stage ... skipped due to earlier failure(s)"). Pipeline result: FAILURE.

### Test fault (inside Verify)
- Fault: `test/payments.test.js` — changed the expected value in `calculateTotal sums price * quantity across items` from `35` to `999999` (commit `900cb5e`).
- Build number: #14 (fault) / #15 (revert, confirmed green)
- What happened: Lint and Build passed. Inside Verify, the Test branch reported `not ok 1 - calculateTotal sums price * quantity across items` (`35 !== 999999`, `# pass 3 / # fail 1`), while the Security Audit branch independently logged `found 0 vulnerabilities` immediately after `Failed in branch Test` in the console — proving it ran to completion despite Test failing. Verify overall failed; Archive and Publish skipped. Pipeline result: FAILURE.

### Security Audit fault (inside Verify)
- Fault: `package.json` — added `"dependencies": { "minimist": "0.0.8" }`, a version with a known **critical** prototype-pollution vulnerability (GHSA-vh95-rmgr-6w4m / GHSA-xvch-5gv4-984h), well above the `--audit-level=high` threshold (commit `40804a6`).
- Build number: #16 (fault) / #17 (revert, confirmed green)
- What happened: Lint and Build passed. Inside Verify, the Test branch completed fully first — `# tests 4 / # pass 4 / # fail 0` logged before `Failed in branch Security Audit` appears — proving Test ran to completion independently despite the audit failing. `npm audit --audit-level=high` reported `1 critical severity vulnerability` for minimist and exited non-zero. Verify overall failed; Archive and Publish skipped. Pipeline result: FAILURE.

### Publish fault
- Fault: `Jenkinsfile` — changed `credentialsId: 'nexus-credentials'` to `credentialsId: 'wrong-id'` in the Publish stage's `withCredentials` block (commit `f4a9e03`).
- Build number: #18 (fault) / #19 (revert, confirmed green)
- What happened: Lint, Build, Verify all passed. Archive succeeded and fingerprinted the artifact (visible under build #18's "Artifacts" tab in Jenkins). Publish failed immediately with `ERROR: Could not find credentials entry with ID 'wrong-id'`, before `npm publish` ran. Confirmed via Nexus REST search (`GET /service/rest/v1/search?repository=npm-kijanikiosk&name=kijanikiosk-payments&version=0.1.0-f4a9e03`) that no artifact for that version was published (`"items": []`). Pipeline result: FAILURE.

All faults reverted; pipeline confirmed green again after each row — build numbers #10, #12, #15, #17, #19.
