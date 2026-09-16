# Design notes: palettes and finishes

Three r/unixporn desktops informed this work. They are references for colour
and geometry only; no code from them is imported or executed here.

| Source | What it shows | Taken | Left out |
|---|---|---|---|
| [i3 Gruvbox: default i3bar, kitty, rofi, picom](https://www.reddit.com/r/unixporn/comments/1exmapv/) | Gruvbox reads well on the *default* i3bar; kitty, rofi, and picom round it out | Gruvbox role colours; confirmation that the stock bar needs no replacement | Its picom tuning — ours is already latency-tuned for a 120Hz OLED |
| [Nord: i3-gaps, kitty, no compositor, Polybar](https://www.reddit.com/r/unixporn/comments/uzs8ii/) | Nord stays legible with no compositor running at all; the bar there is Polybar | Nord role colours; the "effects are optional" idea behind the minimal finish | Polybar — inspiration only, see below |
| [Nord, no gaps](https://www.reddit.com/r/unixporn/comments/fw1f2e/) | Cold minimalism with gaps removed entirely and flat, square surfaces | The direction: flat surfaces, square corners, thin borders, no blur | **Its gap removal.** We keep 6px inner gaps (see below) |

## Decisions

**Palette and finish are independent.** A palette is 11 colour roles; a finish
is geometry and transparency. Five palettes times two finishes comes out of one
renderer, so adding either later costs one entry.

**6px gaps, not zero.** The no-gaps source removes gaps outright. We tighten
instead: `gaps inner 6`, `gaps outer 0`, `smart_gaps on`. A single window
therefore has no gap at all, which is the look that source is after, while
tiled splits keep a visible seam. Going to zero everywhere is one edit in
`minimal()` in `scripts/theme.py` if the seam turns out to be unwanted.

**Keep i3bar and i3blocks; do not import Polybar.** The bar already carries
seven blocks, per-block colours, a Nerd Font icon set, and a live refresh path
(`pkill -RTMIN+10 i3blocks`) wired into the volume bindings in `config`.
Polybar would mean re-implementing every module, adding a dependency, and
maintaining a second theming path — real parity risk for a look the default
i3bar already reaches once the palette is coordinated. The Nord source is cited
for its colours, not its bar.

**Stay on X11 and i3; do not migrate to Wayland.** picom, `xss-lock` with the
custom `i3lock-fancy` wrapper, the `xrandr --rate 120` line, `xset r rate`, and
the `feh` wallpaper command are X11 paths that a Wayland compositor would need
replaced with its own equivalents. Others carry over unchanged: keyd works at
the evdev/uinput layer and is not tied to X, and kitty, rofi, dunst, and
flameshot all have Wayland support. The point is not that everything breaks —
it is that a compositor migration is a rehaul with its own testing, and this
change is a theme.

**The minimal finish is opt-in and conservative.** It changes gaps, borders,
corner radius, and transparency. It does not touch bindings, modes, bar
modules, bar or terminal font sizes, the wallpaper command, or the device lines
(`xset r rate`, `xrandr --rate`). The only binding whose text changes at all is
the floating terminal, where `background_opacity=0.45` becomes `1.0` — the same
window, the same keys, no translucency.

**Parity includes the baseline's rough edges.** `config` binds
`$mod+Shift+w` to `$editor ... -e "nmtui-connect"`, and `$editor` is never
`set` anywhere in that file, so the binding does not work today. Both finishes
reproduce the line verbatim rather than quietly defining the variable: a theme
that silently changes what a key does is worse than one that preserves a known
gap. Fixing it is a separate change to `config`.

**Compositor reload is manual.** Both finishes write an explicit
`--config <path>` into the picom line; `glass` uses `exec` (login only),
`minimal` keeps the baseline `exec_always`. `exec_always` re-runs the command
on every i3 reload, but a second picom exits immediately when one is already
running — it does **not** restart the compositor. After applying a theme,
either log out and back in or restart picom by hand.
