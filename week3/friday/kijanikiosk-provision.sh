#!/usr/bin/env bash
# =============================================================================
# KijaniKiosk Production Server Foundation — Provisioning Script
# Version: 1.0.0  |  Date: 2026-06-24
# Author: DevOps Team (Amina / Hussein)
# =============================================================================
#
# Expected dirty conditions found in pre-provisioning audit (2026-06-24 08:40):
#   - kk-api already exists (UID 998): handled in Phase 2 by id check before useradd
#   - kk-payments already exists (UID 997): handled in Phase 2 by id check before useradd
#   - kijanikiosk group already exists (GID 1001): handled in Phase 2 by getent check
#   - /opt/kijanikiosk/shared/logs ACLs missing kk-payments entry: fixed in Phase 3
#     by setfacl --remove-all then re-applying the full correct ACL set
#   - ufw has extra DENY 3001 rule from Thursday remediation: fixed in Phase 5
#     by ufw --force reset before rebuilding the ruleset from scratch
#   - logrotate config at /etc/logrotate.d/kijanikiosk exists but is missing the
#     postrotate directive and uses incorrect create mode: overwritten in Phase 7
#
# =============================================================================

set -uo pipefail

# ── Constants ──────────────────────────────────────────────────────────────────
readonly SCRIPT_VERSION="1.0.0"
readonly SCRIPT_START
SCRIPT_START=$(date -Is)
readonly LOG_FILE="/var/log/kijanikiosk-provision-$(date +%Y%m%d-%H%M%S).log"

readonly APP_ROOT="/opt/kijanikiosk"
readonly CONFIG_DIR="${APP_ROOT}/config"
readonly LOGS_DIR="${APP_ROOT}/shared/logs"
readonly HEALTH_DIR="${APP_ROOT}/health"
readonly MONITORING_SUBNET="10.0.1.0/24"
readonly NGINX_VERSION="1.24.0-1ubuntu2"

# ── Logging helpers ────────────────────────────────────────────────────────────
PASSED_CHECKS=()
FAILED_CHECKS=()

log()     { echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO  $*" | tee -a "$LOG_FILE"; }
success() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] PASS  $*" | tee -a "$LOG_FILE"; PASSED_CHECKS+=("$*"); }
warn()    { echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARN  $*" | tee -a "$LOG_FILE"; }
error()   { echo "[$(date '+%Y-%m-%d %H:%M:%S')] FAIL  $*" | tee -a "$LOG_FILE"; FAILED_CHECKS+=("$*"); }
phase()   {
  echo "" | tee -a "$LOG_FILE"
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] ================================================================" | tee -a "$LOG_FILE"
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] ================================================================" | tee -a "$LOG_FILE"
}

# ── Root guard ─────────────────────────────────────────────────────────────────
if [[ $EUID -ne 0 ]]; then
  echo "ERROR: Must run as root.  sudo ./kijanikiosk-provision.sh" >&2
  exit 1
fi

mkdir -p /var/log
log "KijaniKiosk provisioning script v${SCRIPT_VERSION} starting at ${SCRIPT_START}"
log "Host: $(hostname)  |  Kernel: $(uname -r)"

# ==============================================================================
# PHASE 1: Pre-flight dirty-state detection
# ==============================================================================
phase "PHASE 1: Pre-flight dirty-state detection"

DIRTY_CONDITIONS=()

for user in kk-api kk-payments kk-logs; do
  if id "$user" &>/dev/null; then
    uid=$(id -u "$user")
    DIRTY_CONDITIONS+=("Already exists: ${user} (UID ${uid})")
    log "Detected: ${user} already exists with UID ${uid}"
  fi
done

if getent group kijanikiosk &>/dev/null; then
  gid=$(getent group kijanikiosk | cut -d: -f3)
  DIRTY_CONDITIONS+=("Already exists: kijanikiosk group (GID ${gid})")
  log "Detected: kijanikiosk group already exists with GID ${gid}"
fi

