#!/usr/bin/env python3
# =============================================================================
# theme.py — Render and install coordinated desktop palettes.
#
# Existing configs provide keybindings; glass styling and artwork add depth.
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
import shlex


ROOT = Path(__file__).resolve().parents[1]
PALETTES = json.loads((ROOT / "themes/palettes.json").read_text())
BASE = "#191724 #1f1d2e #26233a #6e6a86 #e0def4 #eb6f92 #f6c177 #ebbcba #31748f #9ccfd8 #c4a7e7".split()
FILES = {
    "config": "i3/config",
    "kitty.conf": "kitty/kitty.conf",
    "rofi/config.rasi": "rofi/config.rasi",
    "i3blocks/config": "i3blocks/config",
    "dunst/dunstrc": "dunst/dunstrc",
    "themes/glass/picom.conf": "picom/picom.conf",
}


def render(name, config_dir=None):
    config_dir = (config_dir or Path(os.environ.get("XDG_CONFIG_HOME") or Path.home() / ".config")).resolve()
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
    opacity = PALETTES[name]["opacity"]
    kitty = output["kitty/kitty.conf"]
    kitty += f"""
# Glass finish: background alpha only, full-opacity text.
font_family JetBrainsMono Nerd Font
cursor_shape beam
background_opacity {opacity}
window_padding_width 20 24
tab_bar_style separator
tab_separator "   "
tab_title_template "{{index}}  {{title}}"
active_tab_font_style bold
inactive_tab_font_style normal
# Adjust glass strength live; reset returns to this theme's opacity.
map ctrl+shift+alt+up set_background_opacity +0.05
map ctrl+shift+alt+down set_background_opacity -0.05
map ctrl+shift+alt+0 set_background_opacity default
"""
    output["kitty/kitty.conf"] = kitty
    i3 = output["i3/config"]
    i3 = i3.replace("gaps inner 10", "gaps inner 18").replace("gaps outer 4", "gaps outer 12")
    i3 = i3.replace("smart_gaps on", "smart_gaps off")
    i3 = i3.replace("default_border pixel 2", "default_border pixel 1")
    i3 = i3.replace("default_floating_border pixel 2", "default_floating_border pixel 1")
    i3 = i3.replace("background_opacity=0.45", f"background_opacity={opacity}")
    i3 = i3.replace("font pango:JetBrainsMono Nerd Font 14", "font pango:JetBrainsMono Nerd Font 11")
    i3 = i3.replace("background $rp_base", f"background {colors[0]}cc")
    compositor = shlex.quote(str(config_dir / "picom/picom.conf"))
    # Start once at login, not another compositor on every i3 restart.
    i3 = i3.replace("exec_always --no-startup-id picom", f"exec --no-startup-id picom --config {compositor}")
    output["i3/config"] = i3
    rofi = output["rofi/config.rasi"]
    rofi = rofi.replace("border:           2px", "border:           1px")
    rofi = rofi.replace("border-radius:    12px", "border-radius:    18px")
    rofi = rofi.replace("background-color: @base", f"background-color: {colors[0]}df")
    rofi = rofi.replace("mainbox { padding: 12px", "mainbox { padding: 22px")
    output["rofi/config.rasi"] = rofi
    output["dunst/dunstrc"] = output["dunst/dunstrc"].replace("transparency = 8", "transparency = 12").replace("corner_radius = 12", "corner_radius = 16")
    return output


def preview(destination):
    cards = []
    for name, palette in PALETTES.items():
        for relative, contents in render(name, destination / name).items():
            path = destination / name / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(contents)
        base, surface, overlay, muted, text, red, gold, rose, green, blue, accent = palette["colors"]
        swatches = "".join(f'<span style="background:{color}" title="{color}"></span>' for color in palette["colors"])
        cards.append(f'''<article style="--base:{base};--surface:{surface};--overlay:{overlay};--muted:{muted};--text:{text};--accent:{accent};--green:{green};--glass:{palette['opacity']}">
<header><strong>{name.upper()}</strong><span>01 &nbsp; 02 &nbsp; 03</span><span>Tue 08 Sep &nbsp; 14:32</span></header>
<div class="desktop"><div class="terminal"><div class="title">~/research — kitty</div><p><em>tem@workstation</em> ~/research</p><p>❯ git status --short<br><span style="color:{green}"> M analysis.py</span></p><p><span style="color:{blue}">def</span> explore(signal):<br>&nbsp; &nbsp; <span style="color:{blue}">return</span> signal.mean()</p><p>❯ <span style="background:{accent}">&nbsp;</span></p></div><div class="launcher"><small>APPLICATIONS</small><p class="selected">Kitty terminal</p><p>Firefox</p><p>Files</p></div></div>
<footer><div><small>0{len(cards) + 1} / GLASS STUDIES</small><h2>{name.title()}</h2><p>{html.escape(palette['description'])}</p></div><div><label>Background opacity <output>{palette['opacity']:.0%}</output><input aria-label="{name} background opacity" type="range" min="50" max="100" value="{palette['opacity'] * 100:.0f}" oninput="this.closest('article').style.setProperty('--glass',this.value/100);this.previousElementSibling.value=this.value+'%'"></label><div class="swatches">{swatches}</div><code>make theme THEME={name}</code></div></footer></article>''')
    css = (ROOT / "themes/glass/preview.css").read_text()
    page = f'''<!doctype html><html lang="en"><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Glass desktop studies</title><style>{css}</style>
<main><h1>A little atmosphere.</h1><p class="intro">Three glass desktops.
Original artwork, translucent surfaces, quiet typography. Drag the sliders to
explore opacity. These are illustrations; sliders do not edit your configs.</p>
<div class="grid">'''
    (destination / "index.html").write_text(page + "".join(cards) + "</div></main></html>")
    print(destination / "index.html")


def apply(name, config_dir, backup_root):
    rendered = {relative: text.encode() for relative, text in render(name, config_dir).items()}
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
        live.write_bytes(contents)
    print(f"Applied {name} to {config_dir}. Backup: {backup}")
    print("Log out and back into i3 to load the compositor and bar together.")
    print("For existing kitty windows: Ctrl+Shift+F5 reloads the config.")
    print("Glass strength: Ctrl+Shift+Alt+Up/Down; Ctrl+Shift+Alt+0 resets it.")


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
