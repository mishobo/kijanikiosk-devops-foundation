# Two Ways to Deploy the Payments Service — A Comparison for the Board

Prepared for: Nia (engineering lead), ahead of the board presentation.
Evidence sources: the rollback and self-healing measurements in this submission's evidence files.

## What we compared

We ran the payments service two ways, end to end. The first is our current approach: two complete copies of the service run side by side on a rented server, one live and one on standby, and we move customer traffic between them like switching points on a railway. The second is the newer approach: the service is packaged into a sealed, self-contained unit, and a cluster manager runs several identical copies at once, watching each one and replacing any that dies.

Both approaches were tested with a deliberate failure, and both recovered without a human touching anything. The difference is in who does the recovering, how fast, and how much of the machinery we had to build ourselves.

## The numbers that matter

With the side-by-side approach, we injected a fault into a freshly released version and measured the automated recovery at **12 seconds** from the moment the fault appeared to the moment customers were back on the proven version. That recovery works because we wrote and maintain the watchdog ourselves; it is our code, our responsibility, and our 2 a.m. page if it misbehaves.

With the cluster approach, we killed one of the two running copies outright. The cluster noticed and had a replacement copy fully running in **2 seconds**, with the second copy carrying customers in the meantime. Nobody wrote a watchdog for this; replacing dead copies is simply what the cluster does, all day, for every service it runs.

Packaging also got dramatically smaller. A naive package of the service weighed 193 megabytes; the production package we built is 90 megabytes, a reduction of more than half. Smaller packages move faster from storage to a running state, which directly shortens both deployments and recoveries, and they contain fewer components that could carry security flaws.

## Side-by-side comparison

| Concern | Blue/green on servers | Containers on Kubernetes |
|---|---|---|
| Deployment mechanism | Deploy new version to the idle environment (green), verify health on its own port, then rewrite the nginx upstream and reload to move traffic in one step | Push an immutable image (VERSION-GITSHA tag) to the registry; the Deployment pulls it and rolls Pods forward, replicas kept at 2 throughout |
| Rollback mechanism | Custom monitor (5 s polls, 3 consecutive failures) triggers switch-env.sh back to blue; measured fault-to-recovery: 12 s; depends on state files being consistent | Re-point the Deployment at the previous image tag; the cluster rolls Pods back; every historical tag in the registry is a rollback target |
| Failure recovery | Only what we scripted is detected; a failure mode the monitor doesn't poll for goes unnoticed; recovery restores exactly one standby | ReplicaSet self-healing is built in: replacement Pod Running in 2 s (measured); liveness/readiness probes (next project) extend what "healthy" means |
| Scaling | Vertical only in practice; adding capacity means provisioning and configuring another server by pipeline, in minutes-to-hours | Change the replica count; the scheduler places new Pods in seconds, limited only by cluster capacity |

## What this does not yet solve

Honesty matters more than enthusiasm here. The cluster approach we demonstrated runs on a single laptop-hosted cluster, so the machine underneath is still a single point of failure — we proved the service heals itself, not that the platform survives losing a whole computer. Configuration and passwords are still written directly into the deployment description rather than managed separately, which is workable in a lab and unacceptable in production. Traffic is reachable through a fixed doorway rather than a proper front door with certificates and a memorable address. And the cluster currently considers a copy "alive" the moment it starts, not the moment it is genuinely ready for customers — a gap that briefly existed in our old approach too, and that we papered over with a startup grace period. The next project addresses exactly these gaps: separating configuration from code, storing secrets properly, and teaching the cluster the difference between "running" and "ready" so that traffic only ever reaches copies that can serve it. Until then, the honest position is that blue/green remains our production strategy, and the cluster approach is a proven candidate — with better recovery numbers — that is one project away from being production-ready.

---

*Word count: 693 (prose and table). The two measured figures — 12 s and 2 s recoveries, and the 193 MB → 90 MB package reduction — come directly from rollback-evidence.txt, self-healing-rerun.txt, and build-verification.txt.*
