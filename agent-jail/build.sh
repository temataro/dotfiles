#!/usr/bin/env bash
#
# ─── agent-jail/build.sh ─────────────────────────────────────────────────────
# One-time build (re-run after Dockerfile changes).
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Building agent-jail:latest ..."
podman build \
    -t agent-jail:latest \
    "$SCRIPT_DIR"

echo ""
echo "Image ready. Run:  claude-sbx / codex-sbx / opencode-sbx [path/to/repo]"
