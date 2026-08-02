#!/usr/bin/env bash
# switch-env.sh — switch nginx traffic between the blue and green environments.
# Usage: sudo bash switch-env.sh <blue|green>
set -euo pipefail

BASE_DIR=/opt/kijanikiosk
NGINX_ACTIVE_CONF=/etc/nginx/kijanikiosk-active-env.conf
TARGET="${1:-}"

ts() { date -u +%H:%M:%S; }
log() { echo "[$(ts)] $*"; }

case "$TARGET" in
  blue)  TARGET_PORT=3000 ;;
  green) TARGET_PORT=3001 ;;
  *) echo "Usage: $0 <blue|green>" >&2; exit 2 ;;
esac

CURRENT="$(cat "$BASE_DIR/.active-env" 2>/dev/null || echo unknown)"
log "SWITCH requested: $CURRENT -> $TARGET (port $TARGET_PORT)"

# 1. The target environment must be healthy on its own port before any traffic moves.
log "Pre-switch health check: kk-api-$TARGET on 127.0.0.1:$TARGET_PORT"
HEALTH_OK=0
for i in 1 2 3 4 5; do
  if BODY="$(curl -fsS -m 3 "http://127.0.0.1:$TARGET_PORT/health" 2>/dev/null)"; then
    log "kk-api-$TARGET healthy: $BODY"
    HEALTH_OK=1
    break
  fi
  log "attempt $i failed, retrying in 2s"
  sleep 2
done
if [ "$HEALTH_OK" -ne 1 ]; then
  log "ABORT: kk-api-$TARGET is not healthy; traffic remains on $CURRENT"
  exit 1
fi

# 2. Point nginx at the target upstream.
cat > "$NGINX_ACTIVE_CONF" <<EOF
# Active environment: kk-api-$TARGET (port $TARGET_PORT)
# Written by switch-env.sh at $(date -u +%Y-%m-%dT%H:%M:%SZ)
upstream kk_api_active {
    server 127.0.0.1:$TARGET_PORT;  # kk-api-$TARGET
}
EOF
log "nginx active-env config now references kk-api-$TARGET"

nginx -t 2>&1 | sed "s/^/[$(ts)] nginx: /"
systemctl reload nginx
log "nginx reloaded"

# 3. Verify the switch through the proxy itself.
sleep 1
PROXY_BODY="$(curl -fsS -m 3 http://127.0.0.1:80/health)"
log "Post-switch proxy check: $PROXY_BODY"

# 4. Record state only after the switch is verified.
echo "$CURRENT" > "$BASE_DIR/.previous-env"
echo "$TARGET"  > "$BASE_DIR/.active-env"
log "State files updated: active=$TARGET previous=$CURRENT"
log "SWITCH COMPLETE: traffic now served by kk-api-$TARGET"
