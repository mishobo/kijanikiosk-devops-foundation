# Monitoring — kk-payments error rate (Option B)

This capstone uses **Option B** from the Track A requirements: a log-based
error rate calculation following the Week 7 SLO pattern, rather than Option
A (a running Prometheus instance) — this repo has no Prometheus install,
only kk-payments' existing structured logging, which Option B is designed
to use directly.

`error-rate.js` implements the same condition a Prometheus alerting rule
would express:

```yaml
# Equivalent Prometheus rule, for reference (not deployed in this repo):
# See prometheus.io/docs/prometheus/latest/configuration/alerting_rules
groups:
  - name: kk-payments
    rules:
      - alert: KkPaymentsHighErrorRate
        expr: |
          sum(rate(http_requests_total{service="kk-payments",status=~"5.."}[2m]))
            / sum(rate(http_requests_total{service="kk-payments"}[2m])) > 0.05
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "kk-payments error rate above 5% for 2 minutes"
```

## Run it

```bash
./monitoring/check-kk-payments-error-rate.sh kijani-project
# or, for staging:
./monitoring/check-kk-payments-error-rate.sh kijani-staging
```

Writes `monitoring/error-rate-summary.json` and exits `1` when the alert
condition is met. The Jenkinsfile's staging smoke-test stage runs this
against `kijani-staging` before offering the production approval gate.
