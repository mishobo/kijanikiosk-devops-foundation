# Week 8 — KijaniKiosk Production Deployment Pipeline

## Layout

- `bluegreen/` — switch cycle and automated rollback evidence, SLO document, post-incident review, board demo script, plus the operational `scripts/` and the `staging-setup/` used to recreate the staging server.
- `containers/` — `Dockerfile.production`, `.dockerignore`, Kubernetes manifests, and all container/registry/cluster evidence files.
- `comparison.md` — the board-facing comparison of the two approaches.
- `reflection.md` — answers to the four reflection questions.

## Note on the staging environment

The Week 4 AWS staging instances no longer existed when this project began (the
elastic IPs had been recycled to other tenants and the AWS session had
expired), so the staging server was recreated faithfully as a systemd-enabled
container: nginx proxy on port 80 with `/etc/nginx/kijanikiosk-active-env.conf`,
`kk-api-blue.service` (v1.3.0, port 3000), `kk-api-green.service` (v1.4.0,
port 3001), an artifact server on 8080, and `/opt/kijanikiosk` state files and
scripts. See `bluegreen/staging-setup/Dockerfile` for the exact recreation;
every command in the brief's reset sequence runs unchanged inside it. All
evidence in `bluegreen/` was captured live against this environment.

To reproduce (from `deployment-pipeline/`):

```bash
docker build -t kk-staging -f bluegreen/staging-setup/Dockerfile .
docker run -d --name kk-staging --privileged --cgroupns=host \
  -v /sys/fs/cgroup:/sys/fs/cgroup:rw -p 8090:80 kk-staging
docker exec -it kk-staging bash   # then run the reset from the brief
```

## Private registry and Minikube (integration challenge F)

The private registry is a `registry:2` container with htpasswd basic auth on
host port 5001. Minikube was started with
`--insecure-registry=host.minikube.internal:5001`, and the
`kijani-registry-credentials` ImagePullSecret was recreated immediately after
the restart, before applying any manifest. Credentials exist only in the local
Docker credential store and the cluster Secret — never in this repository.

## Version tag computation (Requirement 7)

```bash
VERSION=$(node -p "require('./package.json').version")
GITSHA=$(git rev-parse --short=7 HEAD)
TAG="$VERSION-$GITSHA"     # -> 0.1.0-2e3e50e
```

## Key measured numbers

| Measurement | Value | Evidence |
|---|---|---|
| Automated rollback, fault to recovery (T0→T2) | 12 s | `bluegreen/rollback-evidence.txt` |
| Kubernetes self-healing, Pod delete to replacement Running | 2 s | `containers/self-healing-rerun.txt` |
| Image size, single-stage baseline → production multi-stage | 193 MB → 90.1 MB | `containers/build-verification.txt` |
