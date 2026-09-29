-- File tree in a left sidebar, from snacks.nvim.
--
-- Only the explorer is enabled. Telescope stays the picker and mini keeps
-- editing and appearance, so no other snacks module turns on.
vim.pack.add({ { src = "https://github.com/folke/snacks.nvim", name = "snacks" } })

require("snacks").setup({
	explorer = {
		-- Opening a directory (nvim .) shows the tree instead of netrw.
		replace_netrw = true,
	},
	picker = {
		sources = {
			explorer = {
				hidden = true, -- dotfiles
				win = {
					list = {
						keys = {
							-- Same key as in the Telescope pickers. Tab marks
							-- several entries first.
							["<C-l>"] = { "claude_add", mode = { "n" } },
						},
					},
				},
				actions = {
					claude_add = function()
						vim.cmd("ClaudeCodeTreeAdd")
					end,
				},
			},
		},
	},
})

vim.keymap.set("n", "<leader>e", function()
	Snacks.explorer()
end, { noremap = true, silent = true, desc = "File explorer" })
