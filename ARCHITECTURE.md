# Desktop configuration architecture

Root `config` and `kitty.conf`, plus `rofi/`, `i3blocks/`, and `dunst/`, remain
the source of desktop behavior. Their existing Rosé Pine colors define the
palette roles. Existing installation and copy-based deployment targets remain
in `Makefile`.

`themes/palettes.json` defines three ordered palettes: base, surface, overlay,
muted text, text, red, gold, rose, green, blue, and focus accent.
`scripts/theme.py` substitutes exact six-digit colors in those five source
configs. It also maps kitty's extra background and selection shades; eight-digit
transparent colors stay intact. Behavioral settings are not generated.

`make preview` renders all palettes under ignored `build/themes/` and produces
an HTML gallery with CSS illustrations. `make theme THEME=<name>` renders one
palette in memory, backs up existing destination files, and writes the configs.
The script does not install packages or reload running applications. Backups
are per invocation; installation is not an atomic transaction across files.

`make check` exercises rendering, keybinding preservation, invalid CLI inputs,
and backups in temporary directories. It validates every i3 variant when i3
is installed. CI runs these checks instead of invoking package installation.

Palette substitution depends on the baseline colors: changing the source
palette requires updating the mappings in `scripts/theme.py`. Keeping one
behavioral source avoids three diverging copies of the desktop configuration.
The legacy refresh command rejects generated configs to protect this baseline.
