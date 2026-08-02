# Staging server recreation for Week 8.
# The original AWS staging instances from Week 4 were destroyed (recycled
# elastic IPs, expired session), so this systemd-enabled container recreates
# the exact blue/green layout the project brief assumes:
#   - nginx proxy on :80 with /etc/nginx/kijanikiosk-active-env.conf
#   - kk-api-blue.service  on :3000 (v1.3.0)
#   - kk-api-green.service on :3001 (v1.4.0)
#   - artifact server on :8080 serving /opt/kijanikiosk/artifacts
#   - /opt/kijanikiosk/scripts/{deploy-app,switch-env,rollback,post-deploy-monitor}.sh
#
# Build (context = deployment-pipeline/):
#   docker build -t kk-staging -f bluegreen/staging-setup/Dockerfile .
# Run:
#   docker run -d --name kk-staging --privileged --cgroupns=host \
#     -v /sys/fs/cgroup:/sys/fs/cgroup:rw -p 8090:80 kk-staging
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      systemd systemd-sysv nginx nodejs curl python3 ca-certificates && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Application source used to build the v1.3.0 and v1.4.0 artifacts
COPY containers/src /opt/app-src/src
COPY containers/package.json /opt/app-src/package.json

# Operational scripts (the pipeline under test)
COPY bluegreen/scripts/ /opt/kijanikiosk/scripts/

# systemd units and nginx site
COPY bluegreen/staging-setup/units/ /etc/systemd/system/
COPY bluegreen/staging-setup/nginx-kijanikiosk.conf /etc/nginx/conf.d/kijanikiosk.conf

COPY bluegreen/staging-setup/provision.sh /opt/provision.sh
RUN bash /opt/provision.sh

CMD ["/lib/systemd/systemd"]
