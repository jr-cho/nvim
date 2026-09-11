-- Project-wide find and replace.
--
-- The picker greps but cannot rewrite. The alternative is building a quickfix
-- list and driving :cdo over it, which works and is unpleasant enough that in
-- practice nobody does it. grug-far shows the matches and the replacement side
-- by side and applies them in one step.
--
-- It shells out to ripgrep, which the picker already depends on.
return {
	"MagicDuck/grug-far.nvim",
	cmd = "GrugFar",

	opts = { headerMaxWidth = 80 },

	keys = {
		{
			"<leader>fs",
			function()
				require("grug-far").open({ transient = true })
			end,
			desc = "Search and replace (project)",
		},
		{
			"<leader>fS",
			function()
				require("grug-far").open({
					transient = true,
					prefills = { paths = vim.fn.expand("%") },
				})
			end,
			desc = "Search and replace (this file)",
		},
	},
}
