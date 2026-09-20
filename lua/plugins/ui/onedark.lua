-- onedark, the real one.
--
-- This replaced mini.hues, which was the wrong tool. mini.hues generates a
-- palette from a background and a foreground, and feeding it onedark's two
-- base colours produces something onedark-adjacent rather than onedark: it
-- knows nothing about which syntax group should be which hue.
--
-- Measured before the swap, across eight treesitter groups:
--   @keyword   #abb2bf   the plain foreground. def, if, return, import, class
--                        all rendered grey.
--   @type      #abb2bf   also the foreground.
--   @function  #83b9e0   a washed-out version of onedark's #61afef.
--   @string    #8cc198   a washed-out version of onedark's #98c379.
-- Five distinct colours across eight groups, which is what made every buffer
-- look flat.
vim.pack.add({
	{ src = "https://github.com/navarasu/onedark.nvim", name = "onedark" },
	{ src = "https://github.com/tadaa/vimade", name = "vimade" },
})

require("onedark").setup({
	style = "dark",
	transparent = false,
	term_colors = true,

	code_style = {
		comments = "italic",
		keywords = "none",
		functions = "none",
		strings = "none",
		variables = "none",
	},

	-- The line number grey is onedark's own, dim enough that the numbers do
	-- not compete with the code. The cursor line number is onedark's purple,
	-- which marks the current line at a glance.
	highlights = {
		LineNr = { fg = "$grey" },
		CursorLineNr = { fg = "$purple", fmt = "bold" },
	},
})

require("onedark").load()

-- Dim the windows that are not focused.
require("vimade").setup({
	recipe = { "minimalist", { animate = true } },
	fadelevel = 0.8,
})
