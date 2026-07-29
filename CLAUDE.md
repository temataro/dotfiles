# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Personal dotfiles for an Arch Linux / Debian system running i3wm or Hyprland, with Neovim (AstroNvim-based), Zsh (antidote + starship), tmux, and kitty/alacritty as the terminal.

## Structure

| Path | Purpose |
|------|---------|
| `nvim/` | Active Neovim config (AstroNvim v5 + Lazy.nvim) |
| `astro.nvim/` | Older AstroNvim config (kept for reference) |
| `hyprland-configs/` | Hyprland WM, waybar, swaylock, hyprpaper |
| `config` | i3wm config (no extension — place at `~/.config/i3/config`) |
| `picom.conf` | picom compositor config, latency-tuned (→ `~/.config/picom/picom.conf`) |
| `keyd.conf` | keyd remaps: Copilot→R-Ctrl, Caps→Ctrl, F4→5 (→ `/etc/keyd/default.conf`, sudo) |
| `.zshrc` | Zsh config (antidote plugins + starship prompt), aliases, helpers |
| `.zsh_plugins.txt` | antidote plugin list (→ `~/.zsh_plugins.txt`) |
| `starship.toml` | starship prompt config, rose-pine (→ `~/.config/starship.toml`) |
| `.tmux.conf` | Tmux config |
| `.gitconfig` | Git config |
| `.vimrc` | Legacy Vim config (also sourced by Neovim via `nvim/vimrc.vim`) |
| `kitty.conf` / `alacritty.toml` | Terminal emulator configs |
| `setup_debian.sh` | Bootstrap script for Debian systems |
| `extra/` | Miscellaneous scripts (quote-of-the-day, wallpaper setter, meditations) |
| `xrandr/` | Monitor layout shell scripts |

## Neovim Architecture (`nvim/`)

- `init.lua` — bootstraps Lazy.nvim, sources `vimrc.vim` (which re-exports `~/.vimrc`), then loads `lazy_setup`, `statusline`, and `polish`
- `lua/lazy_setup.lua` — configures Lazy.nvim with AstroNvim v5 as the base distribution
- `lua/polish.lua` — **authoritative** place for vim options and keymaps; runs last so it overrides anything set by plugins
- `lua/statusline.lua` — custom hand-rolled statusline with git hunk counts via gitsigns
- `lua/community.lua` — AstroCommunity imports (currently disabled)
- `lua/plugins/` — plugin specs: `astrocore.lua` (features + buffer mappings), `astrolsp.lua` (LSP config), `astroui.lua` (colorscheme + highlight overrides), `mason.lua`, `treesitter.lua`, `render-markdown.lua`, colorschemes (`rose-pine.lua`, `gruvbox.lua`), `user.lua` (presence, lsp_signature, dashboard)
- `vimrc.vim` — re-exports `~/.vimrc` into Neovim's runtime path
- `.stylua.toml` — StyLua formatter config for Lua files

**Colorscheme:** `rose-pine-main` set in `astroui.lua`. Background forced to `#000000` via highlight override in the same file.
**Leader key:** `<Space>` | **Local leader:** `,`

## Formatting

- Lua (Neovim config): use `stylua` — config at `nvim/.stylua.toml`
- Python: use `black` (or `uv tool run black <file>`); bound to `<C-b>` in Neovim

## Deployment

Files are manually copied to their destinations (no symlink manager like stow). The `setup_debian.sh` script shows where each file lands:

- `~/.zshrc`, `~/.tmux.conf`, `~/.vimrc`, `~/.gitconfig`
- `~/.config/kitty/kitty.conf`
- `~/.config/picom/picom.conf` ← `picom.conf`
- `/etc/keyd/default.conf` ← `keyd.conf` (sudo; apply with `sudo systemctl restart keyd` — Ubuntu ships the CLI as `keyd.rvaiya`)
- `~/.config/nvim/` ← contents of `nvim/`
- `~/.config/i3/config` ← `config`
- `~/.config/hypr/`, `~/.config/waybar/`, `~/.config/swaylock/` ← from `hyprland-configs/`

---

# Thoughts from Claude

## Session 1 — Bonsai cleanup (nvim/)

### Done
- **Deleted dead files** (never loaded, never required):
  - `lua/settings/set.lua` — duplicated polish.lua options
  - `lua/settings/remap.lua` — duplicated polish.lua keymaps
  - `lua/settings/autoreload.lua` — referenced non-existent `neotree.lua`/`undotree.lua`
  - `lua/vimrc.vim` — stray duplicate of root `vimrc.vim`
  - `lua/plugins/lsp.lua` — called `lspconfig.pyright.setup({})` directly, conflicting with AstroLSP
