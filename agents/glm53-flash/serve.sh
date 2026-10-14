#!/usr/bin/env bash
# =============================================================================
# serve.sh — Serve one native-context GLM session across two Sparks.
# Reads authentication from a mounted secret; both ranks share the same flags.
# Copyright (c) 2026 Temesgen Ataro <ataro.temesgen@gmail.com>
# SPDX-License-Identifier: Apache-2.0
# =============================================================================
set -euo pipefail
export VLLM_API_KEY="$(</run/secrets/api-key)"
args=(/models/glm53 --served-model-name glm-5.3-flash
    --host "$API_HOST" --port "$PORT"
    --tensor-parallel-size 2 --max-model-len 262144 --max-num-seqs 1
    --gpu-memory-utilization 0.85 --kv-cache-memory 4294967296
    --kv-cache-dtype fp8_e4m3 --block-size 2304 --moe-backend marlin
    --enforce-eager --max-num-batched-tokens 8192 --enable-chunked-prefill
    --enable-prefix-caching --language-model-only
    --tool-call-parser glm47 --enable-auto-tool-choice --reasoning-parser glm45
    --default-chat-template-kwargs '{"reasoning_effort":"max","clear_thinking":false}'
    --distributed-executor-backend mp --nnodes 2 --node-rank "$NODE_RANK"
    --master-addr "$HEAD_IP" --master-port "$MASTER_PORT")
[[ "$NODE_RANK" == 0 ]] || args+=(--headless)
if [[ "${SPECULATION:-none}" == dflash ]]; then
    args+=(--speculative-config '{"method":"dflash","model":"/models/draft","num_speculative_tokens":7}')
fi
# NVIDIA's MTP head has a different quantization from the target on this stack.
# Baseline uses no draft model; the optional dense DFlash drafter avoids this MTP issue.
exec vllm serve "${args[@]}"
