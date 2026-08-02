#!/usr/bin/env bash
# rollback.sh — switch traffic back to the previously active environment.
# Called automatically by post-deploy-monitor.sh; can also be run by hand.
set -euo pipefail

BASE_DIR=/opt/kijanikiosk
ts() { date -u +%H:%M:%S; }

TARGET="$(cat "$BASE_DIR/.previous-env" 2>/dev/null || true)"
if [ -z "$TARGET" ] || [ "$TARGET" = "unknown" ]; then
  echo "[$(ts)] [ROLLBACK] ABORT: no previous environment recorded in .previous-env" >&2
  exit 1
fi

echo "[$(ts)] [ROLLBACK] Rolling back to environment: $TARGET"
bash /opt/kijanikiosk/scripts/switch-env.sh "$TARGET"
echo "[$(ts)] [ROLLBACK] Complete: traffic restored to kk-api-$TARGET"
