# Makefile improvement report

Goal: make `make`-driven machine setup reliable enough that bringing up a fresh
PC is a one-liner that doesn't silently skip configs or break on the next box.

Scope: this repo targets Arch (`pacman`) and Debian/Ubuntu (`apt`) per CLAUDE.md.
macOS/`brew` is intentionally **out of scope** below. ARM/aarch64 Linux ("other
computers" incl. Apple-Silicon VMs / Pis) **is** in scope.

---

## TL;DR — the two things that actually make it "break too easily"

1. **`deploy` and `refresh` are two hand-maintained, parallel path lists.** Adding
   a config means editing both and keeping them byte-for-byte in sync. The default
   failure mode is *forgetting* — which is exactly what already happened: ~8
   configs live in the repo but are never deployed (see §3). This is the root
   cause; fix it structurally with one data-driven `src → dest` map both targets
   iterate over.

2. **CI runs `make`, which is `sudo apt install …` on every push.** The workflow's
   `run: make` resolves to `all → basic → $(INSTALL) $(BASIC_COMMON)`. So every
   push/PR does a real package install on GitHub's runner: slow, network-flaky,
   and it validates *nothing* about the Makefile's correctness. This is the
   literal "breaks easily" smoking gun. CI should lint + dry-run, never install.

Everything else is secondary hardening.

---

## 1. Current breakage (wrong right now)

### 1a. Uncommitted WIP in the working tree (flagging as observed state, may be intentional)
`git diff Makefile` shows two un-committed edits:

- **`tmux` target no longer installs tpm.** The clone line was changed to
  `echo "git clone …"` **and** lost its trailing `;`. It still parses as valid
  `sh` — so it does **not** error — it just prints the command and the `else`
  branch gets swallowed as an argument to `echo`. Net effect: tpm is *silently
  never cloned*. A user who runs it and sees no error will wrongly conclude the
  Makefile is fine.
- **`fonts` was dropped from the `tem` aggregate.** `make tem` now installs no
  fonts. May be deliberate (fonts is slow), but it's an inconsistency to resolve.

### 1b. CI installs instead of validating
`.github/workflows/makefile.yml` → `run: make`. See TL;DR #2. Replace with a
`make check` (lint via `make --dry-run`, optionally `shellcheck` on the recipe
bodies and `checkmake` on the Makefile).

### 1c. `fonts` downloads *into the repo* and dirties the tree
`FONT_SRC := $(dotfiles_dir)/extra/fonts`. Running `make fonts` writes zips +
extracted fonts into the working tree — that's the `?? extra/fonts/` currently in
`git status`. Downloads belong in a cache/temp dir (e.g. `$(HOME)/.cache/dotfiles-fonts`
or `mktemp -d`), with only the installed `.ttf/.otf` landing in `~/.local/share/fonts`.

### 1d. Pinned, rot-prone font URLs
Eight hardcoded nerd-font release tags (`v3.2.1`, `v3.3.0`, `v3.4.0`) plus a
third-party `ffonts.net/jsMath-cmr10` link. These 404 over time and there's no
checksum/verification. At minimum centralize the version as a variable; ideally
resolve "latest" or pin with a comment on why.

---

## 2. Structural root cause — collapse deploy/refresh into one map

Today `deploy` (repo→home) and `refresh` (home→repo) each spell out the same set
of paths in opposite directions, and only `refresh` is guarded with `-`. Replace
both with a single declarative mapping and generate both directions from it.

Sketch:

```make
# src (relative to repo)        dest (under $HOME)
CONFIGS := \
  .zshrc:.zshrc \
  .tmux.conf:.tmux.conf \
  .vimrc:.vimrc \
  .gitconfig:.gitconfig \
  kitty.conf:.config/kitty/kitty.conf \
  config:.config/i3/config \
  alacritty.toml:.config/alacritty/alacritty.toml \
  zed/settings.json:.config/zed/settings.json \
  ...
# dir-style entries (rsync) kept in a second list:
CONFIG_DIRS := \
  nvim:.config/nvim \
  hyprland-configs/hypr:.config/hypr \
  ...
```

`deploy` and `refresh` then loop over `$(CONFIGS)` splitting on `:` and copying
in the chosen direction. One list, no drift. Add the entry once → both directions
work. (Alternatively: a small `stow`-style symlink approach, but the repo
explicitly chose copy-based sync, so keep that and just de-duplicate.)

---

## 3. Coverage gaps — configs in the repo that `deploy` never touches

These exist in the repo but no target installs them (root cause: §2):

| Repo path | Should land at |
|-----------|----------------|
| `alacritty.toml` | `~/.config/alacritty/alacritty.toml` |
| `hyprland-configs/hypr/` | `~/.config/hypr/` |
| `hyprland-configs/waybar/` | `~/.config/waybar/` |
| `hyprland-configs/swaylock/config` | `~/.config/swaylock/config` |
| `zed/settings.json` | `~/.config/zed/settings.json` |
| `.i3status.conf` | `~/.i3status.conf` (or `~/.config/i3status/config`) |
| `ipython_config.py` | `~/.ipython/profile_default/ipython_config.py` |
| `computermodern.mplstyle` | matplotlib `stylelib/` dir |
| `xrandr/*.sh` | `~/.screenlayout/` |
| `.vim/colors/*.vim` | `~/.vim/colors/` |
| `extra/meditations/qotd.sh`, `extra/wallpapers/back4.sh` | a `~/bin` or `~/.local/bin` |

`astro.nvim/`, `CLAUDE.md`, this file, and reference material stay un-deployed
(intentional). Decide per-row whether it's in the deploy map or genuinely archival.

### 3a. `setup_debian.sh` installs things the Makefile lacks
If the Makefile is meant to be the single source of truth for machine transitions,
the shell script currently does extra work that would silently disappear:

- Rust (`rustup`), Go (`golang-go`)
- Python: `python3 python3-pip ipython3 black` + `pip install -r requirements.txt`
- `xrandr/*` → `~/.screenlayout/`
- brightness-controller (PPA), dictd, the BetaPictoris `wiki` build

**Decision to make explicitly:** promote the Makefile to single source of truth
and either (a) port these into targets (`rust`, `go`, `python`, `screenlayout`)
or (b) keep `setup_debian.sh` as an explicitly-named legacy path. Don't leave two
half-overlapping installers.

---

## 4. Portability & robustness hardening

- **lazygit hardcodes `Linux_x86_64`** → fails on aarch64. Derive arch from
  `uname -m` (`x86_64`→`x86_64`, `aarch64`→`arm64`) and pick the matching asset.
- **No backup before overwrite.** `deploy` `cp`s over live `~/.zshrc` etc. with no
  `.bak`; `refresh` overwrites repo files from a possibly-incomplete live box.
  Add a timestamped backup (or `cp --backup=numbered`) before clobbering.
- **`deploy` is unguarded; `refresh` uses `-`.** Make robustness symmetric (the
  data-driven loop fixes this for free — guard once in the loop body).
- **`all: basic` makes bare `make` run `sudo` installs.** A surprising, hard-to-
  undo default. Point `.DEFAULT_GOAL`/`all` at `help` instead, so `make` is safe.
- **`chsh` runs unconditionally** in `zsh` — guard on current shell already being zsh.
- **`kitty +kitten themes` is interactive** (already commented + `-`-guarded);
  prefer writing the theme include into `kitty.conf` directly so setup stays
  non-interactive.
- **`snaps` assumes snap exists** — gate on `command -v snap` (absent on Arch).
- **`help` text is hand-maintained** and already drifts from `.PHONY`. Generate it
  from `##`-annotated target comments (standard self-documenting-Makefile trick).
- **`neovim: deploy` is misleading** — it deploys *everything*, not just nvim.
  Either make it nvim-only or drop the alias.
- **Aggregate targets install non-interactively (`-y`/`--noconfirm`)** with only a
  comment as warning. Consider a `make plan` (dry-run) and/or a typed confirm gate
  on `tem`.

---

## 5. Prioritized action plan

**P0 — stop the bleeding (current breakage):**
1. Fix/decide the uncommitted `tmux` edit (restore the real `git clone`) and the
   `fonts`-dropped-from-`tem` edit.
2. Repoint CI at `make check` (dry-run + lint), not `make`.
3. Move `fonts` downloads out of the repo into a cache dir; clean up `extra/fonts/`.

**P1 — kill the root cause:**
4. Replace `deploy`/`refresh` with one data-driven `src→dest` map (§2).
5. Backfill the orphaned configs (§3) into that map.
6. Add backup-before-overwrite to both directions.

**P2 — portability & polish:**
7. Arch-aware lazygit download (§4).
8. Make bare `make` safe (`all → help`); self-documenting `help`.
9. Decide the `setup_debian.sh` consolidation (§3a); port Rust/Go/Python or
   formally deprecate the script.
10. Guard `chsh`, `snaps`; de-interactive-ize `kitty` theme; centralize font versions.

---

---

## Status: IMPLEMENTED (Session 2)

P0–P2 applied. See the "Session 2 — Makefile hardening" note in `CLAUDE.md` for the
change summary. Highlights: data-driven `CONFIG MAP`, ~8 orphaned configs backfilled,
backup-on-overwrite, CI → `make check`, arch-aware lazygit, `setup_debian.sh` deprecated.
Verified via `make help` / `make check` / `make deploy HOME=<tmpdir>` (no real installs run).

### Open decisions left for the owner
- **`make check` validates *parsing only*.** `make --dry-run` prints recipes but
  does not execute them, so it would NOT have caught the original `tmux` bug or any
  recipe-body shell error. To catch that class, pipe recipe bodies through `bash -n`.
- Font checksum/verification, and whether `make python` should route through `uv`
  instead of system pip.
