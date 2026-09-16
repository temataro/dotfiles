# =============================================================================
# test_theme.py — Verify palette rendering and recoverable theme installation.
#
# Tests keep every temporary HOME, config, and cache inside build/ and never
# touch the desktop session.
# Copyright (c) 2026 Temesgen Ataro <ataro.temesgen@gmail.com>
# SPDX-License-Identifier: Apache-2.0
# =============================================================================

import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import unittest

from scripts import theme


SCRATCH = theme.ROOT / "build/test-scratch"
BASE_I3 = (theme.ROOT / "config").read_text()
BASE_KITTY = (theme.ROOT / "kitty.conf").read_text()
BASE_BLOCKS = (theme.ROOT / "i3blocks/config").read_text()
# i3 directives that carry behavior rather than looks. Colors, gaps, borders,
# fonts, and bar styling are deliberately excluded: a finish may change those.
BEHAVIOR = ("set ", "exec", "for_window", "bindsym", "bindcode", "mode ",
            "floating_modifier", "tiling_drag", "workspace ")


def scratch():
    """Temporary directory inside the ignored build/ tree, never in /tmp."""

    SCRATCH.mkdir(parents=True, exist_ok=True)
    return tempfile.TemporaryDirectory(dir=SCRATCH)


def child_env(home):
    """Environment for theme.py subprocesses: HOME, temp, caches stay in build/."""

    return dict(os.environ, HOME=str(home), TMPDIR=str(home),
                XDG_CONFIG_HOME=str(home / ".config"),
                XDG_STATE_HOME=str(home / ".local/state"),
                XDG_CACHE_HOME=str(home / ".cache"),
                XDG_DATA_HOME=str(home / ".local/share"),
                PYTHONDONTWRITEBYTECODE="1")


def behavior(text):
    """Behavioral i3 lines, with palette colors and compositor path erased."""

    lines = []
    for line in text.splitlines():
        line = line.strip()
        if not line.startswith(BEHAVIOR):
            continue
        line = re.sub(r"#[0-9a-fA-F]{6,8}", "#HEX", line)
        line = re.sub(r"background_opacity=[0-9.]+", "background_opacity=ALPHA", line)
        lines.append(re.sub(r"exec(_always)? --no-startup-id picom.*", "PICOM", line))
    return lines


def combinations():
    return [(name, finish) for finish in theme.FINISHES for name in theme.PALETTES]


class RenderTests(unittest.TestCase):
    def test_every_binding_survives_every_combination(self):
        original = [line for line in BASE_I3.splitlines() if line.strip().startswith("bind")]
        for name, finish in combinations():
            with self.subTest(theme=name, finish=finish):
                rendered = [line for line in theme.render(name, finish=finish)["i3/config"].splitlines()
                            if line.strip().startswith("bind")]
                self.assertEqual(len(original), len(rendered))
                for before, after in zip(original, rendered):
                    # Only the floating terminal's visual opacity may differ.
                    self.assertEqual(re.sub(r"background_opacity=[0-9.]+", "ALPHA", before),
                                     re.sub(r"background_opacity=[0-9.]+", "ALPHA", after))

    def test_floating_terminal_changes_only_its_opacity(self):
        for name, finish in combinations():
            with self.subTest(theme=name, finish=finish):
                i3 = theme.render(name, finish=finish)["i3/config"]
                expected = theme.terminal_opacity(name, finish)
                self.assertIn(f"kitty --override background_opacity={expected} --class floating", i3)

    def test_non_visual_i3_behavior_is_untouched(self):
        for name, finish in combinations():
            with self.subTest(theme=name, finish=finish):
                self.assertEqual(behavior(BASE_I3),
                                 behavior(theme.render(name, finish=finish)["i3/config"]))

    def test_wallpaper_and_device_commands_survive(self):
        keep = ["exec_always feh --bg-fill ~/Pictures/wallpapers/entoto-hike.jpeg",
                "exec_always --no-startup-id xset r rate 250 50",
                "exec --no-startup-id xrandr --output eDP-1 --rate 120",
                "exec --no-startup-id xss-lock --transfer-sleep-lock -- $lockcmd",
                "set $lockcmd $HOME/.local/bin/lockscreen",
                "status_command i3blocks"]
        for name, finish in combinations():
            with self.subTest(theme=name, finish=finish):
                i3 = theme.render(name, finish=finish)["i3/config"]
                for line in keep:
                    self.assertIn(line, i3)

    def test_compositor_is_started_from_the_installed_config(self):
        for name, finish in combinations():
            with self.subTest(theme=name, finish=finish):
                i3 = theme.render(name, Path("/home/example/.config"), finish)["i3/config"]
                started = "exec_always" if finish == "minimal" else "exec"
                self.assertIn(f"{started} --no-startup-id picom --config /home/example/.config/picom/picom.conf", i3)

    def test_kitty_mappings_and_font_size_survive(self):
        mappings = [line for line in BASE_KITTY.splitlines() if line.startswith("map ")]
        for name, finish in combinations():
            with self.subTest(theme=name, finish=finish):
                kitty = theme.render(name, finish=finish)["kitty/kitty.conf"]
                for mapping in mappings:
                    self.assertIn(mapping, kitty)
                self.assertIn("font_size         22", kitty)
                self.assertIn("dynamic_background_opacity yes", kitty)

    def test_i3blocks_modules_and_commands_survive(self):
        for name, finish in combinations():
            with self.subTest(theme=name, finish=finish):
                blocks = theme.render(name, finish=finish)["i3blocks/config"]
                for line in BASE_BLOCKS.splitlines():
                    # Only per-block color= lines are allowed to change.
                    if not line.startswith("color="):
                        self.assertIn(line, blocks)


