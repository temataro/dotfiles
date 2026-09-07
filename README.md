# dotfiles
Personal dotfile collection. Happy travels space cowboys!

## Desktop themes

| Theme | Look |
|---|---|
| `ember` | Smoked amber glass, bronze dunes, 80% opacity |
| `tide` | Midnight mineral landscape, sea glass, 76% opacity |
| `paper` | Frosted porcelain, ivory folds, 87% opacity |

```sh
make                    # help; no package installation
make preview            # open build/themes/index.html in your browser
make theme THEME=tide   # apply a palette with backups
make check              # isolated rendering and backup tests
make plan               # show full setup commands without running them
```

The gallery uses the actual wallpapers with interactive opacity sliders.
It is an illustration, not an exact screenshot; sliders do not edit configs.
Each theme adds translucent kitty backgrounds, picom blur, 16px corners, broad
soft shadows, 18px inner gaps, 12px outer gaps, a translucent bar and launcher,
and original artwork. Single windows retain gaps. Text stays opaque.

Kitty uses JetBrainsMono Nerd Font (already installed here), keeps your font
size, and gains padding and a beam cursor. Navigation shortcuts stay intact.
Floating kitty now uses the same opacity as tiled kitty.

Dependencies: Python 3, i3 4.22+, kitty, picom 10+ with GLX, feh, rofi, i3blocks,
i3status, and dunst. `make desktop-deps` installs desktop packages using apt
or pacman. No new packages were needed on this machine.

`make theme` copies six configs plus the wallpaper into
`${XDG_CONFIG_HOME:-$HOME/.config}`. Local edits in those six live configs are
replaced, so bring wanted edits into the repo first. Existing files are backed
up under `${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/theme-backups/<timestamp>/`.
To restore, copy that backup's contents into your config directory; files that
did not exist before applying the theme have no backup and can be removed
individually. Switching themes again creates another backup.

After applying, log out and back into i3 to load everything together. To try it
without logging out, restart your compositor with the installed config (below),
press `Alt+Shift+r` to restart i3 and its bar, and `Ctrl+Shift+F5` in kitty.
Rofi uses the new look next launch; restart dunst for notification changes.
No running processes are restarted by the installer.

```sh
# On a single desktop session, restart your user's compositor:
pkill -u "$(id -u)" -x picom
picom --config "${XDG_CONFIG_HOME:-$HOME/.config}/picom/picom.conf" -b
```

In kitty, `Ctrl+Shift+Alt+Up/Down` adjusts opacity live; `Ctrl+Shift+Alt+0`
restores the theme value. Edit `opacity` in `themes/palettes.json` to persist a
different default. Blur adds GPU work; lower `blur-strength` in
`themes/glass/picom.conf` if needed. Without working GLX, use
`backend = "xrender"` and `blur-method = "none"` for transparency without blur.

Tmux, Neovim, and shell prompt colors remain unchanged. Apps that paint an
explicit terminal background can cover the glass; use their transparent/default
background option when desired. Fullscreen windows skip blur and rounding;
kitty's own background alpha still applies.

`make deploy` remains the broader legacy config copy operation: it overwrites
i3 and kitty with the baseline configs, without theme backups. Use `make theme`
after it to reapply your palette. `make refresh` refuses to import generated
i3/kitty configs into the baseline; restore their originals from a backup first.
Legacy deploy/refresh targets use `$HOME/.config`, regardless of XDG overrides.

The palette JSON uses the role order documented in [ARCHITECTURE.md](ARCHITECTURE.md).
JSON does not support comment headers; script and workflow headers carry the
copyright and Apache-2.0 identifier.
