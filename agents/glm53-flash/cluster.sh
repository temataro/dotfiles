#!/usr/bin/env bash
# =============================================================================
# cluster.sh — Prepare, launch, inspect, and stop a two-Spark GLM server.
# Run from the head Spark. The worker needs only fabric SSH, not internet.
# Copyright (c) 2026 Temesgen Ataro <ataro.temesgen@gmail.com>
# SPDX-License-Identifier: Apache-2.0
# =============================================================================
set -euo pipefail
cd "$(dirname "$0")"
source .env
IMAGE=glm53-spark:local
NAME=glm53-server
MODEL=nvidia/GLM-5.3-Flash-NVFP4
REVISION=da920bb0b9f4a06727223a349e55468e38352348

case "${1:-status}" in
prepare)
    test -s secrets/api-key
    mkdir -p "$MODEL_DIR" "$CACHE_DIR"
    docker build -t "$IMAGE" .
    docker run --rm --entrypoint hf -v "$MODEL_DIR:/model" "$IMAGE" \
        download "$MODEL" --revision "$REVISION" --local-dir /model
    python3 validate-weights.py "$MODEL_DIR"
    ssh "$WORKER_SSH" mkdir -p "$WORKER_DIR" "$MODEL_DIR" "$CACHE_DIR"
    rsync -a --exclude results --exclude generated --exclude __pycache__ ./ "$WORKER_SSH:$WORKER_DIR/"
    rsync -a --exclude .cache "$MODEL_DIR/" "$WORKER_SSH:$MODEL_DIR/"
    ssh "$WORKER_SSH" "python3 '$WORKER_DIR/validate-weights.py' '$MODEL_DIR'"
    if [[ "${SPECULATION:-none}" == dflash ]]; then
        mkdir -p "$DRAFT_DIR"
        docker run --rm --entrypoint hf -v "$DRAFT_DIR:/draft" "$IMAGE" \
            download incoai/GLM-5.3-Flash-DFlash2 --revision bf582e4eacc1810f76656d1811693ff6c6737d2a --local-dir /draft
        ssh "$WORKER_SSH" mkdir -p "$DRAFT_DIR"
        rsync -a --exclude .cache "$DRAFT_DIR/" "$WORKER_SSH:$DRAFT_DIR/"
    fi
    docker save "$IMAGE" | ssh "$WORKER_SSH" docker load
    ;;
start)
    sync
    sudo -n sysctl -w vm.drop_caches=3
    ssh "$WORKER_SSH" 'sync; sudo -n sysctl -w vm.drop_caches=3'
    ssh "$WORKER_SSH" "cd '$WORKER_DIR' && bash cluster.sh node 1"
    bash cluster.sh node 0
    ;;
