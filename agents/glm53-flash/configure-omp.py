#!/usr/bin/env python3
# =============================================================================
# configure-omp.py — Render a private oh-my-pi provider from deployment settings.
# Produces a standalone profile without overwriting existing OMP providers.
# Copyright (c) 2026 Temesgen Ataro <ataro.temesgen@gmail.com>
# SPDX-License-Identifier: Apache-2.0
# =============================================================================
import os
import json
from pathlib import Path

root = Path(__file__).resolve().parent
settings = {}
for line in (root / ".env").read_text().splitlines():
    if line.strip() and not line.lstrip().startswith("#"):
        key, value = line.split("=", 1)
        settings[key] = value.strip().strip("\"'")
profile = root / "generated" / "omp"
profile.mkdir(parents=True, exist_ok=True)
os.chmod(profile, 0o700)
text = (root / "omp-models.example.yml").read_text()
text = text.replace("http://HEAD_LAN_ADDRESS:8000/v1", f'http://{settings["API_HOST"]}:{settings["PORT"]}/v1')
output = profile / "models.yml"
output.write_text(text)
os.chmod(output, 0o600)
claude = Path(os.environ.get("OMP_CLAUDE_DIR", str(Path.home() / ".claude")))
instructions = claude / "CLAUDE.md"
link = profile / "AGENTS.md"
if instructions.is_file():
    if link.is_symlink():
        link.unlink()
    assert not link.exists(), f"refusing to replace {link}"
    link.symlink_to(instructions.resolve())
skills = claude / "skills"
# OMP scans one directory level. Include each parent root to retain nested skills.
skill_roots = sorted({str(file.parent.parent.resolve()) for file in skills.rglob("SKILL.md")}) if skills.is_dir() else []
config = (root / "omp-config.example.yml").read_text()
config = config.replace("customDirectories: []", "customDirectories: " + json.dumps(skill_roots))
settings_file = profile / "config.yml"
settings_file.write_text(config)
os.chmod(settings_file, 0o600)
print(f"Claude instructions linked: {instructions.is_file()}; skill roots: {len(skill_roots)}")
print(f"Private OMP profile created: {profile}")
print(f'export PI_CODING_AGENT_DIR="{profile}"')
print(f'export GLM_API_KEY="$(<{root / "secrets" / "api-key"})"')
print("omp --model dgx-glm/glm-5.3-flash")
