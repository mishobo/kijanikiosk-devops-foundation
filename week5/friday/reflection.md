# Reflection — Week 5

> Drafted from the actual design decisions made while building the
> pipeline this week. Personalize the wording and specifics (build numbers,
> exact moments) before submitting — this should read as your own account.

## 1. Where two requirements were in tension

The clearest tension was between **environment isolation** and **build
speed**. Moving to a Docker agent (`node:18-alpine`) for isolation meant
every stage now runs in a throwaway container with none of the Jenkins
host's tooling pre-installed — including `git`, which the version-string
computation depends on (`git rev-parse --short HEAD`). The isolated
environment that makes the pipeline trustworthy is also the one that made
the simplest possible version-tagging step fail on the first run.

The options were: bake a custom image with `git` preinstalled (more
correct, more infrastructure to maintain), or install `git` inline via
`apk add --no-cache git` inside the environment-variable computation
(faster to ship, slightly less clean). I prioritized shipping the working,
documented pipeline this week and installed `git` inline, with the
custom-image approach noted as a follow-up rather than done silently. The
same tension showed up again with `disableConcurrentBuilds()` versus a
proper build-throttling plugin: I chose the simpler option and documented
the limitation rather than leaving it unstated.

## 2. Same fact, two audiences

**Board version** (from `ci-pipeline-board-document.md`):
> "Two different changes can never accidentally share a version number."

**Jenkinsfile / conversation-with-Osei version:**
> "`ARTIFACT_VERSION` concatenates `PKG_VERSION` (read from `package.json`
> via `node -p`) with `GIT_SHORT` (`git rev-parse --short HEAD`), so a
> version collision would require both an unbumped `package.json` and an
> identical commit SHA — i.e., the same commit being published twice, which
> `npm publish` already rejects for an existing version."

What's the same: the underlying guarantee — every published artifact has a
unique, traceable version. What's different: the board sentence asserts the
guarantee as a fact about outcomes; the technical sentence explains the
mechanism (concatenation of two specific values) and the edge case that
would have to hold for the guarantee to fail, which is the information Osei
actually needs to judge whether the guarantee is solid.

## 3. What breaks first at 4 → 40 developers

`disableConcurrentBuilds()` breaks first, and soonest. With four developers,
one queued build at a time is invisible — pushes are infrequent enough that
a build rarely finishes after the next one is already waiting. At forty
developers pushing throughout the day, every build after the first would
queue behind whichever one is running, and a single slow or hung build
(network flake in `npm ci`, a large dependency install) would back up the
entire team's feedback loop, not just one person's.

The fix is a real concurrency model instead of a blanket lock: either the
Throttle Concurrent Builds plugin capping concurrent executions at whatever
the Jenkins/Docker host can actually sustain, or moving to per-branch/PR
build isolation so unrelated changes don't compete for the same queue slot.
That requires knowing the host's real capacity for parallel Docker
containers, which isn't something four developers' worth of traffic ever
forces you to measure — it becomes visible exactly when the team outgrows
it.
