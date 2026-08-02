#!/usr/bin/env bash
# deploy-app.sh — deploy a versioned artifact into one environment (blue or green)
# without touching live traffic. Traffic only moves via switch-env.sh.
#
# Usage:
#   APP_VERSION=v1.4.0 DEPLOY_ENV=green ARTIFACT_BASE_URL=http://127.0.0.1:8080 \
#     sudo -E bash deploy-app.sh
set -euo pipefail

BASE_DIR=/opt/kijanikiosk
: "${APP_VERSION:?APP_VERSION is required (e.g. v1.4.0)}"
: "${DEPLOY_ENV:?DEPLOY_ENV is required (blue|green)}"
: "${ARTIFACT_BASE_URL:?ARTIFACT_BASE_URL is required}"

case "$DEPLOY_ENV" in
  blue)  PORT=3000 ;;
  green) PORT=3001 ;;
  *) echo "DEPLOY_ENV must be blue or green" >&2; exit 2 ;;
esac

ts() { date -u +%H:%M:%S; }
log() { echo "[$(ts)] $*"; }

RELEASE_DIR="$BASE_DIR/releases/$DEPLOY_ENV/$APP_VERSION"
ARTIFACT="kk-payments-$APP_VERSION.tar.gz"

log "DEPLOY $APP_VERSION -> $DEPLOY_ENV (port $PORT)"
mkdir -p "$RELEASE_DIR"

log "Fetching $ARTIFACT_BASE_URL/$ARTIFACT"
curl -fsS -m 30 -o "/tmp/$ARTIFACT" "$ARTIFACT_BASE_URL/$ARTIFACT"
tar -xzf "/tmp/$ARTIFACT" -C "$RELEASE_DIR"
rm -f "/tmp/$ARTIFACT"

ln -sfn "$RELEASE_DIR" "$BASE_DIR/releases/$DEPLOY_ENV/current"

cat > "$BASE_DIR/releases/$DEPLOY_ENV/env" <<EOF
PORT=$PORT
APP_VERSION=$APP_VERSION
DEPLOY_ENV=$DEPLOY_ENV
EOF

systemctl restart "kk-api-$DEPLOY_ENV.service"

log "Waiting for kk-api-$DEPLOY_ENV health on port $PORT"
for i in $(seq 1 10); do
  if BODY="$(curl -fsS -m 3 "http://127.0.0.1:$PORT/health" 2>/dev/null)"; then
    log "kk-api-$DEPLOY_ENV healthy: $BODY"
    log "DEPLOY COMPLETE: $APP_VERSION on $DEPLOY_ENV (no traffic moved)"
    exit 0
  fi
  sleep 2
done
log "DEPLOY FAILED: kk-api-$DEPLOY_ENV did not become healthy"
exit 1
