#!/usr/bin/env bash
# =============================================================================
# omp.sh — Launch the lightweight GLM agent inside the shared Podman jail.
# Preserves the caller's project and translates OMP's --cwd to the repo mount.
# Copyright (c) 2026 Temesgen Ataro <ataro.temesgen@gmail.com>
# SPDX-License-Identifier: Apache-2.0
# =============================================================================
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export OMP_DGX_DIR="$root"
exec "$root/../../agent-jail/omp-sbx" "$PWD" "$@"
