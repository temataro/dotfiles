#!/usr/bin/env bash
# =============================================================================
# nccl-check.sh — Run the RoCE GPU collective probe on both Sparks.
# The worker's output is captured alongside the head's output; failures propagate.
# Copyright (c) 2026 Temesgen Ataro <ataro.temesgen@gmail.com>
# SPDX-License-Identifier: Apache-2.0
# =============================================================================
set -euo pipefail
cd "$(dirname "$0")"
source .env
probe_image="${NCCL_IMAGE:-glm53-spark:local}"
mkdir -p results
run_rank() {
    docker run --rm --gpus all --network host --ipc host --device /dev/infiniband \
        --ulimit memlock=-1:-1 --cap-add IPC_LOCK \
        -v "$PWD/nccl_probe.py:/probe.py:ro" --entrypoint python3 \
        -e "RANK=$1" -e WORLD_SIZE=2 -e "MASTER_ADDR=$HEAD_IP" -e MASTER_PORT=29531 \
        -e NCCL_NET=IB -e NCCL_IB_DISABLE=0 -e "NCCL_IB_HCA=$RDMA_HCA" \
        -e "NCCL_IB_GID_INDEX=$RDMA_GID" -e "NCCL_SOCKET_IFNAME=$FABRIC_IF" \
        -e NCCL_CUMEM_ENABLE=0 -e NCCL_DEBUG=INFO "$probe_image" /probe.py
}
if [[ "${1:-}" == rank ]]; then
    run_rank "${2:?rank required}"
else
    ssh "$WORKER_SSH" "cd '$WORKER_DIR' && NCCL_IMAGE='$probe_image' bash nccl-check.sh rank 1" >results/nccl-worker.log 2>&1 &
    worker_pid=$!
    trap 'kill "$worker_pid" 2>/dev/null || true' EXIT
    run_rank 0 2>&1 | tee results/nccl-head.log
    wait "$worker_pid"
    cat results/nccl-worker.log
    rg 'NCCL_PASS' results/nccl-head.log results/nccl-worker.log
    rg 'NET/IB|Using network IB' results/nccl-head.log results/nccl-worker.log
fi
