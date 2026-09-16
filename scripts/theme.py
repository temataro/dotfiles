#!/usr/bin/env python3
# =============================================================================
# theme.py — Render and install coordinated desktop palettes.
#
# Existing configs provide keybindings; a finish adds either glass depth or a
# flat, compact minimal look on top of the selected palette.
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
}
# A finish is styling only: every palette works with every finish, and both
# finishes keep the same bindings, bar modules, wallpaper, and font sizes.
FINISHES = {
    "glass": {
        "description": "Translucent surfaces, picom blur, generous gaps",
        "picom": "themes/glass/picom.conf",
        "opaque": False,
    },
    "minimal": {
        "description": "No blur or added transparency, compact gaps, stock sizes",
        "picom": "themes/minimal/picom.conf",
        "opaque": True,
    },
}
# Glass stays the default so existing `make theme THEME=...` calls are unchanged.
DEFAULT_FINISH = "glass"


def sources(finish):
    """Source file -> installed destination; only the compositor differs."""
    return {**FILES, FINISHES[finish]["picom"]: "picom/picom.conf"}


def terminal_opacity(name, finish):
    """Terminal background alpha. The minimal finish is deliberately opaque."""
    return 1.0 if FINISHES[finish]["opaque"] else PALETTES[name]["opacity"]


def glass(output, colors, opacity, config_dir):
    """Translucent surfaces, blur, wide gaps, smaller bar type."""
    output["kitty/kitty.conf"] += f"""
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
    i3 = output["i3/config"]
    i3 = i3.replace("gaps inner 10", "gaps inner 18").replace("gaps outer 4", "gaps outer 12")
    i3 = i3.replace("smart_gaps on", "smart_gaps off")
    i3 = i3.replace("default_border pixel 2", "default_border pixel 1")
    i3 = i3.replace("default_floating_border pixel 2", "default_floating_border pixel 1")
    i3 = i3.replace("background_opacity=0.45", f"background_opacity={opacity}")
    i3 = i3.replace("font pango:JetBrainsMono Nerd Font 14", "font pango:JetBrainsMono Nerd Font 11")
    i3 = i3.replace("background $rp_base", f"background {colors[0]}cc")
    compositor = shlex.quote(str(config_dir / "picom/picom.conf"))
    # exec runs at login only; the baseline exec_always re-runs picom on every
    # i3 reload, where the second instance just exits. Neither form restarts a
    # compositor that is already running.
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


def minimal(output, config_dir):
    """Flat and compact: tight gaps, no transparency of ours, stock type sizes."""
    output["kitty/kitty.conf"] += """
