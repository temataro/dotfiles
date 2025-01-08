# My Neovim Configuration
---

Hello. Neovim finally does what I want it to how I want it to.

Broken windows fixed!
Moved over all conveniences from `~/.vimrc` file by sourcing it from
within Neovim.

**__NOTE:__** You will have to clone packer.nvim into ~/.local/share/nvim/<some
place> to get the plugins to work.
```
git clone --depth 1 https://github.com/wbthomason/packer.nvim\
 ~/.local/share/nvim/site/pack/packer/start/packer.nvim
```

Capabilities:
  - Code formatting with clang-format
  - Full blackout mode for desert256 theme
  - A bottom status bar that looks quite nice (lualine)
  - A toggleable sidebar for quick directory exploration
  - A fuzzy finder popup window for searching within files and directories
  - LSPs with help menus when you press `<C-K>`
  - Syntax highlighting with treesitter
  - Decoupled and localized settings and plugin configurations organized into `./lua/{plugins,settings}`
  - Garbage collect: Highlight and remove trailing whitespace characters
  - Spell check
  - Highlight past 80 characters

  Most of these already existed in the base `~/.vimrc` but now they're in
  Neovim!

TODOs:
  - Autocomplete file directories etc with cmp plugin
  - Leader key help map so I can show others how things work and get them to use it
  - LSP keyword view
  - Floating Python interpreter for quick numpy function help; etc
  - Floating C++ REPL program (TODO: Make C++ repl program for basic playground-ing)
  - File tabs that can be quickly toggled through using hjkl
  - Auto comment/uncomment leader key keymap
  - Snippets for redundant code block generation: Quarto, Markdown (images, tables,...), Python, C, C++...
  - Emoji popup window

Happy travels, space cowboys!
