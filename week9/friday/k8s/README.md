# KijaniKiosk — kijani-project Kubernetes deployment

Two-service system (`kk-api` + `kk-payments`) deployed declaratively into the
`kijani-project` namespace. Every resource is created from a manifest in this
directory. All Services are ClusterIP; external access is through the Ingress
at host `kijani.local`.

## Quick start (clean cluster)

```bash
# 1. Namespace (every manifest also declares namespace: kijani-project)
kubectl create namespace kijani-project 2>/dev/null || true

# 2. Recreate the Secret (NOT committed — see below)
kubectl create secret generic kk-payments-secrets \
  --from-literal=DB_PASSWORD=<obtain-from-team> \
  --from-literal=STRIPE_API_KEY=<obtain-from-team> \
  --from-literal=JWT_SECRET=<obtain-from-team> \
  -n kijani-project

# 3. Build the kk-payments image into the cluster's Docker daemon
#    (minikube: run `eval $(minikube docker-env)` first)
docker build -t kijani/kk-payments:v1.1.0 ../kk-payments-image

# 4. Apply everything
kubectl apply -f k8s/
```

The system should be Running/Ready within five minutes.

## Secret recovery note

The `kk-payments-secrets` Secret is created **imperatively** and is
intentionally **not committed to git**. If the cluster is deleted and
recreated, it must be recreated manually.

| Field            | Purpose                                  |
| ---------------- | ---------------------------------------- |
| `DB_PASSWORD`    | Password for the kk-payments database    |
| `STRIPE_API_KEY` | Stripe API key for payment processing    |
| `JWT_SECRET`     | Signing secret for issued JWTs           |

**The real values must be obtained from the team before applying.**
See `kk-payments-secrets.yaml.example` for the structure. The kk-payments
Deployment consumes these via `envFrom.secretRef`.

## Files

| File                             | Purpose                                        |
| -------------------------------- | ---------------------------------------------- |
| `kk-payments-configmap.yaml`     | Non-secret config for kk-payments              |
| `kk-api-configmap.yaml`          | Non-secret config for kk-api                   |
| `kk-payments-secrets.yaml.example` | Secret structure documentation (no values)   |
| `kk-payments-deployment.yaml`    | kk-payments Deployment (3 replicas, probes)    |
| `kk-payments-service.yaml`       | kk-payments Service (ClusterIP:3001)           |
| `kk-api-deployment.yaml`         | kk-api Deployment (2 replicas, probes)         |
| `kk-api-service.yaml`            | kk-api Service (ClusterIP:8080 -> 80)          |
| `kijani-ingress.yaml`            | Ingress: `/api` and `/payments` on kijani.local |
