# =============================================================================
# Dockerfile — Pinned GB10 runtime for distributed GLM-5.3-Flash.
# Extends the community SM121 runtime with its pinned sparse-indexer fix.
# Copyright (c) 2026 Temesgen Ataro <ataro.temesgen@gmail.com>
# SPDX-License-Identifier: Apache-2.0
# =============================================================================
FROM ghcr.io/tonyd2wild/vllm-glm53-flash@sha256:4def0ef644cb2e9814136dcffd5e385e21bc594f48f3b292234051904abe85a6
ADD https://raw.githubusercontent.com/tonyd2wild/GLM-5.3-Flash-NVFP4-DFlash2-2x-DGX-Spark/d061f26ad3ec5c3c04f64aad7516dbe62a8aa6af/docker/sparse_attn_indexer_kpool_sm121.py /usr/local/lib/python3.12/dist-packages/vllm/model_executor/layers/sparse_attn_indexer_kpool.py
ADD https://raw.githubusercontent.com/tonyd2wild/GLM-5.3-Flash-NVFP4-DFlash2-2x-DGX-Spark/d061f26ad3ec5c3c04f64aad7516dbe62a8aa6af/docker/dflash2-overlay/patch_prefix_cache_draft_group.py /opt/glm53/patch-prefix.py
RUN python3 /opt/glm53/patch-prefix.py
COPY serve.sh /opt/glm53/serve.sh
ENTRYPOINT ["/bin/bash", "/opt/glm53/serve.sh"]
