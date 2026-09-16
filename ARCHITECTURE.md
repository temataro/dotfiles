# Desktop configuration architecture

Root `config` and `kitty.conf`, plus `rofi/`, `i3blocks/`, and `dunst/`, supply
the base behavior. `scripts/theme.py` maps their Rosé Pine colors into the
selected palette, then applies a finish. Navigation remains in one source;
generated configs are not edited or committed.

`themes/palettes.json` holds descriptions, terminal opacity, and these ordered
color roles: base, surface, overlay, muted text, text, red, gold, rose, green,
blue, and focus accent. Exact six-digit substitution preserves eight-digit
transparent colors. Source palette changes require updating the base mapping.

A palette and a finish are independent: `render(name, config_dir, finish)`
recolors first, then hands the file set to one finish function. `FINISHES` in
`scripts/theme.py` names each finish, its compositor source, and whether it is
opaque; `glass` is the default so existing invocations are unchanged. Adding a
palette is a JSON entry; adding a finish is a dict entry plus one function.

`glass` widens gaps, thins borders, sets kitty typography, padding, and alpha,
reduces bar type to 11pt, and makes the bar, launcher, and notifications
translucent. `minimal` tightens gaps to 6px with no outer gap, keeps smart gaps,
squares the corners, and removes the transparency these configs ask for; it
changes no font size, no font family, and no bar module. Neither finish forces
windows opaque: `detect-client-opacity` stays on, so an application setting its
own alpha is still composited translucent. Both keep the wallpaper command, the
device lines, every binding, and both modes — including the baseline's undefined
`$editor` in the `$mod+Shift+w` binding, which is preserved verbatim rather than
repaired here. The floating terminal binding is rewritten only at its
`background_opacity=` value.

`themes/glass/picom.conf` blurs; `themes/minimal/picom.conf` has no blur, no
fade, and square corners. The latency-focused baseline `picom.conf` remains
available. Kitty controls background alpha; picom provides blur, corners, and
shadows. Text and ordinary applications are not globally dimmed. Fullscreen
windows skip blur and rounding.

Rendering writes an explicit compositor path into the i3 config: `glass` starts
picom at login with `exec`, `minimal` keeps the baseline `exec_always`, which
re-runs the command on every i3 reload. Neither reloads a running compositor —
a second picom exits while one holds the session — so applying a theme leaves
the live picom on its old config until it is restarted by hand. Preview
generation writes configs into ignored `build/themes/<finish>/<palette>/` and a
gallery built from `themes/preview.css`; card counts and commands come from the
data, not from prose. The opacity sliders affect only the illustration.

Applying backs up all existing destinations before writing six configs. Backups
are per invocation; writes are not one atomic transaction. The installer does
not restart processes. Invalid palettes and finishes are rejected by argparse
and by assertions in `render`, before any file is touched.

The Makefile tracks desktop dependencies as `command:apt:pacman` rows, one per
directly invoked command — window manager, bar, launcher, notifier, the device
and lockscreen helpers, and the tooling's own `python3`, `pkill`, `date`, and
`systemctl`. Transitive dependencies are left to the package manager. `make
deps` reports installed state and package names, `make desktop-deps` installs
the same set, and `-` marks commands the distro cannot provide, which are listed
as manual steps rather than replaced by a different package. Fonts are out of
that scope by design: `make fonts` downloads Nerd Font releases directly.

Tests cover every palette/finish combination: bindings, non-visual i3
directives, i3blocks modules, kitty mappings and font size, wallpaper and device
commands, finish-specific styling, repeat backups, invalid inputs, and `i3 -C`
parsing when i3 is available. Nothing starts a graphical program or a display
server. They keep HOME, TMPDIR, XDG directories, and bytecode caches inside
`build/`. CI runs them without installing desktop packages.

Legacy `deploy` still copies baseline configs. `refresh` rejects generated
i3/kitty configs to protect the source palette. Both use `$HOME/.config`;
the theme installer respects XDG paths.

Palette and finish rationale, with sources: [themes/DESIGN.md](themes/DESIGN.md).
