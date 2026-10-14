# Local analysis agents on DGX Spark

This directory contains a reproducible two-Spark GLM-5.3-Flash inference
deployment in `glm53-flash/`. It is intended for one DSP, log-analysis, and
visualization agent, with a total context budget of 262,144 tokens including
generated output. The inference service does not ingest logs or autonomously
operate an analysis project: oh-my-pi provides the agent and Python provides
continuous ingestion, DSP, storage, and plots.

## Model and precision

GLM-5.3-Flash has 320B total parameters and 18B active per token. BF16 and the
original FP8 weights cannot fit entirely in two 128 GB Sparks. This deployment
uses `nvidia/GLM-5.3-Flash-NVFP4` at revision
`da920bb0b9f4a06727223a349e55468e38352348`. Its selective NVFP4 quantization
retains attention at higher precision. Quantization can affect accuracy; we do
not claim numerical or behavioral equivalence to the original model.

The baseline uses FP8 KV, one active sequence, prefix caching, chunked prefill,
and a 4 GiB KV allocation per rank. The latter is a starting point from the
two-Spark recipe. Baseline startup reports a 615,641-token KV pool, above one
full native context; the long-context check also exercises actual retrieval.
Reasoning defaults to `max`.

Speculative decoding is initially disabled. Set `SPECULATION=dflash` in `.env`
and repeat `prepare`, `stop`, `start`, `wait`, and `check --bench` to compare
the speed profile. Both ranks must have the same setting. The draft checkpoint
is pinned at `bf582e4eacc1810f76656d1811693ff6c6737d2a`; the Dockerfile applies
the reference DFlash prefix-cache fix and runs its build-time self-check.
Compare code, log analysis, and long-context workloads before selecting it.

NVIDIA's MTP head differs in
quantization from its target and is incompatible with the reference GB10 MTP
path. DFlash2 adds a separate
draft model and requires correct rejection sampling and prefix-state handling.
No speculative speed or fidelity claims are made for this baseline.

## Files and architecture

| File | Role |
|---|---|
| `glm53-flash/Dockerfile` | Extends the pinned ARM64/SM121 image with a pinned sparse-indexer fix |
| `glm53-flash/cluster.sh` | Head-side prepare/start/stop/status/fabric/check commands |
| `glm53-flash/serve.sh` | Identical vLLM options on both ranks; worker runs headless |
| `glm53-flash/nccl-check.sh` and `nccl_probe.py` | Two-GPU RoCE collective correctness and latency |
| `glm53-flash/check.py` | Auth, generation, tool call, numerical analysis, optional context/stream checks |
| `glm53-flash/validate-weights.py` | Verifies shard presence and NVIDIA attention-exclusion metadata |
| `glm53-flash/.env.example` | Placeholder-only cluster configuration |

One vLLM rank runs on each Spark. Tensor-parallel collectives and rendezvous use
the dedicated QSFP/RoCE fabric; clients use the head's LAN API. Each node stores
its own weights and kernel caches. Docker host networking exposes distributed
ports on the nodes, so keep the fabric/private service ports off public networks.
The API listener binds to the head's configured LAN address and requires a
bearer token. `/health` is intentionally unauthenticated.
The API uses plain HTTP: the token and prompts are not encrypted in transit.
Use a trusted LAN, SSH tunnel, or TLS proxy; do not expose this port publicly.

Persistent Docker restart policies restart the ranks after reboot. A restart
policy is not a coordinated distributed supervisor: after a rank failure, use
`stop` then `start` on the head to restart both ranks together.

## Private configuration

Run cluster commands from the head Spark; `WORKER_DIR` gives the worker's
deployment path, which can differ when usernames differ. Copy `.env.example`
to `.env`, fill the node/interface values,
and place the token in `secrets/api-key` with mode 600; `.env` should also be 600
and `secrets/` mode 700. The actual deployment uses existing SSH trust from head
to worker. No private key is copied into the inference containers.

`.env`, `secrets/`, `generated/`, and `results/` are ignored by Git and excluded
from the Docker build context. Node addresses, usernames, credentials, generated
client files, and raw diagnostic logs must stay there. Logs can contain addresses
and prompts; publish only sanitized validation summaries. Git ignore rules do
not remove previously tracked secrets.

The image and model revisions are public reproducibility metadata, not secrets.
`prepare` sends configuration, secret, weights, and the built image from head to
worker over SSH. The worker needs no internet access. Both nodes need NVIDIA
Container Toolkit, compatible NVIDIA drivers, Docker, SSH, and RDMA devices;
the head additionally needs `rsync`.
`start` flushes disk caches on both nodes after syncing, using passwordless sudo,
to make unified memory available to the GPU allocator after large transfers.
It does not delete the downloaded weights or the persistent kernel caches.

