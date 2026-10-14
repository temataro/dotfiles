#!/usr/bin/env python3
# =============================================================================
# nccl_probe.py — Verify two-rank GPU reduction over the configured RoCE link.
# Checks numerical correctness and measures synchronized collective latency.
# Copyright (c) 2026 Temesgen Ataro <ataro.temesgen@gmail.com>
# SPDX-License-Identifier: Apache-2.0
# =============================================================================
import os
import time
from datetime import timedelta

import torch
import torch.distributed as dist

rank = int(os.environ["RANK"])
torch.cuda.set_device(0)
dist.init_process_group("nccl", timeout=timedelta(seconds=120))
x = torch.full((262144,), rank + 1.0, device="cuda")
dist.all_reduce(x)
torch.cuda.synchronize()
assert torch.all(x == 3).item(), "all-reduce returned incorrect values"
for _ in range(5):
    x.fill_(1)
    dist.all_reduce(x)
torch.cuda.synchronize()
started = time.monotonic()
for _ in range(30):
    x.fill_(1)
    dist.all_reduce(x)
torch.cuda.synchronize()
elapsed = time.monotonic() - started
assert torch.all(x == 2).item()
print(f"rank={rank} NCCL_PASS payload=1MiB mean_collective_ms={elapsed * 1000 / 30:.3f}", flush=True)
dist.destroy_process_group()