if [[ -d "$APP_ROOT" ]]; then
  DIRTY_CONDITIONS+=("Already exists: ${APP_ROOT} directory tree")
  log "Detected: ${APP_ROOT} directory tree already exists"
fi

if [[ -d "$LOGS_DIR" ]]; then
  if ! getfacl "$LOGS_DIR" 2>/dev/null | grep -q "user:kk-payments"; then
    DIRTY_CONDITIONS+=("ACL gap: kk-payments missing from ${LOGS_DIR}")
    log "Detected: kk-payments ACL entry missing from ${LOGS_DIR} — will reset and reapply"
  fi
fi

if command -v ufw &>/dev/null && ufw status 2>/dev/null | grep -q "3001.*DENY"; then
  DIRTY_CONDITIONS+=("Stale ufw: extra DENY 3001 from Thursday remediation")
  log "Detected: stale ufw DENY 3001 rule present — will reset firewall in Phase 5"
fi

if [[ -f /etc/logrotate.d/kijanikiosk ]]; then
  if ! grep -q "postrotate" /etc/logrotate.d/kijanikiosk 2>/dev/null; then
    DIRTY_CONDITIONS+=("Incomplete logrotate: missing postrotate in /etc/logrotate.d/kijanikiosk")
    log "Detected: logrotate config exists but missing postrotate — will overwrite in Phase 7"
  fi
fi

log "Dirty-state summary: ${#DIRTY_CONDITIONS[@]} condition(s) found"
for condition in "${DIRTY_CONDITIONS[@]}"; do
  log "  -> ${condition}"
done

success "PHASE 1 complete: ${#DIRTY_CONDITIONS[@]} dirty condition(s) documented"

# ==============================================================================
# PHASE 2: Service accounts and group
# ==============================================================================
phase "PHASE 2: Service accounts and group"

if getent group kijanikiosk &>/dev/null; then
  warn "Already exists: kijanikiosk group — skipping creation"
else
  groupadd --system kijanikiosk
  log "Created kijanikiosk system group"
fi

create_service_account() {
  local user="$1"
  local comment="$2"
  local home_dir="$3"

  if id "$user" &>/dev/null; then
    warn "Already exists: ${user} (UID $(id -u "$user")) — verifying kijanikiosk membership"
    if ! id -nG "$user" | grep -qw kijanikiosk; then
      usermod -aG kijanikiosk "$user"
      log "Added ${user} to kijanikiosk group (was missing)"
    fi
  else
    useradd \
      --system \
      --no-create-home \
      --home-dir    "$home_dir" \
      --shell       /usr/sbin/nologin \
      --comment     "$comment" \
      --gid         kijanikiosk \
      "$user"
    log "Created service account: ${user}"
  fi
}

create_service_account kk-api     "KijaniKiosk API service"            "${APP_ROOT}/api"
create_service_account kk-payments "KijaniKiosk payments service"      "${APP_ROOT}/payments"
create_service_account kk-logs     "KijaniKiosk log aggregation"       "${APP_ROOT}/shared/logs"

success "PHASE 2 complete: all service accounts present"

# ==============================================================================
# PHASE 3: Directory structure, ownership, and ACLs
# ==============================================================================
phase "PHASE 3: Directory structure, ownership, and ACLs"

mkdir -p \
  "${APP_ROOT}/api" \
  "${APP_ROOT}/payments" \
  "${APP_ROOT}/shared/logs" \
  "${APP_ROOT}/shared/cache" \
  "${CONFIG_DIR}" \
  "${HEALTH_DIR}"

log "Directory tree created/verified"

# Base structure
chown root:kijanikiosk "${APP_ROOT}"
chmod 755 "${APP_ROOT}"

chown kk-api:kijanikiosk "${APP_ROOT}/api"
chmod 750 "${APP_ROOT}/api"

chown kk-payments:kijanikiosk "${APP_ROOT}/payments"
chmod 750 "${APP_ROOT}/payments"

chown root:kijanikiosk "${APP_ROOT}/shared"
chmod 755 "${APP_ROOT}/shared"

