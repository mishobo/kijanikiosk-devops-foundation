# Pipeline Design Review — KijaniKiosk Payments

Evaluation of the final `Jenkinsfile` (week5/thursday) against the five
principles the board asked for, plus one improvement implemented this round.

## 1. Environment isolation

The pipeline declares a `docker` agent pinned to `node:18-alpine` at the
pipeline level, so every stage runs inside a fresh, disposable container
rather than on the shared Jenkins host. `args '-v /tmp:/tmp'` is the only
host mount, kept deliberately narrow.

- Risk avoided: builds no longer depend on whatever Node/npm version happens
  to be installed on the Jenkins agent, and a compromised or misbehaving
  build cannot touch host state outside `/tmp`.
- Gap: the image tag (`node:18-alpine`) is a minor-version float, not a
  digest pin (`node:18-alpine@sha256:...`). A improvement for later, not the
  one implemented this round.

## 2. Parallel verification

`Test` and `Security Audit` run inside a `parallel` block under the
`Verify` stage. `Test` unstashes the build output and runs `npm test`;
`Security Audit` runs `npm audit --audit-level=high` directly against
`package-lock.json` and needs no build artifact, so it does not unstash.

- Both branches must succeed for `Verify` to pass; a failure in either
  fails the stage and skips Archive/Publish.
- Confirmed in the green run: branch timestamps overlap in the log rather
  than running sequentially (see `green-pipeline-log.txt`).

## 3. Fail-fast ordering and post conditions

`Lint` runs before `Build` so cheap static failures are caught before any
compilation cost is paid. `post { success / failure / changed / always }`
gives:
- `success`: echoes the published artifact version and Nexus URL.
- `failure`: echoes the build URL for log triage.
- `changed`: flags when a build's result differs from the previous one
  (green→red or red→green), useful for on-call signal.
- `always { cleanWs() }`: guarantees the workspace (including any
  `.npmrc` that survived a mid-script crash) is wiped regardless of
  outcome.

## 4. Credential management

Nexus credentials are bound only inside the `Publish` stage via
`withCredentials([usernamePassword(...)])`, scoping their lifetime to the
smallest possible block. The `.npmrc` auth token is built and used entirely
in shell variables inside a single-quoted `sh '''...'''` block, so Groovy
never sees or logs the raw values, and `trap "rm -f .npmrc" EXIT` deletes
the credential file even if `npm publish` fails partway through. No
credential value appears in `environment {}`, in the repository, or in the
build log (verified via `credential-audit.txt`, week5/wednesday).

## 5. Versioned artifact publishing

`ARTIFACT_VERSION` combines `PKG_VERSION` (from `package.json`) with
`GIT_SHORT` (from `git rev-parse --short HEAD`), giving every published
artifact a traceable version tied to both the intended release version and
the exact commit that produced it. `Archive` runs with
`onlyIfSuccessful: true` so a partially-built artifact never gets
fingerprinted, and `Publish` bumps `package.json` to that same version
before `npm publish`, so the version in Nexus always matches the version in
the build log.

## Improvement implemented this round

**`retry(2)` around `npm ci` in the Lint stage.** `npm ci` was previously a
single, unguarded network call to the npm registry; a transient DNS blip or
registry timeout meant the entire pipeline failed and had to be re-triggered
by hand, even though nothing was actually wrong with the code. Wrapping it
in `retry(2)` gives the pipeline two automatic retries before it gives up
and reports a real failure, which removes the most common source of false
red builds without weakening the fail-fast principle for actual lint/build
errors (`retry` only wraps the install step, not the lint or build itself).
