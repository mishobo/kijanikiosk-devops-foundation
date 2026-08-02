# kk-payments — Service Level Indicators and Objectives

Service: `kk-payments` (payments API behind the nginx proxy)
Owner: Platform team (Amina)
Measurement window for all SLOs: rolling 30 days
Status: all targets are **proposed targets (not yet measured against production traffic)** — they were validated only against the staging traffic simulator and must be re-baselined after two weeks of production data.

## 1. Service Level Indicators

### SLI 1 — Availability

**Definition:** the proportion of well-formed HTTP requests to the payments service that receive a successful response (status 200–399), measured at the proxy, over the measurement window.

- **Data source:** nginx access logs on the proxy host (`/var/log/nginx/access.log`), which record every request with its upstream status code. The proxy is the measurement point because it sees what customers see, including failures caused by a dead upstream (502/504), not just failures the application reports about itself.
- **Calculation:** `(count of responses with status < 500) / (count of all responses)` per 5-minute bucket, aggregated over the window. Requests rejected as malformed (4xx) count as *successful* for availability purposes: the service answered correctly.
- **Measurement window:** computed per 5-minute bucket; SLO evaluated over rolling 30 days.

### SLI 2 — Latency

**Definition:** the proportion of successful requests answered within 300 ms, measured at the proxy.

- **Data source:** nginx `$request_time` field added to the access log format. This captures full request duration as the customer experiences it through the proxy, including upstream connect time.
- **Calculation:** `(count of 2xx/3xx responses with request_time <= 0.300s) / (count of all 2xx/3xx responses)` per 5-minute bucket. We use a threshold-proportion SLI rather than an average because a mean hides tail latency; a p-style threshold is directly measurable from logs without a metrics system.
- **Measurement window:** per 5-minute bucket; SLO evaluated over rolling 30 days.

### SLI 3 — Payment error rate

**Definition:** the proportion of payment-processing requests (POST endpoints under the payments path) that complete without a server-side error, i.e. status < 500 **and** no application-level `payment_failed` error in the response.

- **Data source:** two sources joined per request ID: nginx access logs for the status code, and the application's structured stdout log (captured by systemd's journal today, a log shipper in production) for application-level payment failures that still return HTTP 200. This is a specification of what we would build: the application already logs one JSON line per payment attempt; the pipeline would parse and count them.
- **Calculation:** `1 - (failed payment attempts / all payment attempts)` per 5-minute bucket.
- **Measurement window:** per 5-minute bucket; SLO evaluated over rolling 30 days.

## 2. Service Level Objectives (30-day rolling window)

| SLI | SLO target | Approximate error budget / 30 days |
|---|---|---|
| Availability | 99.9% of requests successful | ~43 minutes of full unavailability |
| Latency | 99.0% of successful requests ≤ 300 ms | ~7.2 hours of degraded (slow) service |
| Payment error rate | 99.5% of payment attempts succeed | ~250 failed payments per 50,000 attempts |

All three are **proposed targets (not yet measured against production traffic)**. The availability target of 99.9% (rather than 99.99%) is deliberate: with a single proxy host and no multi-region failover, promising more than three nines would be a promise the current architecture cannot keep.

## 3. Rollback thresholds (short-window, automated)

The SLO is a 30-day promise; the rollback trigger is a short-window tripwire. The threshold is intentionally far looser than the SLO target so that normal noise never triggers a rollback, but a genuinely broken release trips it within seconds — a release that fails 3 consecutive health checks is burning error budget hundreds of times faster than the SLO allows.

| SLI | Short-window rollback threshold | Relationship to the SLO target |
|---|---|---|
| Availability | 3 consecutive proxy health-check failures at a 5 s poll interval (≈15 s of confirmed unavailability) inside the 90 s post-switch confidence window | 15 s of downtime is ~0.6% of the 30-day error budget (43 min) consumed in one burst; sustaining it would exhaust the budget in ~29 hours, so an immediate rollback is cheaper than any investigation |
| Latency | Health-check round trip exceeding the 3 s curl timeout on 3 consecutive polls (a timeout is treated as a failure by the monitor) | A 3 s response is 10× the 300 ms SLO threshold; three in a row cannot be noise and would put the latency SLO's 99.0% target out of reach within hours if sustained |
| Payment error rate | ≥5% of payment attempts failing over any 60 s window after a switch (proposed; requires the log-parsing pipeline above — today the health check is the proxy for this) | 5% failure is 10× the 0.5% the SLO tolerates over a month; one hour at that rate would consume the entire 30-day payment error budget |

Current implementation status: the availability/latency tripwire is implemented and demonstrated (`post-deploy-monitor.sh`, rollback measured at 12 s fault-to-recovery). The payment-error tripwire is specified but not yet implemented.

## 4. What we do not commit to

- **Third-party payment gateway availability.** If the upstream mobile-money gateway is down, our service correctly reports the failure; those failures are excluded from our payment error rate because we cannot roll back our way out of someone else's outage.
- **Latency of requests over customer networks.** We measure from the proxy inward. Time spent on a customer's 2G connection between their kiosk and our edge is outside this SLO; committing to it would make the number unactionable.
- **Batch reconciliation jobs.** The nightly settlement job has no latency or availability promise in this document; it has a separate freshness expectation (complete by 06:00) that is deliberately not an SLO yet, because we have never measured its variance.