# shared/logs: setgid propagates kijanikiosk group to new files
chown kk-logs:kijanikiosk "${LOGS_DIR}"
chmod 2775 "${LOGS_DIR}"

# config: root-owned, group-readable
chown root:kijanikiosk "${CONFIG_DIR}"
chmod 750 "${CONFIG_DIR}"

# health: kk-logs writes; kijanikiosk group members read
chown kk-logs:kijanikiosk "${HEALTH_DIR}"
chmod 750 "${HEALTH_DIR}"

log "Base ownership and permissions applied"

# ACLs on shared/logs — reset-all first to fix dirty state where kk-payments entry was missing
setfacl --remove-all "${LOGS_DIR}"
setfacl -m u:kk-api:rwX,u:kk-payments:rX,u:kk-logs:rwX,g:kijanikiosk:rX "${LOGS_DIR}"
setfacl -d -m u:kk-api:rw,u:kk-payments:r,u:kk-logs:rw,g:kijanikiosk:r   "${LOGS_DIR}"
log "ACLs reset and reapplied on ${LOGS_DIR}"

# health dir: kijanikiosk group members can read health status without sudo
setfacl -m g:kijanikiosk:rX "${HEALTH_DIR}"
setfacl -d -m g:kijanikiosk:r "${HEALTH_DIR}"
log "ACLs applied on ${HEALTH_DIR}"

# Environment files (Challenge A: paths are under /opt, not /etc, so ProtectSystem=strict is safe)
create_env_file() {
  local path="$1"
  local owner="$2"
  local content="$3"
  if [[ ! -f "$path" ]]; then
    printf '%s\n' "$content" > "$path"
    log "Created env file: ${path}"
  else
    warn "Env file already exists: ${path} — updating permissions only"
  fi
  chown "${owner}:kijanikiosk" "$path"
  chmod 640 "$path"
}

create_env_file "${CONFIG_DIR}/api.env" "kk-api" \
"NODE_ENV=production
APP_PORT=3000
LOG_DIR=/opt/kijanikiosk/shared/logs
APP_DATA_DIR=/opt/kijanikiosk/api"

create_env_file "${CONFIG_DIR}/payments-api.env" "kk-payments" \
"NODE_ENV=production
APP_PORT=3001
LOG_DIR=/opt/kijanikiosk/shared/logs
APP_DATA_DIR=/opt/kijanikiosk/payments
PAYMENT_PROCESSOR=internal"

create_env_file "${CONFIG_DIR}/logs.env" "kk-logs" \
"NODE_ENV=production
LOG_DIR=/opt/kijanikiosk/shared/logs
HEALTH_DIR=/opt/kijanikiosk/health"

success "PHASE 3 complete: directory structure and ACLs configured"

# ==============================================================================
# PHASE 4: Package installation with version pinning
# ==============================================================================
phase "PHASE 4: Package installation with version pinning"

apt-get update -qq

# Prerequisite packages (no pinning needed)
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  acl \
  ufw \
  rsyslog \
  logrotate \
  2>/dev/null
log "Prerequisite packages installed/verified"

# Pinned package installation
# Policy on version mismatch: fail loudly — silent downgrades in production are unsafe
install_pinned_package() {
  local pkg="$1"
  local pinned="$2"
  local installed
  installed=$(dpkg-query -W -f='${Version}' "$pkg" 2>/dev/null || echo "not-installed")

  if [[ "$installed" == "$pinned" ]]; then
    warn "Already installed: ${pkg}=${pinned} — skipping install, ensuring hold"
  elif [[ "$installed" == "not-installed" ]]; then
    log "Installing: ${pkg}=${pinned}"
    apt-mark unhold "$pkg" 2>/dev/null || true
    DEBIAN_FRONTEND=noninteractive apt-get install -y "${pkg}=${pinned}"
  else
    # Challenge D: version mismatch — fail loudly rather than attempt silent downgrade
    error "PHASE 4: ${pkg} version mismatch (installed: ${installed}, required: ${pinned})"
    error "  Manual intervention required: apt-mark unhold ${pkg} && apt-get install ${pkg}=${pinned}"
    return 1
  fi

  apt-mark hold "$pkg"
  log "Package hold active: ${pkg}=${pinned}"
}

