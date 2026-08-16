#!/usr/bin/env bash
# Pulls the last 5 minutes of kk-payments logs from the given namespace and
# runs them through error-rate.js. Exits non-zero (and the summary file's
# "alert": true) when the 2-minute error rate exceeds 5%.
#
# Usage: ./monitoring/check-kk-payments-error-rate.sh <namespace>
set -euo pipefail

NAMESPACE="${1:-kijani-project}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

kubectl logs deployment/kk-payments -n "$NAMESPACE" --since=5m --all-containers=true \
  | node "$SCRIPT_DIR/error-rate.js"
