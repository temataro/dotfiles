#!/usr/bin/env bash
#
# ─── claude-sandbox/build.sh ─────────────────────────────────────────────────
# One-time build (re-run after Dockerfile changes).
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Building claude-dev:latest ..."
podman build \
    -t claude-dev:latest \
    "$SCRIPT_DIR"

echo ""
echo "Image ready. Run:  claude-sbx [path/to/repo]"
