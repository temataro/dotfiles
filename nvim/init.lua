-- *** === *** Load vim's vimrcs here *** === ***
local vimrc = vim.fn.stdpath("config") .. "/vimrc.vim"
vim.cmd.source(vimrc)
-- *** === ***        ^ __ ^          *** === ***


require('plugins.colors'); ColorThings("000000")
require('plugins.lualine')
require('plugins.undotree')
require('plugins.neotree')
require('plugins.lsp')
require('plugins.telescope')

require('settings.set')
require('settings.remap')
require('settings.autoreload')

-- Only required if you have packer configured as `opt`
vim.cmd [[packadd packer.nvim]]

return require('packer').startup(function(use)
  -- Packer can manage itself
  use 'wbthomason/packer.nvim'
  -- ***===*** TEM ***===***
  -- Everything below here is how we add new plugins/themes/tools
  -- 1. Telescope
  use {
	  'nvim-telescope/telescope.nvim', tag = '0.1.8',
	  -- or                            , branch = '0.1.x',
	  requires = { {'nvim-lua/plenary.nvim'} }
}

  -- 2. Themes
  -- 2.1 github nvim theme
use({
	'projekt0n/github-nvim-theme',
	config = function()
		require('github-theme').setup({
		  options = {
		    -- Compiled file's destination location
		    compile_path = vim.fn.stdpath('cache') .. '/github-theme',
		    compile_file_suffix = '_compiled', -- Compiled file suffix
		    hide_end_of_buffer = false, -- Hide the '~' character at the end of the buffer for a cleaner look
		    hide_nc_statusline = false, -- Override the underline style for non-active statuslines
		    transparent = false,       -- Disable setting bg (make neovim's background transparent)
		    terminal_colors = true,    -- Set terminal colors (vim.g.terminal_color_*) used in `:terminal`
		    dim_inactive = true,      -- Non focused panes set to alternative background
		    module_default = true,     -- Default enable value for modules
		    styles = {                 -- Style to be applied to different syntax groups
		      comments = 'NONE',       -- Value is any valid attr-list value `:help attr-list`
		      functions = 'NONE',
		      keywords = 'NONE',
		      variables = 'NONE',
		      conditionals = 'NONE',
		      constants = 'bold',
		      numbers = 'NONE',
		      operators = 'NONE',
		      strings = 'NONE',
		      types = 'NONE',
		    },
		    inverse = {                -- Inverse highlight for different types
		      match_paren = true,
		      visual = true,
		      search = false,
		    },
		    darken = {                 -- Darken floating windows and sidebar-like windows
		      floats = true,
		      sidebars = {
			enable = true,
			list = {},             -- Apply dark background to specific windows

		      },
		    },
		    modules = {                -- List of various plugins and additional options
		      -- ...
		    },
		  },
	})

		vim.cmd('colorscheme github_dark')
	end
})


  -- 3. Tree  Sitter
	use('nvim-treesitter/nvim-treesitter', { run = ':TSUpdate' })

  -- 4. Undo Tree
	use('mbbill/undotree')

  -- 5. LSP
	use('neovim/nvim-lspconfig')
	use('hrsh7th/nvim-cmp')
	use('hrsh7th/cmp-nvim-lsp')

  -- 6. LuaLine
  use {
      'nvim-lualine/lualine.nvim',
      requires = { 'nvim-tree/nvim-web-devicons', opt = true }
}

  -- 7. nvim-neo-tree
  use {
      "nvim-neo-tree/neo-tree.nvim",
      branch = "v3.x",
      requires = {
          "nvim-lua/plenary.nvim",
          "nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
          "MunifTanjim/nui.nvim",
          -- "3rd/image.nvim", -- Optional image support in preview window: See `# Preview Mode` for more information
          opt = true
      }
  }
end)
