# dotfiles
Personal dotfile collection. Happy travels space cowboys!

## Desktop themes

A theme is a **palette** plus a **finish**. Every palette works with every
finish; `make themes` prints the current list.

| Palette | Look |
|---|---|
| `ember` | Smoked amber glass, bronze dunes |
| `tide` | Midnight mineral landscape, sea glass |
| `paper` | Frosted porcelain, ivory folds |
| `gruvbox` | Warm retro contrast, grey surfaces, orange focus |
| `nord` | Cold polar night surfaces, frost accents |

| Finish | Look |
|---|---|
| `glass` (default) | Translucent kitty, picom blur, 16px corners, 18px inner gaps |
| `minimal` | No blur or added transparency, square corners, 6px inner gaps |

```sh
make                                    # help; no package installation
make themes                             # palettes and finishes
make preview                            # open build/themes/index.html
make theme THEME=tide                   # glass finish (unchanged default)
make theme THEME=nord FINISH=minimal    # opt-in minimal finish
make deps                               # what the desktop configs need here
make check                              # isolated rendering and backup tests
make plan                               # show full setup commands, run nothing
```

The gallery renders every palette/finish combination. It is an illustration,
not a screenshot: glass cards get an opacity slider, minimal cards are flat,
and no slider edits a config.

**Glass** adds translucent kitty backgrounds, picom blur, 16px corners, broad
soft shadows, 18px inner and 12px outer gaps, and a translucent bar and
launcher; single windows keep their gaps, and it sets bar type to 11pt.
**Minimal** keeps 6px inner gaps with no outer gap, smart gaps on, 1px borders,
square corners, an opaque bar and launcher, and no blur. It changes no font
size — bar type stays 14pt, kitty stays at `font_size 22` with its own font
family.

Minimal means these configs request no transparency and its picom profile adds
no opacity rules. It does not force windows opaque: `detect-client-opacity`
stays on, so an application that sets its own alpha (an ARGB window, or
`_NET_WM_WINDOW_OPACITY`) still renders translucent.

Both finishes preserve every keybinding, both modes, all seven i3blocks
modules, the `feh` wallpaper command, and the device lines (`xset r rate`,
`xrandr --rate 120`, `xss-lock`). The only binding whose text differs is the
floating terminal, where the `background_opacity=` value follows the finish.
Text is never dimmed. Baseline quirks are reproduced as-is — including
`$mod+Shift+w`, which calls an `$editor` variable that `config` never defines,
so it is as broken after theming as before. See
[themes/DESIGN.md](themes/DESIGN.md) for why this stays on i3bar and X11.

Dependencies: `make deps` lists every command the i3 config, i3blocks config,
lockscreen binding, and theme tooling call directly — python3, pkill, systemctl
and date included — with its apt or pacman package and whether it is installed
here. `make desktop-deps` installs exactly those packages; what those packages
pull in themselves is left to the package manager. Reported instead of
substituted: commands with no package on your distro (i3lock-fancy on Arch),
the custom `~/.local/bin/lockscreen` wrapper, and the `/usr/share/i3blocks/*`
status scripts (Debian ships them with i3blocks, Arch does not). The Nerd Fonts
are installed by `make fonts`, which downloads releases rather than packages,
so `desktop-deps` does not cover them.

`make theme` copies six configs into
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

The compositor in particular needs that manual restart. The minimal finish
keeps the baseline `exec_always` picom line and glass uses `exec`, but neither
reloads a picom that is already running: `exec_always` re-runs the command on
an i3 reload and the second instance exits, since one compositor is already
there. Until you restart it, picom keeps the config it started with.

```sh
# On a single desktop session, restart your user's compositor:
pkill -u "$(id -u)" -x picom
picom --config "${XDG_CONFIG_HOME:-$HOME/.config}/picom/picom.conf" -b
```

With the glass finish, `Ctrl+Shift+Alt+Up/Down` adjusts kitty opacity live and
`Ctrl+Shift+Alt+0` restores the theme value; edit `opacity` in
`themes/palettes.json` to persist a different default. Blur adds GPU work;
lower `blur-strength` in `themes/glass/picom.conf` if needed. Without working
GLX, use `backend = "xrender"` and `blur-method = "none"`. The minimal finish
ships `themes/minimal/picom.conf`, which has no blur to begin with, and leaves
kitty's opacity controls out because its kitty background is opaque.

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
