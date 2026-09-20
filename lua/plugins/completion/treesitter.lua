-- The main branch, not the default master branch. install() and the
-- vim.treesitter.start() handoff below are the main branch API.
vim.pack.add({
	{ src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main", name = "treesitter" },
})

require("nvim-treesitter").install({
	"bash",
	"c",
	"cpp",
	"html",
	"javascript",
	"json",
	"lua",
	"markdown",
	"markdown_inline",
	"python",
	"query",
	"regex",
	"tsx",
	"typescript",
	"vim",
	"yaml",
})

-- The main branch does not start highlighting on its own.
vim.api.nvim_create_autocmd("FileType", {
	callback = function(args)
		pcall(vim.treesitter.start, args.buf)
	end,
})
