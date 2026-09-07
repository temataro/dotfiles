# =============================================================================
# test_theme.py — Verify palette rendering and recoverable theme installation.
#
# Tests use temporary directories and never touch the desktop session.
# Copyright (c) 2026 Temesgen Ataro <ataro.temesgen@gmail.com>
# SPDX-License-Identifier: Apache-2.0
# =============================================================================

from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

from scripts import theme


class ThemeTests(unittest.TestCase):
    def test_preserves_bindings_and_transparency(self):
        original = (theme.ROOT / "config").read_text()
        bindings = [line for line in original.splitlines() if line.strip().startswith("bind") and "background_opacity=" not in line]
        for name in theme.PALETTES:
            rendered = theme.render(name)
            self.assertEqual(bindings, [line for line in rendered["i3/config"].splitlines() if line.strip().startswith("bind") and "background_opacity=" not in line])
            self.assertIn("#00000000", rendered["i3/config"])
            self.assertIn("font_size         22", rendered["kitty/kitty.conf"])

    def test_preview_and_i3_validation(self):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory)
            theme.preview(output)
            self.assertTrue((output / "index.html").exists())
            for name in theme.PALETTES:
                for relative in theme.FILES.values():
                    self.assertTrue((output / name / relative).is_file())
                self.assertEqual((output / name / "dotfiles/wallpaper.png").read_bytes(), (theme.ROOT / f"themes/wallpapers/{name}.png").read_bytes())
                if shutil.which("i3"):
                    subprocess.run(["i3", "-C", "-c", str(output / name / "i3/config")], check=True, capture_output=True)

    def test_apply_backs_up_previous_theme(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            config, backups = root / "config", root / "backups"
            (config / "kitty").mkdir(parents=True)
            (config / "kitty/kitty.conf").write_text("original\n")
            theme.apply("ember", config, backups)
            saved = list(backups.iterdir())[0]
            self.assertEqual((saved / "kitty/kitty.conf").read_text(), "original\n")
            theme.apply("paper", config, backups)
            self.assertEqual((config / "dotfiles/wallpaper.png").read_bytes(), (theme.ROOT / "themes/wallpapers/paper.png").read_bytes())
            self.assertEqual(len(list(backups.iterdir())), 2)
            self.assertIn("#f5f0e7", (config / "kitty/kitty.conf").read_text())
            self.assertEqual((saved / "kitty/kitty.conf").read_text(), "original\n")

    def test_invalid_theme_does_not_write(self):
        with tempfile.TemporaryDirectory() as directory:
            config = Path(directory) / "config"
            for name in [[], ["unknown"], ["../ember"]]:
                result = subprocess.run(["python3", str(theme.ROOT / "scripts/theme.py"), "apply", *name, "--config-dir", str(config)], capture_output=True)
                self.assertNotEqual(result.returncode, 0)
                self.assertFalse(config.exists())
