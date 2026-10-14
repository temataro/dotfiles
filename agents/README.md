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
The 32,768-token client output limit includes reasoning and answer tokens.

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
| `glm53-flash/omp-models.example.yml` | Current oh-my-pi YAML provider schema |
| `glm53-flash/omp-config.example.yml` | Lightweight role/discovery settings with serial delegation |
| `glm53-flash/configure-omp.py` | Renders an ignored standalone OMP profile from private settings |
| `glm53-flash/omp.sh` | Launches that profile while preserving the caller's project directory |
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

## oh-my-pi

The configured `omp` and `omp-dgx` commands launch oh-my-pi inside the rootless
Podman jail, using the private generated GLM profile. Provider configuration is
YAML (`models.yml`), not the earlier Pi JSON setup. The template's `apiKey`
names `GLM_API_KEY`; the launcher loads its value inside the container from the
read-only token mount. No manual token export or provider login is needed.

The template preserves reasoning across tool calls (`clear_thinking: false`)
and explicitly replays OMP thinking as `reasoning_content`; the installed
provider converter was tested to retain that field. It requests maximum
reasoning. For ordinary standalone chat, Z.ai recommends
`clear_thinking: true`. The declared input is text; vision is disabled in this
deployment to preserve memory for analysis context.

Run `python3 configure-omp.py` inside `glm53-flash/` to regenerate the profile. It renders
ignored `generated/omp/models.yml` and `config.yml`, and prints the launch environment for
that standalone profile. It does not replace an existing OMP profile or embed
the token in YAML. `PI_CODING_AGENT_DIR` must be set in the actual agent process,
including inside a sandbox. The printed key command contains only its file
path, not its value. The jail sets the profile directory inside the container.
To check discovery there, run
`/path/to/agent-jail/omp-sbx /path/to/repo omp models find glm-5.3-flash`.

The shared image includes pinned OMP 18.10.4 and Bun 1.3.14. Launch the generated
profile with `omp-dgx` from your analysis repository, or `omp-dgx --cwd /path/to/repo`.
The equivalent repository launcher is `bash /path/to/agents/glm53-flash/omp.sh`.
Both now launch `agent-jail/omp-sbx`, not an unrestricted host agent. The
container reads the private token from a read-only mount and selects the
persistent generated profile. `--cwd` selects the mounted analysis repository.
Build `agent-jail:latest` with the updated Dockerfile before launching.

To reproduce the sandbox setup on another machine after filling private settings:

```bash
python3 /path/to/agents/glm53-flash/configure-omp.py
bash /path/to/agent-jail/build.sh
bash /path/to/agents/glm53-flash/omp.sh --cwd /path/to/analysis-repo
```

The generated profile links `AGENTS.md` directly to your `~/.claude/CLAUDE.md`
and discovers skills from `~/.claude/skills`. It does not commit or copy those
private contents. Nested skill roots are included explicitly because OMP's
directory scanner is not recursive. Use `OMP_CLAUDE_DIR` when your Claude root
is elsewhere. Rerun the generator after adding skills under a new nested root.
The profile opts out of foreign provider registries, Claude/OMP plugin discovery,
and managed/registry skill packages; the explicit skill paths still work.
It retains OMP's built-in tools, lazy tool-schema discovery, project instruction
discovery, and the full Claude user instruction text. That text and the skill
catalog have a context cost; full skill bodies load on demand.
Optional client cache-warming requests are disabled; server prefix caching
remains enabled. The profile allows 30 minutes to receive the first stream
event for long prefill or queued work, then detects five-minute inter-event
stalls. These are timeouts, not a limit on an actively streaming agent run.

Default, smol, slow, and plan roles all use the same local GLM with maximum
reasoning. Delegation starts with one concurrent task, one recursion level, and
no speculative subagent launches. This makes the initial profile predictable
without lowering model precision or reasoning effort. Project OMP settings can
override profile settings; inspect effective configuration when working in a
repository that already has `.omp/config.yml`.

