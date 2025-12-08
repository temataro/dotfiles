return {
	"rose-pine/neovim",
  ---@type AstroUIOpts
  opts = {
    colorscheme = "rose-pine-main",
    terminal_colors = true, -- add neovim terminal colors
    undercurl = true,
    underline = true,
    bold = true,
    italic = {
      strings = false,
      emphasis = true,
      comments = false,
      operators = false,
      folds = false,
    },
    strikethrough = true,
    invert_selection = true,
    invert_signs = true,
    invert_tabline = true,
    invert_intend_guides = true,
    inverse = true, -- invert background for search, diffs, statuslines and errors
    contrast = "", -- can be "hard", "soft" or empty string
    overrides = {},
    dim_inactive = true,
    transparent_mode = true,
  },
	config = function()
		vim.cmd("colorscheme rose-pine-main")
	end
}
