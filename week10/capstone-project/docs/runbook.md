# Runbook

## Reproducing the system from a clean checkout

```bash
minikube start
minikube addons enable ingress   # only needed for the production kijani-ingress

# 1. Infrastructure: provision kijani-staging
cd terraform && terraform init && terraform apply -auto-approve && cd ..

# 2. Delivery: configure staging's kk-payments ConfigMap
cd ansible && ansible-galaxy collection install -r requirements.yml \
  && ansible-playbook -i inventory/hosts.ini playbook.yml && cd ..

# 3. Runtime: build the image into minikube's Docker daemon and deploy
eval $(minikube docker-env)
docker build -t kijani/kk-payments:v1.2.0 kk-payments-image/
kubectl apply -f k8s/kk-payments-deployment.yaml -f k8s/kk-payments-service.yaml -n kijani-staging
kubectl create secret generic kk-payments-secrets --from-literal=DB_PASSWORD=dev --from-literal=STRIPE_API_KEY=dev --from-literal=JWT_SECRET=dev -n kijani-staging
kubectl rollout status deployment/kk-payments -n kijani-staging

# 4. Intelligence: start the receipt chain watcher
cd serverless && npm install && cd ..
node scripts/run-local-chain.js staging

# 5. Fire it
kubectl port-forward -n kijani-staging svc/kk-payments 13001:3001 &
curl -X POST http://127.0.0.1:13001/pay -H 'Content-Type: application/json' \
  -d '{"items":[{"name":"Coffee","price":150,"quantity":2}]}'
# watch the run-local-chain.js terminal — kk-receipts, kk-processor, kk-notifier
# should each log a line for the same orderId within ~1 second.
```

## The integration seam that breaks first

`kk-payments` writes receipts to `/tmp/kijani-s3-local` (`S3_LOCAL_ROOT`),
and the serverless chain watches the same directory. **These are two
different filesystems if kk-payments is running as a Kubernetes Pod on
minikube's `docker` driver**, because minikube runs its own VM/container
with its own `/tmp`. The Deployment's `hostPath` volume
(`k8s/kk-payments-deployment.yaml`) mounts minikube's `/tmp/kijani-s3-local`,
not the laptop's. Two ways to bridge this for a local demo, in order of
preference:

1. **`minikube mount /tmp/kijani-s3-local:/tmp/kijani-s3-local`** in a
   separate terminal before deploying — this is the supported way to share
   a host path with the cluster and is what the smoke test and demo assume.
2. **Run kk-payments as a plain `node server.js` process** on the host
   (`RECEIPTS_BUCKET=kijani-payments-receipts-staging node kk-payments-image/server.js`)
   for a chain demo without minikube in the loop — the Kubernetes Deployment
   remains the artifact assessed for the runtime layer, this is only a
   fallback for showing the serverless integration.

This is the same class of failure project.md calls out for Track A (Ansible
ConfigMap name vs. Deployment manifest reference) and Track B (S3 bucket
name mismatch): the fix here is the same DRY principle — `RECEIPTS_BUCKET`
and `S3_LOCAL_ROOT` are defined once in `ansible/group_vars/staging.yml`
and read by both the rendered ConfigMap and this runbook's commands.

## Delete everything (integration test)

```bash
minikube delete
docker system prune -a -f
rm -rf /tmp/kijani-s3-local
minikube start
# then repeat "Reproducing the system from a clean checkout" above
```

If any step in that sequence fails or needs a command not written down
here, this runbook is incomplete — fix it before submission.

## Rollback

```bash
kubectl rollout undo deployment/kk-payments -n kijani-staging
kubectl rollout undo deployment/kk-payments -n kijani-project
kubectl rollout history deployment/kk-payments -n kijani-project
```

## Verifying the error-rate gate manually

```bash
./monitoring/check-kk-payments-error-rate.sh kijani-staging
cat monitoring/error-rate-summary.json
```
