# My Neovim Configuration

Barebones Neovim configuration managed with `lazy.nvim`.
Authored entirely using GPT5.5 with me as the Rick Rubin.

## Structure

- `init.lua` sets leaders, loads the ported Vim config, loads plugins, then runs `polish.lua`.
- `lua/config/vimrc.lua` is the Lua port of the relevant `~/.vimrc` settings, keymaps, highlights, and autocmds.
- `lua/polish.lua` keeps the existing Neovim-specific options and keymaps that should run last.
- `lua/plugins/` contains only theme plugins and `nvim-tree`.

## Plugins

- `rose-pine/neovim` is the active theme, using `rose-pine-main` with a black `Normal` background.
- `ellisonleao/gruvbox.nvim` is kept as an optional theme.
- `projekt0n/github-nvim-theme` is kept as an optional theme.
- `nvim-tree/nvim-tree.lua` provides the file explorer sidebar.

## Keymaps

- `<Leader>e` toggles the file explorer sidebar.
- `gc` strips trailing whitespace.
- `<C-K>` runs the existing clang-format script mapping.
- `<C-b>` runs `uv tool run black %`.
- Visual `J`/`K` move selected lines.
- Normal `J` joins without moving the cursor.
- `n`/`N` center search results.

## Notes

- This config no longer sources `vimrc.vim` or `~/.vimrc`; the relevant behavior has been ported to Lua.
- Lazy plugin cloning uses `https://github.com:443/...` to avoid the repo's Git URL rewrite from HTTPS to SSH.