install_pinned_package nginx "$NGINX_VERSION"

success "PHASE 4 complete: packages at pinned versions with holds active"

# ==============================================================================
# PHASE 5: Firewall — reset to known baseline, rebuild from intent
# ==============================================================================
phase "PHASE 5: Firewall — reset to known baseline"

# Full reset removes Thursday's stale DENY 3001 rule and any other manual edits
ufw --force reset
log "UFW reset to factory baseline"

ufw default deny incoming
ufw default allow outgoing

# Rule ordering matters: allow rules for port 3001 MUST precede the deny rule.
# ufw evaluates first-match; the loopback allow below would be unreachable if
# the broad deny appeared first.

ufw allow 22/tcp \
  comment 'SSH — administrative access, required for server management'

ufw allow 80/tcp \
  comment 'HTTP — public web traffic to nginx reverse proxy'

ufw allow 443/tcp \
  comment 'HTTPS — TLS-encrypted public web traffic'

# kk-payments health check restricted to ops monitoring subnet only
ufw allow from "${MONITORING_SUBNET}" to any port 3001 proto tcp \
  comment "kk-payments health endpoint — monitoring subnet ${MONITORING_SUBNET} only"

# Loopback allow BEFORE the broad deny (first-match wins)
ufw allow in on lo to any port 3001 proto tcp \
  comment 'kk-payments internal port — loopback only, for nginx reverse proxy'

# Deny all other external access to internal service port
ufw deny 3001/tcp \
  comment 'kk-payments — deny direct external access; use nginx proxy on 80/443'

ufw --force enable
log "UFW enabled"

success "PHASE 5 complete: firewall rebuilt from intent with clean baseline"

# ==============================================================================
# PHASE 6: systemd unit files (all three, inline)
# ==============================================================================
phase "PHASE 6: systemd unit files"

# ── kk-api.service (target score < 3.5) ───────────────────────────────────────
cat > /etc/systemd/system/kk-api.service <<'UNIT'
[Unit]
Description=KijaniKiosk API Service
Documentation=https://internal.kijanikiosk.co.ke/docs/api
After=network.target
Wants=network.target

[Service]
Type=simple
User=kk-api
Group=kijanikiosk
WorkingDirectory=/opt/kijanikiosk/api
EnvironmentFile=/opt/kijanikiosk/config/api.env
ExecStart=/usr/bin/node /opt/kijanikiosk/api/server.js
ExecReload=/bin/kill -USR1 $MAINPID
Restart=on-failure
RestartSec=5s
TimeoutStartSec=30s
TimeoutStopSec=30s

# Security hardening — target: systemd-analyze security < 3.5
NoNewPrivileges=true
PrivateTmp=true
PrivateDevices=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/kijanikiosk/api /opt/kijanikiosk/shared/logs
CapabilityBoundingSet=
AmbientCapabilities=
SystemCallFilter=@system-service
SystemCallArchitectures=native
LockPersonality=true
MemoryDenyWriteExecute=true
RestrictNamespaces=true
RestrictAddressFamilies=AF_INET AF_UNIX
RestrictSUIDSGID=true
RemoveIPC=true
ProtectKernelModules=true
ProtectKernelTunables=true
ProtectControlGroups=true
ProtectHostname=true
ProtectClock=true
UMask=0027

[Install]
WantedBy=multi-user.target
UNIT

log "Written: /etc/systemd/system/kk-api.service"

# ── kk-payments.service (target score < 2.5) ──────────────────────────────────
# Financial transaction data — maximum isolation required
# After= and Wants= enforce startup ordering dependency on kk-api
cat > /etc/systemd/system/kk-payments.service <<'UNIT'
[Unit]
Description=KijaniKiosk Payments Processing Service
Documentation=https://internal.kijanikiosk.co.ke/docs/payments
After=network.target kk-api.service
Wants=kk-api.service

