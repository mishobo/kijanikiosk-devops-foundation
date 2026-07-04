#!/usr/bin/env bash
# KijaniKiosk IaC pipeline: Terraform provisions, then Ansible configures.
#
# This project uses the cloud (AWS) path throughout Week 4, not Multipass -
# see environment-setup.md. IPs are always extracted from `terraform output`,
# never hardcoded, so re-running this script after servers are recreated
# (different IPs) still works without editing inventory.ini by hand.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TF_DIR="${SCRIPT_DIR}/terraform"
ANSIBLE_DIR="${SCRIPT_DIR}/ansible"

echo "=== Checking AWS credentials ==="
if ! aws sts get-caller-identity >/dev/null 2>&1; then
  echo "ERROR: no valid AWS credentials in this shell. Run 'aws login' and" \
       "'eval \"\$(aws configure export-credentials --format env)\"' first." >&2
  exit 1
fi

echo "=== Terraform: init + apply ==="
terraform -chdir="${TF_DIR}" init -input=false
terraform -chdir="${TF_DIR}" apply -auto-approve

echo "=== Extracting server IPs from Terraform outputs ==="
API_IP=$(terraform -chdir="${TF_DIR}" output -raw api_server_ip)
PAYMENTS_IP=$(terraform -chdir="${TF_DIR}" output -raw payments_server_ip)
LOGS_IP=$(terraform -chdir="${TF_DIR}" output -raw logs_server_ip)

echo "api-staging=${API_IP}  payments-staging=${PAYMENTS_IP}  logs-staging=${LOGS_IP}"

echo "=== Writing ansible/inventory.ini ==="
cat > "${ANSIBLE_DIR}/inventory.ini" <<EOF
[kijanikiosk]
api-staging      ansible_host=${API_IP}
payments-staging ansible_host=${PAYMENTS_IP}
logs-staging     ansible_host=${LOGS_IP}
EOF

echo "=== Waiting for SSH to come up ==="
for ip in "$API_IP" "$PAYMENTS_IP" "$LOGS_IP"; do
  for attempt in $(seq 1 15); do
    if ssh -i ~/.ssh/aws-moringa.pem -o StrictHostKeyChecking=no -o ConnectTimeout=5 \
         "ubuntu@${ip}" true 2>/dev/null; then
      break
    fi
    if [ "$attempt" -eq 15 ]; then
      echo "ERROR: SSH to ${ip} did not come up in time." >&2
      exit 1
    fi
    sleep 5
  done
done

echo "=== Ansible: configure all three servers ==="
# cd into ansible/ so the playbook's relative template paths (templates/*.j2)
# resolve correctly regardless of where pipeline.sh was invoked from.
(cd "${ANSIBLE_DIR}" && ansible-playbook -i inventory.ini kijanikiosk.yml)

echo "=== Pipeline complete ==="