- **Cleaned `polish.lua`**: removed double vimrc source (init.lua already does it), duplicate `mapleader`, duplicate `termguicolors`, redundant `vim.cmd("colorscheme ...")` (astroui.lua owns colorscheme)
- **Cleaned `astrocore.lua`**: removed fooscript placeholder filetypes, removed `options` block (conflicted with polish.lua; polish always wins since it runs last — `number=false` vs `nu=true`, `signcolumn="no"` vs `signcolumn="yes"`)
- **Cleaned `rose-pine.lua`**: all opts were gruvbox-style keys that rose-pine ignores; stripped to minimal spec with only `styles.transparency`
- **Cleaned `gruvbox.lua`**: removed invalid opts including `colorscheme` key (not a gruvbox opt)
- **Cleaned `user.lua`**: removed LuaSnip `javascript→javascriptreact` boilerplate, removed autopairs rules with `"xxx"`/`"xx"` placeholder conditions

- **Fixed `render-markdown.lua`**: wrong dependency `nvim-mini/mini.nvim` → `echasnovski/mini.nvim`
- **`lazy_setup.lua`**: added `rocks = { hererocks = false }` — suppresses luarocks ❌ in checkhealth (no plugins use luarocks; confirmed by checkhealth output)
- **`lazy_setup.lua`**: removed verbose comments from AstroNvim opts (self-explanatory fields)

### checkhealth notes (live config, 2026-03-18)
All remaining warnings/errors are pre-existing, not caused by our changes:
- `lazygit`, `node`, `gdu`, `btm` not installed — all flagged Optional, no action needed
- snacks image/input/picker errors — missing optional tools (imagemagick, gs, mmdc) or headless-mode artifacts
- treesitter: `tree-sitter` CLI only needed for TSInstallFromGrammar, not normal use

### Still to consider
- Add `pyright`, `clangd`, `rust-analyzer` to `mason.lua` `ensure_installed` (currently only `lua-language-server` auto-installs)
- Add `cpp`, `markdown`, `bash`, `toml` to treesitter `ensure_installed` (many already installed by AstroNvim defaults)
- README TODOs: floating Python REPL (`:terminal python3` in a float, no new plugin needed), snippets (LuaSnip already present), emoji picker (`telescope-emoji.nvim`)
- Note: `~/.config/nvim` is a separate git repo — deploy dotfiles changes manually with `rsync -av --exclude='.git' ~/code/github.com/temataro/dotfiles/nvim/ ~/.config/nvim/`

## Session 2 — New-laptop responsiveness rehaul (2026-07-29)

Machine: ASUS Vivobook S16 S5606CA (Core Ultra 9 285H "Arrow Lake-H", 2880x1800@120 OLED), Ubuntu 25.04, X11 + i3 + picom. Felt sluggish vs the old Arch+i3 laptop. Probes showed hardware/power already perfect (EPP + platform profile + PPD all `performance`, turbo on). Real causes → fixes:

- **Panel at 60Hz** with 120Hz available → i3 config now runs `xrandr --output eDP-1 --rate 120` at startup
- **Keyboard autorepeat at X defaults** (660ms/25cps) → i3 config now runs `xset r rate 250 50`
- **picom latency**: fading on (i3 workspace switch unmaps/remaps windows = ~120ms fade per switch), `inactive-opacity 0.92` + dual_kawase = constant blur of most of the 5MP frame → fading off, inactive-opacity 1.0, `unredir-if-possible` on. Blur kept (now only hits the floating kitty). Old values kept as comments for re-enable.
- **kitty**: `input_delay 0`, `repaint_delay 2` (defaults stacked ~13ms per keystroke)
- **i915 PSR2 selective-fetch bug** on ARL OLED — kernel log `Selective fetch area calculation failed in pipe A` (RH bug 2467676; still unfixed in kernels ≥6.16). Mitigation: kernel args `i915.enable_psr=0 i915.enable_panel_replay=0`; live test without reboot: `echo 0 | sudo tee /sys/kernel/debug/dri/0/i915_edp_psr_debug`
- **Snap apps** (firefox, chromium, telegram-desktop, thunderbird, and nvim!) explain slow app launches vs native pacman on old laptop. De-snap still pending.

S5606CA quirks (sourced): asus_nb_wmi WiFi soft-block fixed in kernel 6.15 (HWE bump worthwhile); RGB keyboard is HID LampArray (ITE5570) — standard asus-wmi tools can't drive it; Right Ctrl is a hardwired Copilot key firing a `leftmeta+leftshift+f23` chord.

**Copilot key remap (keyd):** xev capture proved this unit *sustains* the chord while held (many units only tap it), so `keyd.conf` binds `leftmeta+leftshift+f23 = rightcontrol` — a true held Right Ctrl with the fake mods swallowed (keyd ≥2.4.3 chords; Ubuntu 25.04 ships 2.5.0). Same file carries capslock→ctrl and f4→5 (broken 5 key on one keyboard); the `setxkbmap ctrl:nocaps` line was removed from the i3 config — keyd owns all key remaps now (and works in TTYs, unlike X-level remaps). Install: `sudo apt install -y keyd && sudo mkdir -p /etc/keyd && sudo cp keyd.conf /etc/keyd/default.conf && sudo systemctl restart keyd && sudo systemctl enable keyd`. Ubuntu renames the CLI binary to `keyd.rvaiya` (`/usr/bin/keyd.rvaiya`) — `keyd reload`/`keyd monitor` from upstream docs won't resolve unless symlinked. Panic chord if input ever bricks: Backspace+Escape+Enter.
