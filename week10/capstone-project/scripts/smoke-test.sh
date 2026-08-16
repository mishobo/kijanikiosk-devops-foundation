#!/usr/bin/env bash
# Smoke test run by the Jenkins staging stage before the production approval
# gate is offered. Confirms kk-payments is healthy in the given namespace
# and that a /pay call successfully writes a receipt (the seam the
# serverless chain depends on).
#
# Usage: ./scripts/smoke-test.sh <namespace> <local-port>
set -euo pipefail

NAMESPACE="${1:-kijani-staging}"
LOCAL_PORT="${2:-13001}"

echo "== smoke test: $NAMESPACE =="

kubectl rollout status deployment/kk-payments -n "$NAMESPACE" --timeout=120s

kubectl port-forward -n "$NAMESPACE" svc/kk-payments "$LOCAL_PORT:3001" >/tmp/kk-payments-pf.log 2>&1 &
PF_PID=$!
trap 'kill $PF_PID 2>/dev/null || true' EXIT
sleep 3

HEALTH=$(curl -sf "http://127.0.0.1:$LOCAL_PORT/health")
echo "health: $HEALTH"
echo "$HEALTH" | grep -q '"status":"ok"' || { echo "FAIL: /health did not report ok"; exit 1; }

PAY_RESPONSE=$(curl -sf -X POST "http://127.0.0.1:$LOCAL_PORT/pay" \
  -H 'Content-Type: application/json' \
  -d '{"items":[{"name":"Smoke Test Item","price":50,"quantity":1}]}')
echo "pay: $PAY_RESPONSE"
echo "$PAY_RESPONSE" | grep -q '"orderId"' || { echo "FAIL: /pay did not return an orderId"; exit 1; }

RECEIPT_KEY=$(echo "$PAY_RESPONSE" | node -pe 'JSON.parse(require("fs").readFileSync(0,"utf8")).receipt.key')
RECEIPT_BUCKET=$(echo "$PAY_RESPONSE" | node -pe 'JSON.parse(require("fs").readFileSync(0,"utf8")).receipt.bucket')

if [ -f "/tmp/kijani-s3-local/$RECEIPT_BUCKET/$RECEIPT_KEY" ]; then
  echo "PASS: receipt found at /tmp/kijani-s3-local/$RECEIPT_BUCKET/$RECEIPT_KEY"
else
  echo "FAIL: receipt not found in local S3 mock (see docs/runbook.md if kk-payments runs inside minikube)"
  exit 1
fi

echo "== smoke test PASSED for $NAMESPACE =="