Later, independent DSP analysis, visualization, and code-review agents can have
separate prompts/tool policies. `omp-dgx agents unpack --project` can export the
bundled agents into `.omp/agents` as a starting point; do this in the analysis
repository when ready to customize them. Increase `task.maxConcurrency` to permit parallel
agent workflows, use isolated worktrees for agents editing the same repository,
and define ownership for outputs. The current inference scheduler still allows
only one active generation, so their model calls queue; shell computation and
plotting can overlap. Raising agent concurrency does not itself increase model
decode throughput. Benchmark memory and latency before increasing server
`--max-num-seqs` above one or loading another model replica.

Inside an agent container, mount its OMP profile and provide the token through a
read-only secret file or the agent launch environment. Also mount the Claude
root read-only at the paths referenced by the instruction link and skill roots,
or regenerate the profile inside the container using `OMP_CLAUDE_DIR` to point
to its mounted Claude directory. Give the container LAN
egress to the head endpoint. Inference runs on the Sparks; numerical tools and
visualization run in the agent's analysis project/container.
This profile is not an OS sandbox. Use the agent-jail container and restricted
project mounts when running unattended or delegating work.
The configured launcher now does this automatically using rootless Podman:

```bash
/path/to/agent-jail/omp-sbx /path/to/analysis-repo
omp-dgx --cwd /path/to/analysis-repo
```

OMP's profile/session state is writable; the GLM token, Claude instructions,
and Claude skills are read-only. Claude account credentials are not mounted.
Absolute instruction links and skill paths remain valid inside the container.
The jail retains its existing SSH-agent forwarding and USB passthrough, so it
is not a network-isolated or hardware-isolated environment. Each new launch is
an ephemeral container; its project edits and session state persist on the host.

## Continuous DSP and logs

Keep raw logs in append-only files or a queryable store. Python consumes incoming
data and computes rolling statistics, spectra, and anomaly events. Trigger the
agent periodically or on meaningful events, supplying a bounded summary and
tools to query time windows. Save conclusions, plots, and ingestion checkpoints
outside the chat. This is the recommended integration pattern; an application
watch loop is not part of this inference deployment.

Context size is a ceiling, not a goal. Reusing an append-only conversation prefix
can improve cache reuse; filling every turn with new full logs defeats that.
The analysis agent should execute tested Python for exact calculations, rather
than relying on model arithmetic.

## Sources and provenance

- [Z.ai GLM-5.3-Flash model and reasoning controls](https://huggingface.co/zai-org/GLM-5.3-Flash)
- [NVIDIA checkpoint, calibration, and evaluation](https://huggingface.co/nvidia/GLM-5.3-Flash-NVFP4)
- [Two-Spark runtime and GB10 corrections](https://github.com/tonyd2wild/GLM-5.3-Flash-NVFP4-DFlash2-2x-DGX-Spark/tree/d061f26ad3ec5c3c04f64aad7516dbe62a8aa6af)
- [NVIDIA two-Spark QSFP setup](https://build.nvidia.com/spark/connect-two-sparks/stacked-sparks)
- [oh-my-pi model configuration](https://github.com/can1357/oh-my-pi/blob/main/docs/models.md)

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
| OMP 18.10.4 provider/schema discovery | Pass: local model, 262k context, low/high/max thinking |
| OMP task concurrency and Claude skill discovery | Pass: concurrency 1, all five skills discovered by the installed SDK with no warnings |
| OMP instruction preservation | Pass: SDK-discovered AGENTS.md content matches the original Claude instruction file |
| OMP live model execution | Pass: exact OMP_GLM_ALIVE response; actual Python DFT tool returned 1000 Hz with its assertion passing |
| OMP thinking replay | Pass: installed provider converter retains reasoning_content on tool calls |
| OMP Podman jail | Pass: rebuilt image, profile/model discovery, authenticated endpoint access, read-only Claude/token mounts and no other agent credentials |

The reduction timing is a small collective latency measurement, not a saturated
200 Gb/s throughput measurement or a benchmark of GLM. Raw evidence stays in
ignored `results/` on the head. The runtime difference demonstrates why a
cached-image transport test alone is not a serving-performance benchmark.
