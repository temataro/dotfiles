# My Neovim Configuration

Barebones Neovim configuration managed with `lazy.nvim`. Requires Neovim 0.11+.
Authored entirely using agentic AI with me as the Rick Rubin.

## Structure

- `init.lua` sets leaders, loads the ported Vim config, loads plugins, then runs `polish.lua`.
- `lua/config/vimrc.lua` is the Lua port of the relevant `~/.vimrc` settings, keymaps, highlights, and autocmds.
- `lua/config/transparency.lua` strips backgrounds from core highlight groups so the terminal shows through, and keeps doing so across colorscheme switches.
- `lua/polish.lua` keeps the Neovim-specific options and keymaps that should run last.
- `lua/plugins/` contains one spec file per plugin.

## Plugins

- `rose-pine/neovim` is the active theme (`rose-pine-main`, transparent background).
- `ellisonleao/gruvbox.nvim` and `projekt0n/github-nvim-theme` are kept as optional themes.
- `nvim-lualine/lualine.nvim` draws the statusline and a buffer list in the tabline.
- `nvim-tree/nvim-web-devicons` provides filetype icons (tree, telescope, lualine, aerial).
- `nvim-tree/nvim-tree.lua` provides the file explorer sidebar (with git status).
- `stevearc/aerial.nvim` provides the symbol (functions/variables) sidebar.
- `lewis6991/gitsigns.nvim` shows git chunk indicators and hunk actions under `<Leader>g`.
- `nvim-telescope/telescope.nvim` (+fzf-native) provides pickers under `<Leader>f`.
- `echasnovski/mini.comment` provides comment toggling on `<Leader>/`.
- Mason + native `vim.lsp` config: `lua_ls`, `clangd` (mason), `ruff`, `jedi-language-server` (uv tools, enabled when on PATH).
- `hrsh7th/nvim-cmp` + LuaSnip for completion and snippets.
- `nvimdev/dashboard-nvim` + `milli.nvim` for the animated start screen.
- `sudormrfbin/cheatsheet.nvim` (+ telescope/plenary) provides the searchable cheatsheet.
- `folke/which-key.nvim` shows keymap hints (helix preset).

## Keymaps

- `<Leader>s` toggles the symbol sidebar (aerial.nvim); `<Leader>a` toggles it without focusing.
- `<Leader>c` closes current buffer.
- `<Leader>q` quits nvim.
- `<Leader>w` writes current file.
- `<Leader>e` toggles the file explorer sidebar.
- `<Leader>/` toggles comments (normal: current line, visual: selection).
- `gc` strips trailing whitespace.
- `<C-K>` runs the existing clang-format script mapping.
- `<C-b>` runs `uv tool run black %` on Python and `clang-format -i %` on C/C++.
- Visual `J`/`K` move selected lines.
- Normal `J` joins without moving the cursor.
- `n`/`N` center search results.
- Git hunk actions under `<Leader>g` (stage/reset/preview/blame/diff), `]c`/`[c` jump hunks.
- Buffer switching with `<C-l>`/`<C-j>` or `<Leader>L`/`<Leader>H`; open buffers are listed in the tabline.
- Telescope: `<Leader>ff` files, `<Leader>fg` grep, `<Leader>fb` buffers, `<Leader>fh` help, `<Leader>fr` recent, `<Leader>fw` word, `<Leader>fs` fuzzy-find in buffer.
- LSP (buffer-local): `gd`/`gD`/`gr`/`gi`/`gy` navigation, `K` hover, `<Leader>la` code action, `<Leader>lr` rename, `<Leader>ld` diagnostic float, `<Leader>ls` symbols.
- `<Leader>?` opens the cheatsheet.

## TODOs

## Notes

- This config no longer sources `vimrc.vim` or `~/.vimrc`; the relevant behavior has been ported to Lua.
- Lazy plugin cloning uses `https://github.com:443/...` to avoid the repo's Git URL rewrite from HTTPS to SSH.
- System clipboard yanks use `clipboard=unnamedplus`; install `xclip` so Neovim can copy to the desktop clipboard.
- Backgrounds are transparent via `config/transparency.lua`, not a black `Normal` override; the terminal theme decides what shows through.
- Floats use rounded borders globally via `winborder` (nvim 0.11+).
