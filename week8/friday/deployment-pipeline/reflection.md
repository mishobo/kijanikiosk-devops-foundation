# Week 8 Reflection

## 1. Where the plain language overclaimed

The demo script says the watchdog "moves every customer back to the proven old version. No pager. No phone call. No human." That sentence overclaims in two ways. First, "every customer" glosses over the roughly 11 seconds between the fault and the rollback during which real requests failed — at 50,000 requests an hour that is about 150 failed requests, not zero. Second, "the proven old version" implies the old version is guaranteed good, when all we actually know is that it passed the same health check the broken version initially passed. A more precise phrasing that a board member can still follow: "Within about ten seconds the system noticed customers were failing and sent them back to the version that had been serving them reliably all week. A small number of requests failed during those seconds — far fewer than when a person had to notice first." It trades a little polish for a claim I can defend with the evidence file.

## 2. The highest-value action item

Action item 1: make the deployment target a required, validated parameter with no default. I am fairly confident — perhaps 80% — that it prevents a literal recurrence, because the incident's direct path (trigger with no target → default applies → wrong environment) becomes impossible: the run fails at parse time instead. The remaining 20% is what I would need to inspect the pipeline's actual implementation to close: whether any *other* code path re-introduces a default (a wrapper script that passes `staging` "helpfully", a scheduled job with the value baked in, or an environment variable set at the agent level that the job inherits). A required parameter only protects the entry points that go through the parameter check. Before claiming certainty I would audit every trigger path — manual, webhook, scheduled — and grep the agent environment for `DEPLOY_ENV`.

## 3. What carries forward from the blue/green rollback machinery, and what becomes redundant

The **concepts** carry forward almost entirely: keep the last known-good version runnable, define health as an externally observable check, decide rollback automatically against a threshold, and never let the system sit in an ambiguous state. The **implementations** mostly do not. The state files (`.active-env`/`.previous-env`) become redundant — Kubernetes stores the equivalent (current and previous ReplicaSet, rollout history) in the cluster itself, with better consistency guarantees than two text files we must remember to write in the right order. The switch script's job is absorbed by the Service selector and rolling updates. The rollback script becomes a one-line change of image tag (or `rollout undo`). The piece that genuinely survives is the monitor: Kubernetes replaces a *dead* Pod, but nothing built-in watches a *new release* for elevated failures and reverts the version — that decision logic (our 3-consecutive-failures threshold) still has to exist, whether as our script pointed at the Service, or as a progressive-delivery controller doing the same job. The monitor's concept is the part of our pipeline that was never really about servers.

## 4. Hardcoded values that should come from configuration

Looking at `kk-payments-deployment.yaml`:

- **The port (3001, in three places: containerPort and the PORT env).** If the port must change, someone has to find every occurrence in the manifest and the Service and keep them agreeing; a missed one produces a service that is Running and unreachable.
- **`APP_VERSION` / the image tag string.** It is duplicated between the image field and an env var. If they drift, the health endpoint reports a version that is not what is running — which poisons exactly the evidence a rollback decision depends on.
- **`DEPLOY_ENV: "kubernetes"`.** Promoting the same manifest to a second environment (staging vs production cluster) requires editing the file, which means the artifact that was tested is not the artifact that ships.
- **The registry address inside the image reference.** Moving registries (the lab registry will not be the production one) means rewriting manifests instead of changing one configuration value; during a registry migration this hardcoding turns into a mass find-and-replace across every service.
- **Resource requests and limits.** Less obvious, but sizing differs per environment (a lab node vs a production node); baked-in numbers mean either over-reserving in the lab or starving in production.

There are no secrets in this manifest today — the registry credential is already referenced by name, not value, which is the pattern everything above should follow: the manifest names the configuration, ConfigMaps and Secrets carry the values.
