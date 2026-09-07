#!/usr/bin/env python3
# =============================================================================
# theme.py — Render and install coordinated desktop palettes.
#
# Existing configs remain the source of behavior. Only their palette changes.
# Copyright (c) 2026 Temesgen Ataro <ataro.temesgen@gmail.com>
# SPDX-License-Identifier: Apache-2.0
# =============================================================================

import argparse
from datetime import datetime
import html
import json
import os
from pathlib import Path
import re
import shutil


ROOT = Path(__file__).resolve().parents[1]
PALETTES = json.loads((ROOT / "themes/palettes.json").read_text())
BASE = "#191724 #1f1d2e #26233a #6e6a86 #e0def4 #eb6f92 #f6c177 #ebbcba #31748f #9ccfd8 #c4a7e7".split()
FILES = {
    "config": "i3/config",
    "kitty.conf": "kitty/kitty.conf",
    "rofi/config.rasi": "rofi/config.rasi",
    "i3blocks/config": "i3blocks/config",
    "dunst/dunstrc": "dunst/dunstrc",
}


def render(name):
    colors = PALETTES[name]["colors"]
    assert len(colors) == len(BASE)
    assert all(re.fullmatch(r"#[0-9a-f]{6}", color) for color in colors)
    replacements = dict(zip(BASE, colors))
    # Kitty's true-black background and extra selection shades share roles.
    replacements.update({"#000000": colors[0], "#21202e": colors[1],
                         "#403d52": colors[2], "#908caa": colors[3]})
    output = {}
    for source, destination in FILES.items():
        text = (ROOT / source).read_text()
        text = re.sub(r"#[0-9a-fA-F]{6}(?![0-9a-fA-F])",
                      lambda match: replacements.get(match[0].lower(), match[0]), text)
        marker = f"# Generated theme: {name}\n"
        if source.endswith(".rasi"):
            marker = f"/* Generated theme: {name} */\n"
        output[destination] = marker + text
    return output


def preview(destination):
    cards = []
    for name, palette in PALETTES.items():
        for relative, contents in render(name).items():
            path = destination / name / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(contents)
        base, surface, overlay, muted, text, red, gold, rose, green, blue, accent = palette["colors"]
        swatches = "".join(f'<span style="background:{color}" title="{color}"></span>' for color in palette["colors"])
        cards.append(f'''<article style="--base:{base};--surface:{surface};--overlay:{overlay};--muted:{muted};--text:{text};--accent:{accent};--green:{green}">
<header><strong>{name.upper()}</strong><span>01 &nbsp; 02 &nbsp; 03</span><span>Tue 08 Sep &nbsp; 14:32</span></header>
<div class="desktop"><div class="terminal"><div class="title">~/research — kitty</div><p><em>tem@workstation</em> ~/research</p><p>❯ git status --short<br><span style="color:{green}"> M analysis.py</span></p><p><span style="color:{blue}">def</span> explore(signal):<br>&nbsp; &nbsp; <span style="color:{blue}">return</span> signal.mean()</p><p>❯ <span style="background:{accent}">&nbsp;</span></p></div><div class="launcher"><small>APPLICATIONS</small><p class="selected">Kitty terminal</p><p>Firefox</p><p>Files</p></div></div>
<footer><h2>{name.title()}</h2><p>{html.escape(palette['description'])}</p><div class="swatches">{swatches}</div><code>make theme THEME={name}</code></footer></article>''')
    page = '''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Desktop palettes</title><style>
*{box-sizing:border-box}body{margin:0;padding:40px;background:#17191c;color:#e9e5df;font:15px system-ui}main{max-width:1400px;margin:auto}h1{font-size:38px;margin-bottom:8px}.intro{color:#aaa;margin-bottom:32px}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(360px,1fr));gap:24px}article{background:var(--base);color:var(--text);border:1px solid var(--overlay);border-radius:12px;overflow:hidden}header{display:flex;justify-content:space-between;gap:12px;padding:14px;background:var(--surface);font:11px monospace}header strong{color:var(--accent)}.desktop{padding:28px 18px;min-height:300px;position:relative}.terminal{border:2px solid var(--accent);padding:15px;font:12px/1.8 monospace;min-height:250px}.title,small{color:var(--muted)}em{font-style:normal;color:var(--green)}.launcher{position:absolute;right:12px;top:80px;background:var(--surface);border:2px solid var(--accent);padding:12px;width:145px;font-size:12px;border-radius:8px}.launcher p{padding:7px;margin:4px 0}.selected{background:var(--accent);color:var(--base)}footer{padding:20px;border-top:1px solid var(--overlay)}h2{margin:0}footer p{color:var(--muted);min-height:40px}.swatches{display:flex;margin:20px 0}.swatches span{height:24px;flex:1}code{font-size:12px}@media(max-width:450px){body{padding:16px}.grid{grid-template-columns:1fr}}
</style><main><h1>Three ways to settle in.</h1><p class="intro">Coordinated i3 + kitty + rofi + notifications. Illustrative previews; your existing fonts and layout remain in use.</p><div class="grid">'''
    (destination / "index.html").write_text(page + "".join(cards) + "</div></main></html>")
    print(destination / "index.html")


def apply(name, config_dir, backup_root):
    rendered = render(name)
    # Back up the entire affected set before writing any live config.
    backup = backup_root / datetime.now().strftime("%Y%m%d-%H%M%S-%f")
    backup.mkdir(parents=True)
    for relative in rendered:
        live = config_dir / relative
        if live.exists():
            saved = backup / relative
            saved.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(live, saved)
    for relative, contents in rendered.items():
        live = config_dir / relative
        live.parent.mkdir(parents=True, exist_ok=True)
        live.write_text(contents)
    print(f"Applied {name} to {config_dir}. Backup: {backup}")
    print("Reload i3 with Alt+Shift+c; reload kitty with Ctrl+Shift+F5.")
    print("Restart dunst and i3blocks when convenient to load their new colors.")


def main():
    parser = argparse.ArgumentParser(description="Preview and apply coordinated desktop themes.")
    parser.add_argument("action", choices=["list", "preview", "apply"])
    parser.add_argument("name", nargs="?", choices=PALETTES)
    parser.add_argument("--output", type=Path, default=ROOT / "build/themes")
    parser.add_argument("--config-dir", type=Path, default=Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config")))
    parser.add_argument("--backup-dir", type=Path, default=Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state")) / "dotfiles/theme-backups")
    args = parser.parse_args()
    if args.action == "list":
        for name, palette in PALETTES.items():
            print(f"{name:8} {palette['description']}")
    elif args.action == "preview":
        preview(args.output)
    else:
        if args.name is None:
            parser.error("apply requires a theme name")
        apply(args.name, args.config_dir, args.backup_dir)


if __name__ == "__main__":
    main()
