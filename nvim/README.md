# My Neovim Configuration
---

Hello. Neovim finally does what I want it to how I want it to.

Broken windows fixed!
Moved over all conveniences from `~/.vimrc` file by sourcing it from
within Neovim.

Simply added extras into polish.lua from a baseline template of astro.nvim
along with previous vimrc configs for style and QoL.

## Requirements:
    Neovim >= v0.10.0
    You'll need to install lazyvim from a template and then `rm -fr
    ~/.config/nvim && rm -fr ~/.local/{share/nvim,state/nvim}`... probably.
    (To be clarified, but this procedure works for now)

Capabilities:
  - Code formatting with clang-format
  - Full blackout mode for desert256 theme
  - A bottom status bar that looks quite nice (lualine)
  - A toggleable sidebar for quick directory exploration
  - A fuzzy finder popup window for searching within files and directories
  - LSPs with help menus when you press `<C-K>`
    - * caveat: you have to setup a clang format type autoformatter for nvim
        to reach for
  - Syntax highlighting with treesitter
  - Decoupled and localized settings and plugin configurations organized into `./lua/{plugins,settings}`
  - Garbage collect: Highlight and remove trailing whitespace characters
  - Spell check
  - Highlight past 80 characters
  - Autocomplete file directories etc with cmp plugin
  - Leader key help map so I can show others how things work and get them to use it
  - LSP keyword view
  - File tabs that can be quickly toggled through using hjkl
  - Auto comment/uncomment leader key keymap
  - Pop up Python interpreter
  - Pop up terminal window

TODOs:
  - Floating Python interpreter for quick numpy function help; etc
  - Floating C++ REPL program (TODO: Make C++ repl program for basic playground-ing)
  - Snippets for redundant code block generation: Quarto, Markdown (images, tables,...), Python, C, C++...
  - Emoji popup window

Happy travels, space cowboys!
