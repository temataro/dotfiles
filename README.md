# dotfiles
Personal dotfile collection. Happy travels space cowboys!

## Desktop themes

| Theme | Look |
|---|---|
| `ember` | Warm charcoal, terracotta, sage |
| `tide` | Ocean blue, sea glass, lavender |
| `paper` | Ivory, dark ink, forest green, plum |

```sh
make                    # help; no package installation
make preview            # open build/themes/index.html in your browser
make theme THEME=tide   # apply a palette with backups
make check              # isolated rendering and backup tests
make plan               # show full setup commands without running them
```

The browser gallery is an illustrative mockup, not a screenshot. Themes retain
the repo's current keybindings, fonts, gaps, wallpaper, and compositor behavior.
Python 3 is the only dependency added by this workflow. Existing desktop tools
(i3, kitty, rofi, i3blocks, dunst) must already be installed to use their configs.

`make theme` copies five configs from the repo with the selected palette into
`${XDG_CONFIG_HOME:-$HOME/.config}`. Local edits in those five live configs are
replaced, so bring wanted edits into the repo first. Existing files are backed
up under `${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/theme-backups/<timestamp>/`.
To restore, copy that backup's contents into your config directory; files that
did not exist before applying the theme have no backup and can be removed
individually. Switching themes again creates another backup.

Reload i3 with `Alt+Shift+c` and kitty with `Ctrl+Shift+F5`. Rofi picks up the
theme next launch. Restart i3blocks and dunst when convenient; an i3 restart
(`Alt+Shift+r`) restarts its bar. No session processes are restarted automatically.
Picom, wallpaper, tmux, Neovim, and shell prompt colors are not changed.

`make deploy` remains the broader legacy config copy operation: it overwrites
i3 and kitty with the baseline configs, without theme backups. Use `make theme`
after it to reapply your palette. `make refresh` refuses to import generated
i3/kitty configs into the baseline; restore their originals from a backup first.
Legacy deploy/refresh targets use `$HOME/.config`, regardless of XDG overrides.

The palette JSON uses the role order documented in [ARCHITECTURE.md](ARCHITECTURE.md).
JSON does not support comment headers; script and workflow headers carry the
copyright and Apache-2.0 identifier.
