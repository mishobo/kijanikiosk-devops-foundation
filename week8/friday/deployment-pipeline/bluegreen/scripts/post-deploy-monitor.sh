#!/usr/bin/env bash
# post-deploy-monitor.sh — watch the live environment through the nginx proxy
# after a traffic switch, and trigger an automated rollback on repeated failure.
#
# Usage: sudo bash post-deploy-monitor.sh <confidence-window-seconds>
#
# Polls http://127.0.0.1:80/health every POLL_INTERVAL seconds. Three
# consecutive failures trigger rollback.sh with no human action. If the
# confidence window elapses with no failure streak, the deployment is
# declared stable.
set -uo pipefail

WINDOW="${1:-60}"
POLL_INTERVAL=5
FAIL_THRESHOLD=3
PROXY_URL="http://127.0.0.1:80/health"

ts() { date -u +%H:%M:%S; }

echo "[$(ts)] [MONITOR] Started. Confidence window: ${WINDOW}s, poll interval: ${POLL_INTERVAL}s, failure threshold: ${FAIL_THRESHOLD} consecutive"
echo "[$(ts)] [MONITOR] Watching ${PROXY_URL} (active env: $(cat /opt/kijanikiosk/.active-env 2>/dev/null || echo unknown))"

DEADLINE=$(( $(date +%s) + WINDOW ))
CONSECUTIVE_FAILS=0

while [ "$(date +%s)" -lt "$DEADLINE" ]; do
  if BODY="$(curl -fsS -m 3 "$PROXY_URL" 2>/dev/null)"; then
    CONSECUTIVE_FAILS=0
    echo "[$(ts)] [MONITOR OK] $BODY"
  else
    CONSECUTIVE_FAILS=$((CONSECUTIVE_FAILS + 1))
    echo "[$(ts)] [MONITOR WARN] health check failed (${CONSECUTIVE_FAILS}/${FAIL_THRESHOLD} consecutive)"
    if [ "$CONSECUTIVE_FAILS" -ge "$FAIL_THRESHOLD" ]; then
      echo "[$(ts)] [MONITOR FAIL] ROLLBACK TRIGGERED after ${FAIL_THRESHOLD} consecutive health check failures"
      bash /opt/kijanikiosk/scripts/rollback.sh
      # Confirm recovery through the proxy before exiting.
      for i in 1 2 3 4 5; do
        if BODY="$(curl -fsS -m 3 "$PROXY_URL" 2>/dev/null)"; then
          echo "[$(ts)] [MONITOR] ROLLBACK CONFIRMED: healthy through proxy: $BODY"
          exit 1
        fi
        sleep 1
      done
      echo "[$(ts)] [MONITOR] ROLLBACK FAILED: proxy still unhealthy after rollback" >&2
      exit 2
    fi
  fi
  sleep "$POLL_INTERVAL"
done

echo "[$(ts)] [MONITOR PASS] Confidence window of ${WINDOW}s completed with no failure streak. Deployment is stable."
exit 0