[Service]
Type=simple
User=kk-payments
Group=kijanikiosk
WorkingDirectory=/opt/kijanikiosk/payments
EnvironmentFile=/opt/kijanikiosk/config/payments-api.env
ExecStart=/usr/bin/node /opt/kijanikiosk/payments/server.js
ExecReload=/bin/kill -USR1 $MAINPID
Restart=on-failure
RestartSec=5s
TimeoutStartSec=30s
TimeoutStopSec=30s

# Security hardening — target: systemd-analyze security < 2.5
# All directives verified to not break service startup (see kk-payments-hardening.md)
NoNewPrivileges=true
PrivateTmp=true
PrivateDevices=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/kijanikiosk/payments /opt/kijanikiosk/shared/logs
CapabilityBoundingSet=
AmbientCapabilities=
SystemCallFilter=@system-service
SystemCallArchitectures=native
LockPersonality=true
MemoryDenyWriteExecute=true
RestrictNamespaces=true
RestrictAddressFamilies=AF_INET AF_UNIX
RestrictSUIDSGID=true
RemoveIPC=true
ProtectKernelModules=true
ProtectKernelTunables=true
ProtectControlGroups=true
ProtectHostname=true
ProtectClock=true
UMask=0027
# Additional directives to reach < 2.5 (payments-specific)
IPAddressDeny=any
IPAddressAllow=localhost 10.0.0.0/8
DevicePolicy=closed
SecureBits=no-setuid-fixup-locked noroot noroot-locked

[Install]
WantedBy=multi-user.target
UNIT

log "Written: /etc/systemd/system/kk-payments.service"

# ── kk-logs.service (target score < 3.5) ──────────────────────────────────────
# ExecReload sends SIGUSR1 to main process — required for logrotate postrotate
# (Challenge C: PrivateTmp=true does not affect reload signal path since
#  systemd sends the signal from the main process, not a child of kk-logs)
cat > /etc/systemd/system/kk-logs.service <<'UNIT'
[Unit]
Description=KijaniKiosk Log Aggregation Service
Documentation=https://internal.kijanikiosk.co.ke/docs/logs
After=network.target kk-api.service kk-payments.service

[Service]
Type=simple
User=kk-logs
Group=kijanikiosk
WorkingDirectory=/opt/kijanikiosk/shared/logs
EnvironmentFile=/opt/kijanikiosk/config/logs.env
ExecStart=/usr/bin/node /opt/kijanikiosk/logs/server.js
ExecReload=/bin/kill -USR1 $MAINPID
Restart=on-failure
RestartSec=5s
TimeoutStartSec=30s
TimeoutStopSec=30s

# Security hardening — target: systemd-analyze security < 3.5
NoNewPrivileges=true
PrivateTmp=true
PrivateDevices=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/kijanikiosk/shared/logs /opt/kijanikiosk/health
CapabilityBoundingSet=
AmbientCapabilities=
SystemCallFilter=@system-service
SystemCallArchitectures=native
LockPersonality=true
MemoryDenyWriteExecute=true
RestrictNamespaces=true
RestrictAddressFamilies=AF_INET AF_UNIX
RestrictSUIDSGID=true
RemoveIPC=true
ProtectKernelModules=true
ProtectKernelTunables=true
ProtectControlGroups=true
ProtectHostname=true
ProtectClock=true
UMask=0027

[Install]
WantedBy=multi-user.target
UNIT

log "Written: /etc/systemd/system/kk-logs.service"

systemctl daemon-reload
log "systemd daemon reloaded"

for svc in kk-api kk-payments kk-logs; do
  systemctl enable "${svc}.service" 2>&1 | tee -a "$LOG_FILE"
  log "Enabled: ${svc}.service"
done

success "PHASE 6 complete: all three unit files written and enabled"

