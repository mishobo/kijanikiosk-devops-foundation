# Fault Injection Log

For each row: introduce the fault, push, observe the run in the Jenkins stage
view, then revert the fault and push the clean version again before moving to
the next row. Never stack two faults at once.

| Stage faulted | Fault introduced | Expected behaviour | Observed? (Y/N) | Explanation |
|---|---|---|---|---|
| Lint | Syntax error in source file | Build, Verify, Archive, Publish all skip | | |
| Build | Invalid `npm ci` flag | Verify, Archive, Publish all skip | | |
| Test (in Verify) | Deliberate failing assertion | Security Audit runs to completion; Archive, Publish skip | | |
| Publish | Wrong `credentialsId` | Archive ran; artifact fingerprinted in Jenkins but never reached Nexus | | |

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
- Confirm Security Audit's branch still completed independently (parallel stages don't share failure state until Verify overall is evaluated).

### Publish fault
- Fault: <describe exact change, e.g. credentialsId: 'wrong-id'>
- Build number: <#>
- What happened:
- Confirm: Archive stage succeeded and the artifact is visible under the Jenkins build's "Artifacts" tab, but `curl` against the Nexus search API shows no new version.
