vim.pack.add({ { src = "https://github.com/folke/which-key.nvim", name = "whichkey" } })

require("which-key").setup({
	-- "modern" is the rounded, titled popup, sitting at the bottom of the
	-- screen and centred across it.
	preset = "modern",

	-- Wait before the popup appears. Separate from timeoutlen, which is how
	-- long Neovim waits for the next key of a mapping. A long timeoutlen and a
	-- short delay is the pair worth having: plenty of time to finish typing,
	-- hints quickly when you pause.
	delay = 250,

	win = {
		-- row = -1 anchors to the bottom. col = 0.5 centres it across the
		-- width. A fraction would place the top edge instead, so 0.5 there
		-- would put the popup in the middle of the screen, over the code you
		-- are looking at.
		row = -1,
		col = 0.5,
		width = { min = 40, max = 0.8 },
		height = { min = 4, max = 0.7 },
		border = "rounded",
		padding = { 1, 2 },
		title = true,
		title_pos = "center",
	},

	layout = {
		width = { min = 22 },
		spacing = 3,
	},

	-- Group labels, from lua/keygroups.lua. which-key empties this table
	-- during setup, so the copy is what keeps the original readable.
	spec = vim.deepcopy(require("keygroups")),
})
