#!/usr/bin/env bash
# provision.sh — build-time provisioning of the recreated staging server.
# Lays out /opt/kijanikiosk exactly as the Week 8 brief assumes:
# versioned artifacts, blue on v1.3.0, green on v1.4.0, nginx routed to blue.
set -euo pipefail

BASE=/opt/kijanikiosk
SRC=/opt/app-src

useradd --system --home-dir /nonexistent --shell /usr/sbin/nologin kijani

mkdir -p "$BASE/artifacts" "$BASE/releases/blue" "$BASE/releases/green"
chmod +x "$BASE/scripts/"*.sh

# Build the two versioned artifacts from the same source tree.
for v in v1.3.0 v1.4.0; do
  PKG=$(mktemp -d)
  mkdir -p "$PKG/dist"
  cp "$SRC/src/"*.js "$PKG/dist/"
  cp "$SRC/package.json" "$PKG/"
  echo "$v" > "$PKG/version.txt"
  tar -czf "$BASE/artifacts/kk-payments-$v.tar.gz" -C "$PKG" .
  rm -rf "$PKG"
done

# Install blue = v1.3.0 (port 3000), green = v1.4.0 (port 3001).
install_release() {
  local env="$1" version="$2" port="$3"
  local dir="$BASE/releases/$env/$version"
  mkdir -p "$dir"
  tar -xzf "$BASE/artifacts/kk-payments-$version.tar.gz" -C "$dir"
  ln -sfn "$dir" "$BASE/releases/$env/current"
  cat > "$BASE/releases/$env/env" <<EOF
PORT=$port
APP_VERSION=$version
DEPLOY_ENV=$env
EOF
}
install_release blue  v1.3.0 3000
install_release green v1.4.0 3001

chown -R kijani:kijani "$BASE/releases"

# nginx: disable the stock default site, route to blue initially.
rm -f /etc/nginx/sites-enabled/default
cat > /etc/nginx/kijanikiosk-active-env.conf <<'EOF'
# Active environment: kk-api-blue (port 3000)
# Written by provision.sh (initial state)
upstream kk_api_active {
    server 127.0.0.1:3000;  # kk-api-blue
}
EOF

echo blue  > "$BASE/.active-env"
echo green > "$BASE/.previous-env"

# Enable services for boot (offline enable: create the wants symlinks).
WANTS=/etc/systemd/system/multi-user.target.wants
mkdir -p "$WANTS"
ln -sf /etc/systemd/system/kk-api-blue.service  "$WANTS/kk-api-blue.service"
ln -sf /etc/systemd/system/kk-api-green.service "$WANTS/kk-api-green.service"
ln -sf /etc/systemd/system/kk-artifacts.service "$WANTS/kk-artifacts.service"
ln -sf /lib/systemd/system/nginx.service        "$WANTS/nginx.service"

echo "Provisioning complete."
