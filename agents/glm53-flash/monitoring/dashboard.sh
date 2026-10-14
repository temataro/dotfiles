#!/usr/bin/env bash
# =============================================================================
# dashboard.sh — Start and stop the local DGX serving dashboard.
# Grafana and Prometheus bind to loopback; SSH collection is read-only.
# Copyright (c) 2026 Temesgen Ataro <ataro.temesgen@gmail.com>
# SPDX-License-Identifier: Apache-2.0
# =============================================================================
set -euo pipefail
cd "$(dirname "$0")"

PROM_IMAGE=docker.io/prom/prometheus:v3.15.0
GRAFANA_IMAGE=docker.io/grafana/grafana:13.2.2
PROM_NAME=dgx-monitor-prometheus
GRAFANA_NAME=dgx-monitor-grafana
EXPORTER_NAME=dgx-monitor-exporter

exists() { podman container exists "$1"; }

start_container() {
    local name="$1"
    shift
    if exists "$name"; then
        podman start "$name" >/dev/null
    else
        "$@"
    fi
}

case "${1:-up}" in
up)
    test -s .env || { echo 'Copy .env.example to .env and set private cluster values.' >&2; exit 1; }
    source .env
    ssh_dir="${HOME:?}/.ssh"
    test -s "$ssh_dir/id_ed25519" && test -s "$ssh_dir/known_hosts"
    mkdir -p generated/prometheus-data generated/grafana-data
    podman build -t localhost/dgx-monitor-exporter:local -f Containerfile .
    start_container "$EXPORTER_NAME" podman run -d --name "$EXPORTER_NAME" --restart unless-stopped \
        --network host --userns keep-id --user "$(id -u):$(id -g)" \
        -e "HEAD_SSH=$HEAD_SSH" -e "WORKER_SSH=$WORKER_SSH" -e "API_HOST=$API_HOST" \
        -e "API_PORT=${API_PORT:-8000}" -e "FABRIC_IF=$FABRIC_IF" -e "RDMA_HCA=$RDMA_HCA" \
        -e "POLL_SECONDS=${POLL_SECONDS:-15}" \
        -v "$ssh_dir/id_ed25519:/run/ssh/id_ed25519:ro,Z" \
        -v "$ssh_dir/known_hosts:/run/ssh/known_hosts:ro,Z" localhost/dgx-monitor-exporter:local
    start_container "$PROM_NAME" podman run -d --name "$PROM_NAME" --restart unless-stopped \
        --network host --userns keep-id --user "$(id -u):$(id -g)" \
        -v "$PWD/prometheus.yml:/etc/prometheus/prometheus.yml:ro,Z" \
        -v "$PWD/generated/prometheus-data:/prometheus:Z" "$PROM_IMAGE" \
        --config.file=/etc/prometheus/prometheus.yml --storage.tsdb.path=/prometheus \
        --storage.tsdb.retention.time=14d --storage.tsdb.retention.size=2GB \
        --web.listen-address=127.0.0.1:9090
    start_container "$GRAFANA_NAME" podman run -d --name "$GRAFANA_NAME" --restart unless-stopped \
        --network host --userns keep-id --user "$(id -u):$(id -g)" \
        -e GF_SERVER_HTTP_ADDR=127.0.0.1 -e GF_SERVER_HTTP_PORT=3000 \
        -e GF_AUTH_ANONYMOUS_ENABLED=true -e GF_AUTH_ANONYMOUS_ORG_ROLE=Viewer \
        -e GF_AUTH_DISABLE_LOGIN_FORM=true -e GF_USERS_VIEWERS_CAN_EDIT=false \
        -v "$PWD/grafana/provisioning:/etc/grafana/provisioning:ro,Z" \
        -v "$PWD/grafana/dashboards:/etc/grafana/dashboards:ro,Z" \
        -v "$PWD/generated/grafana-data:/var/lib/grafana:Z" "$GRAFANA_IMAGE"
    printf 'Dashboard: http://127.0.0.1:3000/d/dgx-spark-serving/dgx-spark-serving\n'
    ;;
down)
    podman stop "$GRAFANA_NAME" "$PROM_NAME" "$EXPORTER_NAME" >/dev/null 2>&1 || true
    ;;
status)
    podman ps -a --format '{{.Names}} {{.Status}}' | rg "^($PROM_NAME|$GRAFANA_NAME|$EXPORTER_NAME) " || true
    curl -fsS --max-time 2 http://127.0.0.1:9108/health || true
    curl -fsS --max-time 2 http://127.0.0.1:9090/-/ready || true
    curl -fsS --max-time 2 http://127.0.0.1:3000/api/health || true
    ;;
*) echo 'usage: dashboard.sh {up|down|status}' >&2; exit 2 ;;
esac
