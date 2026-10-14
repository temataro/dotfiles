# DGX Spark setup and health checks

This directory records the two-Spark hardware setup and diagnostic tools.
Model deployment and the sandboxed client are added in separate commits.

## Private configuration

Copy `glm53-flash/.env.example` to `glm53-flash/.env` and fill the
host, fabric, interface, and private directory values. Keep its mode at 600.
Place the API token in `secrets/api-key` with mode 600 and its directory at 700.
Addresses, usernames, credentials, generated profiles, and raw results are
ignored by Git. Do not commit diagnostic logs, which can include private data.

## Hardware and prerequisites

Both inspected hosts have a GB10 GPU, about 121 GiB usable unified memory,
NVIDIA driver 580.142, CUDA 13.0, Docker, NVIDIA Container Toolkit, and RDMA.
The dedicated QSFP connection negotiated 200 Gb/s. Existing head-to-worker
SSH trust is reused; no private SSH key is copied into containers.

Run physical checks on the head using the private configuration:

```bash
cd /your/deployment/glm53-flash
source .env
ip -br address show dev "$FABRIC_IF"
ethtool "$FABRIC_IF"
rdma link
ping -c 3 -W 2 "$WORKER_IP"
ssh "$WORKER_SSH" "rdma link; ping -c 3 -W 2 '$HEAD_IP'"
```

## Diagnostic tools

| File | Purpose |
|---|---|
| `nccl-check.sh` and `nccl_probe.py` | Real two-rank GPU reduction correctness, latency, and RoCE transport evidence |
| `validate-weights.py` | Check weight shards and NVIDIA attention-exclusion metadata |
| `check.py` | Authenticated readiness, native context, generation, tool JSON/replay, numerical correctness, optional context and speed checks |

The NCCL probe runs from the head. Set `NCCL_IMAGE` to an available ARM64
GPU image with PyTorch until the model deployment builds its default image.
The API checks run after deployment, using `GLM_BASE_URL` and
`GLM_API_KEY_FILE`. Raw evidence stays in ignored `results/`.

## Verified hardware checks

- QSFP/RoCE: 200 Gb/s and no packet loss in the short bidirectional check.
- Two-rank reduction: correct on both GPUs.
- Cached vLLM 0.21.0 / NCCL 2.28.9: 1 MiB all-reduce mean latency
  0.197 ms on head and 0.198 ms on worker over 30 synchronized iterations.
- Transport logs show `NET/IB` and `GDR 0`; this does not prove GPU-direct
  transfer or saturated 200 Gb/s throughput.

[NVIDIA two-Spark setup](https://build.nvidia.com/spark/connect-two-sparks/stacked-sparks)
