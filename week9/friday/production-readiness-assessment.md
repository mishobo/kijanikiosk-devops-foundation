# Production Readiness Assessment — kijani-project

*Assessed against Nia's three questions: external routing, health signalling, and capacity.*

## External routing — not production-ready

The Ingress routes `/api` and `/payments` correctly and both backends show healthy
Endpoints, but it serves **plain HTTP only**. `kk-payments` moves card data, a
`STRIPE_API_KEY`, and JWTs; over HTTP every request — including the `DB_PASSWORD`
and Stripe key carried inside payment calls — travels in cleartext and can be read
or modified by anyone on the path. The fix is to terminate TLS at the Ingress: create
a `kubernetes.io/tls` Secret holding the cert/key (in practice issued by a
cert-manager `Certificate`/`ClusterIssuer`) and reference it under `spec.tls` for
host `kijani.local`, backed by the `nginx.ingress.kubernetes.io/ssl-redirect: "true"`
annotation so HTTP is 308-redirected to HTTPS. A second gap is the total absence of
**rate limiting**: the payments endpoint is open to brute-force and card-testing abuse.
`nginx.ingress.kubernetes.io/limit-rps` (with `limit-connections`) caps per-client
request rate at the controller before traffic ever reaches a Pod. (Authentication via
`nginx.ingress.kubernetes.io/auth-url` is a third gap — the routes are currently
unauthenticated at the edge.)

## Health signalling — probes are too aggressive for a payment service

The probes hit `/health`, but the values are tuned for a trivial service, not one that
opens a database pool on boot. Readiness `initialDelaySeconds: 5` likely marks a Pod
Ready before its `MAX_CONNECTIONS` pool to `DB_HOST` is warm, so the first real
transactions hit an unready backend. I would raise readiness `initialDelaySeconds` to
~15s (or add a `startupProbe` so the liveness clock does not start until boot
completes). The more dangerous value is `failureThreshold: 3` on the **liveness**
probe with `periodSeconds: 20`: under a temporary database slowdown, three missed
checks (~60s) will make the kubelet **kill and restart a Pod that is merely slow, not
dead** — turning transient DB load into a self-inflicted restart storm that removes
capacity exactly when demand is highest. For liveness I would raise `failureThreshold`
to 5–6 and keep readiness stricter, so a struggling Pod is pulled from the Service
(stops receiving traffic) without being killed.

## Capacity — 3 fixed replicas is not an answer for month-end spikes

Three replicas with manual scaling cannot absorb end-of-month load; someone has to be
awake to run `kubectl scale`. Autoscaling requires three things to be true: the
**metrics-server** addon must be running, the Deployment must declare **resource
requests** (it does: `cpu: 100m`), and an **HPA** must target CPU utilisation with
`minReplicas`/`maxReplicas`. The target percentage is the trap. Set it **too high**
(e.g. 90%) and the HPA scales out only after Pods are already saturated — latency and
timeouts hit customers before new Pods are Ready. Set it **too low** (e.g. 20%) and the
HPA over-provisions on minor noise, burning cluster budget and risking flapping (scale
up/down churn). A target around 60–70% CPU, plus scale-down stabilisation, balances
headroom against cost.

## Bottom line

Correct, declarative, and safely rollback-able — but not customer-ready until TLS,
edge rate limiting, probe re-tuning, and an HPA are in place.
