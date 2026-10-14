#!/usr/bin/env python3
# =============================================================================
# validate-weights.py — Reject incomplete or unexpected GLM checkpoints.
# Checks shard presence, quantization metadata, and attention exclusions.
# Copyright (c) 2026 Temesgen Ataro <ataro.temesgen@gmail.com>
# SPDX-License-Identifier: Apache-2.0
# =============================================================================
import fnmatch
import json
import sys
from pathlib import Path

root = Path(sys.argv[1])
config = json.loads((root / "config.json").read_text())
index = json.loads((root / "model.safetensors.index.json").read_text())
shards = set(index["weight_map"].values())
assert shards and all((root / name).is_file() and (root / name).stat().st_size > 0 for name in shards), "missing/empty shards"
quant = config.get("quantization_config", {})
assert quant.get("quant_method") == "modelopt", "expected pinned NVIDIA ModelOpt checkpoint"
ignored = quant.get("ignore") or quant.get("exclude_modules") or []
layers = (config.get("text_config") or config)["num_hidden_layers"]
for layer in range(layers):
    attention = f"model.language_model.layers.{layer}.self_attn.__whole_block__"
    assert any(fnmatch.fnmatch(attention, pattern) for pattern in ignored), f"attention quantized in layer {layer}"
print(f"WEIGHTS_PASS shards={len(shards)} attention_layers_preserved={layers}")
# Presence checks do not prove shard integrity; pinned HF downloads verify blobs.
