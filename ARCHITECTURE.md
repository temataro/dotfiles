# Desktop configuration architecture

Root `config` and `kitty.conf`, plus `rofi/`, `i3blocks/`, and `dunst/`, supply
the base behavior. `scripts/theme.py` maps their Rosé Pine colors into the
selected palette, then applies shared glass styling. Navigation remains in
one source; generated configs are not edited or committed.

`themes/palettes.json` holds descriptions, terminal opacity, and these ordered
color roles: base, surface, overlay, muted text, text, red, gold, rose, green,
blue, and focus accent. Exact six-digit substitution preserves eight-digit
transparent colors. Source palette changes require updating the base mapping.

Glass styling changes gaps and borders, kitty typography and padding, and
launcher/bar alpha. `themes/glass/picom.conf` supplies a separate compositor
profile; the old latency-focused baseline remains available. Kitty controls
background alpha; picom provides blur, corners, and shadows. Text and ordinary
applications are not globally dimmed. Fullscreen windows skip blur and rounding.

`themes/wallpapers/` contains original generated artwork and its provenance.
Rendering writes explicit destination paths in i3 for picom and wallpaper.
Preview generation writes configs and images into ignored `build/themes/`.
The HTML gallery uses CSS from `themes/glass/preview.css`; its opacity sliders
affect only the illustration.

Applying backs up all existing destinations before writing six configs and
one PNG. Backups are per invocation; writes are not one atomic transaction.
The installer does not restart processes. An i3 login starts picom once;
i3 restarts reapply wallpaper without spawning another compositor.

Tests cover rendering, navigation preservation, artwork deployment, repeat
backups, invalid inputs, and i3 validation when available. The desktop stack
was also rendered in isolated Xvfb with picom GLX. CI runs portable tests
without installing desktop packages.

Legacy `deploy` still copies baseline configs. `refresh` rejects generated
i3/kitty configs to protect the source palette. Both use `$HOME/.config`;
the theme installer respects XDG paths.
