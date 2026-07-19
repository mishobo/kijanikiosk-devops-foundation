# How KijaniKiosk Gets New Code Ready to Ship

## The short version

Every time a developer saves a change to the shared codebase, an automated
process checks whether that change meets our quality bar before it is ever
treated as an approved version of the payments software. Nothing reaches a
customer-facing environment without passing through this process first. That
process is what this document explains.

## From a saved change to a numbered package

Think of it as five checkpoints a change must pass, in order. Each one
confirms something specific, and if a checkpoint fails, everything after it
is skipped automatically.

| Checkpoint | Plain-language question it answers | What it confirms |
|---|---|---|
| Lint | Is the code written the way our team agreed to write it? | Style and obvious mistakes are caught in seconds, before we spend time building anything. |
| Build | Does the code actually turn into a working piece of software? | The payments application compiles and produces something runnable. |
| Test & Security Check | Does it behave correctly, and does it introduce any known vulnerabilities? | Automated tests confirm behavior; a security scan confirms none of our dependencies have a known high-risk flaw. These two checks run at the same time, not one after another, which is why this step doesn't add much extra time. |
| Package | Is there a safe, exact copy of this version saved? | A snapshot of the working software is kept, labeled, and never overwritten. |
| Publish | Is this exact version now available for other systems to use? | The package is uploaded to our internal software registry — Nexus — with a version number that ties it back to the exact change that produced it. Two different changes can never accidentally share a version number. |

If a change clears all five checkpoints, the result is a labeled,
traceable package in our registry, ready for the next stage of delivery to
pick up. That labeling matters more in financial services than almost
anywhere else: if something goes wrong in production, we need to say with
certainty which exact version of the code was running, and which change
introduced it. A vague label like "the latest build" cannot answer that
question under audit. A version number tied to the precise change can.

## What happens when something goes wrong

The system is built so that bad changes are stopped early and stopped
loudly, rather than quietly making it further than they should.

If a change fails any checkpoint — say, it doesn't compile, or a test
fails, or the security scan flags a risky dependency — everything after
that point simply does not run. A broken change never gets packaged, and it
never reaches the registry. The person who made the change gets an
immediate, specific notification telling them which checkpoint failed and
why, so they can fix it and resubmit rather than guessing.

Just as important: nothing about this process depends on someone
remembering to double-check by hand. The checks either run and pass, or the
process stops itself — no person has to notice a problem for the system to
refuse to publish a bad version.

We tested this deliberately, introducing a real fault at each checkpoint
one at a time — bad formatting, broken code, a failing test, a flagged
dependency, a wrong credential — and confirmed the process stopped exactly
where it should and nowhere else, and that publishing never happened for a
bad change. That evidence is attached separately.

## Where the credentials live

The password used to publish to our internal registry is never written
anywhere a person could read it — not in the pipeline definition, not in
any saved log, not anywhere in the project's history. It is stored in one
secured location and used only for the few seconds it takes to publish,
then discarded immediately after.

## What this does not do yet

This process stops at "a trustworthy, labeled version exists in our
registry." It does not yet take that version and put it in front of
customers — that is a separate step, planned for a later phase, and it is
intentionally kept separate so that publishing a version and releasing it
to production are two decisions, not one automatic one. It also currently
allows only one change to go through this process at a time; as the
engineering team grows, that will need to change so multiple developers
aren't waiting on each other. Neither gap affects the reliability of what
is being labeled and stored today — they affect how much further, and how
fast, the system can carry that work.