class MinimalFinishTests(unittest.TestCase):
    def test_surfaces_are_opaque_and_compact(self):
        for name in theme.PALETTES:
            with self.subTest(theme=name):
                rendered = theme.render(name, finish="minimal")
                self.assertTrue(rendered["kitty/kitty.conf"].rstrip().endswith("background_opacity 1.0"))
                i3 = rendered["i3/config"]
                self.assertIn("gaps inner 6", i3)
                self.assertIn("gaps outer 0", i3)
                self.assertIn("smart_gaps on", i3)
                # Bar font size and the opaque bar background are left alone.
                self.assertIn("font pango:JetBrainsMono Nerd Font 14", i3)
                self.assertIn("background $rp_base", i3)
                self.assertNotIn("transparency = 12", rendered["dunst/dunstrc"])
                self.assertIn("transparency = 0", rendered["dunst/dunstrc"])

    def test_compositor_profile_has_no_blur(self):
        picom = theme.render("nord", finish="minimal")["picom/picom.conf"]
        self.assertIn('blur-method = "none"', picom)
        self.assertNotIn("dual_kawase", picom)
        self.assertIn("fading = false", picom)

    def test_kitty_font_family_is_not_replaced(self):
        kitty = theme.render("gruvbox", finish="minimal")["kitty/kitty.conf"]
        self.assertIn("font_family       ShureTechMonoNerdFont", kitty)
        self.assertEqual(kitty.count("font_family"), BASE_KITTY.count("font_family"))


class GlassFinishTests(unittest.TestCase):
    def test_glass_remains_the_default_and_is_unchanged(self):
        for name in theme.PALETTES:
            with self.subTest(theme=name):
                self.assertEqual(theme.render(name), theme.render(name, finish="glass"))
                rendered = theme.render(name, finish="glass")
                self.assertIn("gaps inner 18", rendered["i3/config"])
                self.assertIn("smart_gaps off", rendered["i3/config"])
                self.assertIn(f"background_opacity {theme.PALETTES[name]['opacity']}", rendered["kitty/kitty.conf"])
                self.assertIn("dual_kawase", rendered["picom/picom.conf"])


class PreviewTests(unittest.TestCase):
    def test_gallery_covers_every_combination(self):
        with scratch() as directory:
            output = Path(directory)
            theme.preview(output)
            page = (output / "index.html").read_text()
            self.assertIn(f"{len(theme.PALETTES)} palettes", page)
            self.assertIn(f"{len(theme.FINISHES)} finishes", page)
            for name, finish in combinations():
                self.assertIn(f"make theme THEME={name} FINISH={finish}", page)
                for relative in theme.sources(finish).values():
                    self.assertTrue((output / finish / name / relative).is_file())
                # i3 -C only parses the file: no X connection, no window manager.
                if shutil.which("i3"):
                    subprocess.run(["i3", "-C", "-c", str(output / finish / name / "i3/config")],
                                   check=True, capture_output=True, env=child_env(Path(directory)))


class InstallTests(unittest.TestCase):
    def test_apply_backs_up_previous_theme(self):
        with scratch() as directory:
            root = Path(directory)
            config, backups = root / "config", root / "backups"
            (config / "kitty").mkdir(parents=True)
            (config / "kitty/kitty.conf").write_text("original\n")
            theme.apply("ember", config, backups, "glass")
            saved = list(backups.iterdir())[0]
            self.assertEqual((saved / "kitty/kitty.conf").read_text(), "original\n")
            theme.apply("nord", config, backups, "minimal")
            self.assertEqual(len(list(backups.iterdir())), 2)
            self.assertIn("#2e3440", (config / "kitty/kitty.conf").read_text())
            self.assertEqual((saved / "kitty/kitty.conf").read_text(), "original\n")

    def test_invalid_input_writes_nothing(self):
        for arguments in [[], ["unknown"], ["../ember"], ["ember", "--finish", "neon"],
                          ["ember", "--finish", ""], ["nord", "--finish", "../glass"]]:
            with self.subTest(arguments=arguments), scratch() as directory:
                home = Path(directory)
                config = home / "config"
                result = subprocess.run(["python3", str(theme.ROOT / "scripts/theme.py"), "apply",
                                         *arguments, "--config-dir", str(config),
                                         "--backup-dir", str(home / "backups")],
                                        capture_output=True, env=child_env(home))
                self.assertNotEqual(result.returncode, 0)
                self.assertFalse(config.exists())
                self.assertFalse((home / "backups").exists())

    def test_unknown_finish_is_rejected_by_the_library(self):
        with self.assertRaises(AssertionError):
            theme.render("nord", finish="neon")
