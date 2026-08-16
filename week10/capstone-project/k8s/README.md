# k8s manifests

`kk-payments-deployment.yaml` and `kk-payments-service.yaml` carry no
`namespace` field on purpose — the same file is applied to both
environments:

```bash
kubectl apply -f k8s/kk-payments-deployment.yaml -f k8s/kk-payments-service.yaml -n kijani-staging
kubectl apply -f k8s/kk-payments-deployment.yaml -f k8s/kk-payments-service.yaml -n kijani-project
```

Only the ConfigMap differs per environment:

| Namespace         | ConfigMap                            | Applied by                          |
|--------------------|---------------------------------------|--------------------------------------|
| `kijani-staging`   | `kk-payments-configmap-staging.yaml`  | `ansible/playbook.yml` (Jenkins CI)  |
| `kijani-project`   | `kk-payments-configmap.yaml`          | `kubectl apply` (this file, checked in) |

`kk-api-*.yaml` and `kijani-ingress.yaml` are production-only (Week 9
carry-forward) — staging is reached via `kubectl port-forward` per
`docs/runbook.md`, consistent with the macOS ingress limitation noted there.

`kk-payments-secrets.yaml.example` documents the Secret shape; the real
Secret is created imperatively per namespace and is never committed.