# Minimal finish: opaque kitty background. Font, padding, and cursor stay as set.
background_opacity 1.0
"""
    i3 = output["i3/config"]
    i3 = i3.replace("gaps inner 10", "gaps inner 6").replace("gaps outer 4", "gaps outer 0")
    i3 = i3.replace("default_border pixel 2", "default_border pixel 1")
    i3 = i3.replace("default_floating_border pixel 2", "default_floating_border pixel 1")
    # The floating terminal keeps its binding; only its transparency is dropped.
    i3 = i3.replace("background_opacity=0.45", "background_opacity=1.0")
    compositor = shlex.quote(str(config_dir / "picom/picom.conf"))
    # Baseline exec_always is kept as-is: it re-runs picom on every i3 reload,
    # which is a no-op while one is running. An already-running picom keeps its
    # old config until it is restarted by hand.
    i3 = i3.replace("exec_always --no-startup-id picom", f"exec_always --no-startup-id picom --config {compositor}")
    output["i3/config"] = i3
    rofi = output["rofi/config.rasi"]
    rofi = rofi.replace("border:           2px", "border:           1px")
    rofi = rofi.replace("border-radius:    12px", "border-radius:    4px")
    output["rofi/config.rasi"] = rofi
    output["dunst/dunstrc"] = output["dunst/dunstrc"].replace("transparency = 8", "transparency = 0").replace("corner_radius = 12", "corner_radius = 4")
    return output


def render(name, config_dir=None, finish=DEFAULT_FINISH):
    assert finish in FINISHES, f"unknown finish {finish!r}, choose from {sorted(FINISHES)}"
    assert name in PALETTES, f"unknown theme {name!r}, choose from {sorted(PALETTES)}"
    config_dir = (config_dir or Path(os.environ.get("XDG_CONFIG_HOME") or Path.home() / ".config")).resolve()
    colors = PALETTES[name]["colors"]
    assert len(colors) == len(BASE)
    assert all(re.fullmatch(r"#[0-9a-f]{6}", color) for color in colors)
    replacements = dict(zip(BASE, colors))
    # Kitty's true-black background and extra selection shades share roles.
    replacements.update({"#000000": colors[0], "#21202e": colors[1],
                         "#403d52": colors[2], "#908caa": colors[3]})
    output = {}
    for source, destination in sources(finish).items():
        text = (ROOT / source).read_text()
        text = re.sub(r"#[0-9a-fA-F]{6}(?![0-9a-fA-F])",
                      lambda match: replacements.get(match[0].lower(), match[0]), text)
        marker = f"# Generated theme: {name} ({finish})\n"
        if source.endswith(".rasi"):
            marker = f"/* Generated theme: {name} ({finish}) */\n"
        output[destination] = marker + text
    if FINISHES[finish]["opaque"]:
        return minimal(output, config_dir)
    return glass(output, colors, terminal_opacity(name, finish), config_dir)


def card(index, name, palette, finish):
    """One gallery illustration of a palette rendered in a finish."""
    base, surface, overlay, muted, text, red, gold, rose, green, blue, accent = palette["colors"]
    opacity = terminal_opacity(name, finish)
    flat = FINISHES[finish]["opaque"]
    swatches = "".join(f'<span style="background:{color}" title="{color}"></span>' for color in palette["colors"])
    if flat:
        control = f'<label>Background opacity <output>{opacity:.0%}</output></label><p class="note">No blur, and no transparency from these configs. Apps that ask for their own alpha still get it.</p>'
    else:
        control = f'''<label>Background opacity <output>{opacity:.0%}</output><input aria-label="{name} {finish} background opacity" type="range" min="50" max="100" value="{opacity * 100:.0f}" oninput="this.closest('article').style.setProperty('--glass',this.value/100);this.previousElementSibling.value=this.value+'%'"></label>'''
    return f'''<article class="{'flat' if flat else 'glass'}" style="--base:{base};--surface:{surface};--overlay:{overlay};--muted:{muted};--text:{text};--accent:{accent};--green:{green};--glass:{opacity}">
<header><strong>{name.upper()}</strong><span class="finish">{finish.upper()} FINISH</span><span>01 &nbsp; 02 &nbsp; 03</span><span>Tue 08 Sep &nbsp; 14:32</span></header>
<div class="desktop"><div class="terminal"><div class="title">~/research — kitty</div><p><em>tem@workstation</em> ~/research</p><p>❯ git status --short<br><span style="color:{green}"> M analysis.py</span></p><p><span style="color:{blue}">def</span> explore(signal):<br>&nbsp; &nbsp; <span style="color:{blue}">return</span> signal.mean()</p><p>❯ <span style="background:{accent}">&nbsp;</span></p></div><div class="launcher"><small>APPLICATIONS</small><p class="selected">Kitty terminal</p><p>Firefox</p><p>Files</p></div></div>
<footer><div><small>{index:02d} / {html.escape(FINISHES[finish]['description'].upper())}</small><h2>{name.title()}</h2><p>{html.escape(palette['description'])}</p></div><div>{control}<div class="swatches">{swatches}</div><code>make theme THEME={name} FINISH={finish}</code></div></footer></article>'''


def preview(destination):
    cards = []
    for finish in FINISHES:
        for name, palette in PALETTES.items():
            target = destination / finish / name
            for relative, contents in render(name, target, finish).items():
                path = target / relative
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text(contents)
            cards.append(card(len(cards) + 1, name, palette, finish))
    finishes = "; ".join(f"<b>{finish}</b> — {html.escape(spec['description'].lower())}"
                         for finish, spec in FINISHES.items())
    css = (ROOT / "themes/preview.css").read_text()
    page = f'''<!doctype html><html lang="en"><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Desktop palette and finish studies</title><style>{css}</style>
<main><h1>A little atmosphere.</h1><p class="intro">{len(PALETTES)} palettes
&times; {len(FINISHES)} finishes = {len(cards)} desktops. {finishes}.
Glass cards carry an opacity slider; minimal cards are opaque by definition.
These are illustrations, not screenshots, and the sliders do not edit your
configs.</p>
<div class="grid">'''
    destination.mkdir(parents=True, exist_ok=True)
    (destination / "index.html").write_text(page + "".join(cards) + "</div></main></html>")
    print(destination / "index.html")


def apply(name, config_dir, backup_root, finish=DEFAULT_FINISH):
    rendered = {relative: text.encode() for relative, text in render(name, config_dir, finish).items()}
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
    print(f"Applied {name} ({finish}) to {config_dir}. Backup: {backup}")
    print("Log out and back into i3 to load the compositor and bar together.")
    print("A picom that is already running keeps its old config: restart it by")
    print("hand (pkill -u \"$(id -u)\" -x picom, then start it again) — reloading")
    print("i3 re-runs the command but the second instance just exits.")
    print("For existing kitty windows: Ctrl+Shift+F5 reloads the config.")
    if not FINISHES[finish]["opaque"]:
        print("Glass strength: Ctrl+Shift+Alt+Up/Down; Ctrl+Shift+Alt+0 resets it.")


def main():
    parser = argparse.ArgumentParser(description="Preview and apply coordinated desktop themes.")
    parser.add_argument("action", choices=["list", "preview", "apply"])
    parser.add_argument("name", nargs="?", choices=PALETTES)
    parser.add_argument("--finish", choices=FINISHES, default=DEFAULT_FINISH)
    parser.add_argument("--output", type=Path, default=ROOT / "build/themes")
    parser.add_argument("--config-dir", type=Path, default=Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config")))
    parser.add_argument("--backup-dir", type=Path, default=Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state")) / "dotfiles/theme-backups")
    args = parser.parse_args()
    if args.action == "list":
        for name, palette in PALETTES.items():
            print(f"palette  {name:8} {palette['description']}")
        for finish, spec in FINISHES.items():
            default = " (default)" if finish == DEFAULT_FINISH else ""
            print(f"finish   {finish:8} {spec['description']}{default}")
    elif args.action == "preview":
        preview(args.output)
    else:
        if args.name is None:
            parser.error("apply requires a theme name")
        apply(args.name, args.config_dir, args.backup_dir, args.finish)


if __name__ == "__main__":
    main()