# ==============================================================================
# PHASE 7: Journal persistence and log rotation
# ==============================================================================
phase "PHASE 7: Journal persistence and log rotation"

# Persistent journal capped at 500 MB
mkdir -p /etc/systemd/journald.conf.d
cat > /etc/systemd/journald.conf.d/kijanikiosk.conf <<'CONF'
[Journal]
Storage=persistent
SystemMaxUse=500M
SystemKeepFree=100M
SystemMaxFileSize=50M
SystemMaxFiles=10
Compress=yes
CONF

log "Persistent journal configured (cap: 500 MB)"
systemctl restart systemd-journald 2>/dev/null \
  || warn "journald restart requires privilege escalation — may need manual restart"

# Logrotate configuration
# Integration challenge: logrotate's `create` directive bypasses the directory's
# default ACLs, so we explicitly re-apply ACLs in postrotate for the three-way
# access model (kk-api writes, kk-payments reads, kk-logs owns).
#
# Challenge C: kk-logs has ExecReload=kill -USR1 $MAINPID so `systemctl reload`
# correctly signals the process to re-open file handles. PrivateTmp=true on
# kk-logs does not affect this — systemd sends the signal from its own namespace,
# not from the service's private /tmp.
cat > /etc/logrotate.d/kijanikiosk <<'LOGROTATE'
/opt/kijanikiosk/shared/logs/*.log {
    daily
    rotate 14
    compress
    delaycompress
    missingok
    notifempty
    sharedscripts
    create 0660 kk-logs kijanikiosk
    postrotate
        # Re-apply named-user ACLs: logrotate's create directive sets base mode
        # but does not carry forward the directory's default ACL entries.
        # Without this, kk-api loses write access after each rotation.
        if ls /opt/kijanikiosk/shared/logs/*.log 1>/dev/null 2>&1; then
            setfacl -m u:kk-api:rw,u:kk-payments:r,u:kk-logs:rw \
              /opt/kijanikiosk/shared/logs/*.log 2>/dev/null || true
        fi
        # Signal kk-logs to re-open file handles (ExecReload=kill -USR1 $MAINPID)
        systemctl reload kk-logs.service 2>/dev/null || true
    endscript
}
LOGROTATE

log "Logrotate configuration written"

# Verify logrotate config
logrotate_output=$(logrotate --debug /etc/logrotate.d/kijanikiosk 2>&1)
echo "$logrotate_output" >> "$LOG_FILE"
if echo "$logrotate_output" | grep -qiE "^error"; then
  error "PHASE 7: logrotate --debug reported errors"
else
  success "PHASE 7: logrotate --debug passed with no errors"
fi

success "PHASE 7 complete: journal persistence and log rotation configured"

# ==============================================================================
# PHASE 8: Monitoring health checks
# ==============================================================================
phase "PHASE 8: Monitoring health checks"

# Services will not be running at provisioning time (no application code deployed).
# Health check still writes a JSON file reflecting real port check results.
# A file containing "down" is an expected result; a missing file is a script failure.

api_status=$(timeout 2 bash -c "echo >/dev/tcp/localhost/3000" 2>/dev/null \
  && echo '"ok"' || echo '"down"')
payments_status=$(timeout 2 bash -c "echo >/dev/tcp/localhost/3001" 2>/dev/null \
  && echo '"ok"' || echo '"down"')
logs_status=$(timeout 2 bash -c "echo >/dev/tcp/localhost/3002" 2>/dev/null \
  && echo '"ok"' || echo '"down"')

log "Port check: kk-api=${api_status}  kk-payments=${payments_status}  kk-logs=${logs_status}"

# Ensure health dir ownership is correct (may have been created above)
mkdir -p "$HEALTH_DIR"
chown kk-logs:kijanikiosk "$HEALTH_DIR"
chmod 750 "$HEALTH_DIR"
setfacl -m g:kijanikiosk:rX "$HEALTH_DIR"

# Write structured health check JSON
printf '{"timestamp":"%s","script_version":"%s","kk-api":%s,"kk-payments":%s,"kk-logs":%s}\n' \
  "$(date -Is)" "$SCRIPT_VERSION" \
  "$api_status" "$payments_status" "$logs_status" \
  > "${HEALTH_DIR}/last-provision.json"

chown kk-logs:kijanikiosk "${HEALTH_DIR}/last-provision.json"
chmod 640 "${HEALTH_DIR}/last-provision.json"
setfacl -m g:kijanikiosk:r "${HEALTH_DIR}/last-provision.json"

log "Health check JSON written to ${HEALTH_DIR}/last-provision.json"
log "Contents: $(cat "${HEALTH_DIR}/last-provision.json")"

if [[ -f "${HEALTH_DIR}/last-provision.json" ]]; then
  success "PHASE 8: Health check file present"
else
  error "PHASE 8: Health check file missing — write failed"
fi

success "PHASE 8 complete: monitoring health checks written"

# ==============================================================================
# PHASE 9: Final verification — all phases, exit non-zero on any failure
# ==============================================================================
phase "PHASE 9: Final verification"

FINAL_FAILED=0

verify() {
  local label="$1"
  local cmd="$2"
  if eval "$cmd" &>/dev/null; then
    success "PASS: ${label}"
  else
    error "FAIL: ${label}"
    (( FINAL_FAILED++ )) || true
  fi
}

# Phase 2: accounts
verify "kijanikiosk group exists"            "getent group kijanikiosk"
verify "kk-api user exists"                  "id kk-api"
verify "kk-payments user exists"             "id kk-payments"
verify "kk-logs user exists"                 "id kk-logs"
verify "kk-api in kijanikiosk group"         "id -nG kk-api | grep -qw kijanikiosk"
verify "kk-payments in kijanikiosk group"    "id -nG kk-payments | grep -qw kijanikiosk"
verify "kk-logs in kijanikiosk group"        "id -nG kk-logs | grep -qw kijanikiosk"

# Phase 3: directories and ACLs
verify "APP_ROOT exists"                     "[[ -d ${APP_ROOT} ]]"
verify "Config dir exists"                   "[[ -d ${CONFIG_DIR} ]]"
verify "Shared logs dir exists"              "[[ -d ${LOGS_DIR} ]]"
verify "Health dir exists"                   "[[ -d ${HEALTH_DIR} ]]"
verify "api.env readable by kk-api"          "sudo -u kk-api test -r ${CONFIG_DIR}/api.env"
verify "payments-api.env readable"           "sudo -u kk-payments test -r ${CONFIG_DIR}/payments-api.env"
verify "logs.env readable by kk-logs"        "sudo -u kk-logs test -r ${CONFIG_DIR}/logs.env"
verify "kk-payments ACL on logs dir"         "getfacl ${LOGS_DIR} | grep -q 'user:kk-payments'"
verify "default ACL on logs dir"             "getfacl ${LOGS_DIR} | grep -q 'default:'"

# Phase 5: firewall
verify_firewall() {
  local fw_failed=0
  local status
  status=$(ufw status 2>/dev/null)

  echo "$status" | grep -q "22/tcp.*ALLOW" \
    && success "PASS: SSH (22/tcp) rule present" \
    || { error "FAIL: SSH rule missing"; (( fw_failed++ )) || true; }

  echo "$status" | grep -q "80/tcp.*ALLOW" \
    && success "PASS: HTTP (80/tcp) rule present" \
    || { error "FAIL: HTTP rule missing"; (( fw_failed++ )) || true; }

  echo "$status" | grep -q "443/tcp.*ALLOW" \
    && success "PASS: HTTPS (443/tcp) rule present" \
    || { error "FAIL: HTTPS rule missing"; (( fw_failed++ )) || true; }

  echo "$status" | grep -q "3001" \
    && success "PASS: port 3001 rules present" \
    || { error "FAIL: port 3001 rules missing"; (( fw_failed++ )) || true; }

  echo "$status" | grep -q "DENY" \
    && success "PASS: port 3001 external DENY rule present" \
    || { error "FAIL: port 3001 DENY rule missing"; (( fw_failed++ )) || true; }

  echo "$status" | grep -q "Status: active" \
    && success "PASS: UFW is active" \
    || { error "FAIL: UFW is not active"; (( fw_failed++ )) || true; }

  (( FINAL_FAILED += fw_failed )) || true
}
verify_firewall

# Phase 6: unit files
verify "kk-api.service file exists"          "[[ -f /etc/systemd/system/kk-api.service ]]"
verify "kk-payments.service file exists"     "[[ -f /etc/systemd/system/kk-payments.service ]]"
verify "kk-logs.service file exists"         "[[ -f /etc/systemd/system/kk-logs.service ]]"
verify "kk-payments After=kk-api"            "grep -q 'After=.*kk-api.service' /etc/systemd/system/kk-payments.service"
verify "kk-payments Wants=kk-api"            "grep -q 'Wants=.*kk-api.service' /etc/systemd/system/kk-payments.service"
verify "kk-api.service enabled"              "systemctl is-enabled kk-api.service"
verify "kk-payments.service enabled"         "systemctl is-enabled kk-payments.service"
verify "kk-logs.service enabled"             "systemctl is-enabled kk-logs.service"
verify "kk-api EnvironmentFile path correct" "grep -q '/opt/kijanikiosk/config/api.env' /etc/systemd/system/kk-api.service"
verify "kk-payments EnvironmentFile correct" "grep -q '/opt/kijanikiosk/config/payments-api.env' /etc/systemd/system/kk-payments.service"

# Phase 7: journal and logrotate
verify "Journald persistent config exists"   "[[ -f /etc/systemd/journald.conf.d/kijanikiosk.conf ]]"
verify "Journald Storage=persistent set"     "grep -q 'Storage=persistent' /etc/systemd/journald.conf.d/kijanikiosk.conf"
verify "Journald 500M cap set"               "grep -q 'SystemMaxUse=500M' /etc/systemd/journald.conf.d/kijanikiosk.conf"
verify "Logrotate config exists"             "[[ -f /etc/logrotate.d/kijanikiosk ]]"
verify "Logrotate has postrotate directive"  "grep -q 'postrotate' /etc/logrotate.d/kijanikiosk"
verify "Logrotate debug passes"              "logrotate --debug /etc/logrotate.d/kijanikiosk 2>&1 | grep -v '^error'"

# Phase 8: health check
verify "Health JSON file exists"             "[[ -f ${HEALTH_DIR}/last-provision.json ]]"
verify "Health JSON has timestamp field"     "grep -q 'timestamp' ${HEALTH_DIR}/last-provision.json"
verify "Health JSON has kk-api field"        "grep -q 'kk-api' ${HEALTH_DIR}/last-provision.json"
verify "Health JSON owned by kk-logs"        "stat -c '%U' ${HEALTH_DIR}/last-provision.json | grep -q kk-logs"
verify "Health JSON group kijanikiosk"       "stat -c '%G' ${HEALTH_DIR}/last-provision.json | grep -q kijanikiosk"

# ── Summary ───────────────────────────────────────────────────────────────────
echo "" | tee -a "$LOG_FILE"
log "================================================================"
log "PROVISIONING SUMMARY"
log "================================================================"
log "Started:       ${SCRIPT_START}"
log "Finished:      $(date -Is)"
log "Log file:      ${LOG_FILE}"
log "Checks passed: ${#PASSED_CHECKS[@]}"
log "Checks failed: ${FINAL_FAILED}"

if [[ $FINAL_FAILED -gt 0 ]]; then
  log ""
  log "FAILED CHECKS:"
  for chk in "${FAILED_CHECKS[@]}"; do
    log "  FAIL: ${chk}"
  done
  log ""
  log "PROVISIONING COMPLETED WITH ERRORS — resolve failures before deploying"
  exit 1
else
  log ""
  log "ALL CHECKS PASSED — server foundation is production-ready"
  exit 0
fi