node)
    rank="${2:?node rank required}"
    [[ "$rank" == 0 || "$rank" == 1 ]]
    test -s "$MODEL_DIR/config.json"
    python3 validate-weights.py "$MODEL_DIR"
    test -s secrets/api-key
    host_ip="$HEAD_IP"
    [[ "$rank" == 0 ]] || host_ip="$WORKER_IP"
    mkdir -p "$CACHE_DIR/flashinfer" "$CACHE_DIR/triton" "$CACHE_DIR/tilelang"
    draft_mount=()
    if [[ "${SPECULATION:-none}" == dflash ]]; then
        test -s "$DRAFT_DIR/config.json"
        draft_mount=(-v "$DRAFT_DIR:/models/draft:ro")
    else
        [[ "${SPECULATION:-none}" == none ]]
    fi
    docker run -d --gpus all --name "$NAME" --restart unless-stopped \
        --network host --ipc host --memory 112g --memory-swap 112g \
        --ulimit memlock=-1:-1 --cap-add IPC_LOCK --device /dev/infiniband \
        -v "$MODEL_DIR:/models/glm53:ro" -v "$CACHE_DIR:/cache" \
        -v "$CACHE_DIR/flashinfer:/root/.cache/flashinfer" \
        -v "$PWD/secrets/api-key:/run/secrets/api-key:ro" \
        "${draft_mount[@]}" -e "SPECULATION=${SPECULATION:-none}" \
        -e "NODE_RANK=$rank" -e "HEAD_IP=$HEAD_IP" -e "API_HOST=$API_HOST" \
        -e "PORT=$PORT" -e "MASTER_PORT=$MASTER_PORT" -e "VLLM_HOST_IP=$host_ip" \
        -e HF_HUB_OFFLINE=1 -e TRANSFORMERS_OFFLINE=1 -e HF_HOME=/cache/huggingface \
        -e VLLM_ENGINE_READY_TIMEOUT_S=3600 -e MAX_JOBS=1 -e FLASHINFER_NVCC_THREADS=1 \
        -e VLLM_USE_V2_MODEL_RUNNER=0 -e CUDA_LOG_FILE=stderr \
        -e TILELANG_CACHE_DIR=/cache/tilelang -e TRITON_CACHE_DIR=/cache/triton \
        -e PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True \
        -e TORCH_CUDA_ARCH_LIST=12.1a -e FLASHINFER_CUDA_ARCH_LIST=12.1a \
        -e FLASHINFER_DISABLE_VERSION_CHECK=1 \
        -e NCCL_NET=IB -e NCCL_IB_DISABLE=0 -e "NCCL_IB_HCA=$RDMA_HCA" \
        -e "NCCL_IB_GID_INDEX=$RDMA_GID" -e NCCL_IB_ROCE_VERSION_NUM=2 \
        -e NCCL_IB_ADDR_FAMILY=AF_INET -e "NCCL_IB_ADDR_RANGE=$FABRIC_CIDR" \
        -e "NCCL_SOCKET_IFNAME=$FABRIC_IF" -e "GLOO_SOCKET_IFNAME=$FABRIC_IF" \
        -e NCCL_NVLS_ENABLE=0 -e NCCL_CROSS_NIC=0 -e NCCL_IB_MERGE_NICS=0 \
        -e NCCL_CUMEM_ENABLE=0 -e NCCL_IGNORE_CPU_AFFINITY=1 -e NCCL_DEBUG=INFO \
        -e TORCH_NCCL_ASYNC_ERROR_HANDLING=1 "$IMAGE"
    ;;
stop)
    ssh "$WORKER_SSH" "docker rm -f $NAME" || true
    docker rm -f "$NAME"
    ;;
status)
    docker ps -a --filter "name=^/$NAME$" --format '{{.Names}} {{.Status}}'
    ssh "$WORKER_SSH" "docker ps -a --filter 'name=^/$NAME$' --format '{{.Names}} {{.Status}}'"
    curl --fail --silent --show-error --max-time 5 "http://$API_HOST:$PORT/health"
    ;;
wait)
    export GLM_BASE_URL="http://$API_HOST:$PORT/v1"
    export GLM_API_KEY_FILE="$PWD/secrets/api-key"
    for ((attempt=0; attempt<360; attempt++)); do
        if curl --fail --silent --max-time 5 "http://$API_HOST:$PORT/health" && python3 check.py --ready; then
            echo 'GLM API ready'
            exit 0
        fi
        running="$(docker inspect --format '{{.State.Running}}' "$NAME")"
        [[ "$running" == true ]] || { docker logs --tail 80 "$NAME"; exit 1; }
        sleep 10
    done
    echo 'Startup timed out; inspect logs on both ranks.' >&2
    exit 1
    ;;
fabric)
    ip -br address show dev "$FABRIC_IF"
    ethtool "$FABRIC_IF" | sed -n '/Speed:/p; /Link detected:/p'
    rdma link
    ping -c 3 -W 2 "$WORKER_IP"
    ssh "$WORKER_SSH" "rdma link; ping -c 3 -W 2 '$HEAD_IP'"
    echo 'Physical checks only. Run nccl-check.sh for a real two-rank collective.'
    ;;
check)
    export GLM_BASE_URL="http://$API_HOST:$PORT/v1"
    export GLM_API_KEY_FILE="$PWD/secrets/api-key"
    python3 check.py "${@:2}"
    ;;
*) echo 'usage: cluster.sh {prepare|start|stop|status|wait|fabric|check}' >&2; exit 2 ;;
esac
