-- Set colorscheme and dark/transparent/blurred background for the themes we use
-- TODO: transparent
print("[DBG_TEM] Hello from ./lua/plugins/colors.lua")
function ColorThings(colors)
	blurBg = "none"
	backgroundColor = "#000000"

	color = color or "github_dark"
	vim.cmd.colorscheme(color)
	-- Now bg stuff
	vim.api.nvim_set_hl(0, "Normal",      { bg = backgroundColor })
	vim.api.nvim_set_hl(0, "NormalFloat", { bg = backgroundColor })
end


ColorThings('000000')