The configured model/cache directories must be writable by the SSH user on
both nodes. If using `/srv/models`, create and assign only the specific new
model/cache subdirectories, rather than changing ownership of existing models.

## Build and operations

```bash
cd /your/deployment/glm53-flash
bash cluster.sh prepare
bash cluster.sh fabric
bash nccl-check.sh
bash cluster.sh start
bash cluster.sh wait
bash cluster.sh status
docker logs --tail 100 glm53-server
bash cluster.sh check
bash cluster.sh check --bench
bash cluster.sh check --long
bash cluster.sh stop
```

`prepare` downloads about 204.5 GB of checkpoint files and transfers them to the
worker. Downloads are resumable. First startup can take many minutes for kernel
compilation. `start` launches worker first, then head. Start assumes neither node
already has a `glm53-server` container; use `stop` before replacing it. Competing
inference services must be stopped to free unified memory before GLM starts.
The previous Qwen container is stopped, with its restart policy disabled;
its configuration and weights are retained. To roll back on the head, stop
both GLM ranks, then run `docker update --restart unless-stopped qwen38-server`
and `docker start qwen38-server`. Its old model alias is distinct from GLM's.

The pinned image's automatic V2 model runner failed its first full-model CUDA
profiling pass on this fleet with `operation not permitted`. The launcher
explicitly selects the legacy runner (`VLLM_USE_V2_MODEL_RUNNER=0`), which
completed startup. Compiler concurrency is limited to one job for memory margin.
First requests can compile additional shape-specific kernels even after
`/health` becomes ready. Baseline weight loading took about 12 minutes per node.

`status` checks both containers and the live API. `fabric` proves link/reachability
only. `nccl-check.sh` verifies real GPU reductions on both ranks, checks their
values, measures 1 MiB collective latency, and requires IB/RoCE log evidence.
`check.py` asserts exact proof of life, rejection of anonymous model access,
valid tool JSON, and a known mean/RMS/sample-rate calculation.
Tool checks include replaying the assistant call and consuming a tool result.
`--long` uses a
roughly 240k-token retrieval prompt and checks actual reported token counts;
it is not a comprehensive long-context reasoning evaluation. `--bench` measures
streaming TTFT and completion throughput, counting reasoning tokens too.
Results and raw NCCL logs stay in ignored `results/`.
These checks establish wiring and basic correctness, not reliable long-horizon
autonomy. Before leaving an agent unattended, replay representative logs with
known outcomes, test its DSP code, and constrain writable paths and tools.

## Sources and provenance

- [Z.ai GLM-5.3-Flash model and reasoning controls](https://huggingface.co/zai-org/GLM-5.3-Flash)
- [NVIDIA checkpoint, calibration, and evaluation](https://huggingface.co/nvidia/GLM-5.3-Flash-NVFP4)
- [Two-Spark runtime and GB10 corrections](https://github.com/tonyd2wild/GLM-5.3-Flash-NVFP4-DFlash2-2x-DGX-Spark/tree/d061f26ad3ec5c3c04f64aad7516dbe62a8aa6af)
- [NVIDIA two-Spark QSFP setup](https://build.nvidia.com/spark/connect-two-sparks/stacked-sparks)

The third-party runtime includes patched vLLM code; its dependency provenance is
documented above. This repository's Dockerfile intentionally does not pretend to
rebuild all those patches from upstream vLLM. Pinning the base digest and patch
commit makes the inherited runtime identifiable.

## Validation record

2026-10-14:

| Check | Result |
|---|---|
| Shell syntax and Python compilation | Pass |
| Private configuration/generated-profile ignore rules | Pass |
| QSFP negotiation and bidirectional reachability | 200 Gb/s, active RoCE, no packet loss in the short check |
| Two-rank NCCL numerical reduction | Pass on both ranks, including the final pinned GLM runtime |
| 1 MiB GPU all-reduce mean latency | Final GLM runtime: 0.953 ms on each rank; cached vLLM 0.21.0: 0.197/0.198 ms; 30 synchronized iterations |
| NCCL transport | `NET/IB` over RoCE; logs reported `GDR 0`, so this does not establish GPU-direct transfer |
| Standalone mHC numerical probe | Pass: no NaNs; largest relative difference 0.003165 versus the torch reference |
| GLM runtime/model preparation | Pass: image built/transferred; 33 weight shards and attention-exclusion metadata validated on each node |
| GLM API, generation, tool JSON/replay and numerical analysis | Pass; both ranks running with zero restarts after the legacy-runner workaround |
| GLM context and decode speed | 262,144 configured; large-context test stopped at user request; no completed throughput benchmark |

The reduction timing is a small collective latency measurement, not a saturated
200 Gb/s throughput measurement or a benchmark of GLM. Raw evidence stays in
ignored `results/` on the head. The runtime difference demonstrates why a
cached-image transport test alone is not a serving-performance benchmark.
