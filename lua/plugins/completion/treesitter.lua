-- The main branch, not the default master branch. install() and the
-- vim.treesitter.start() handoff below are the main branch API.
vim.pack.add({
	{ src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main", name = "treesitter" },
})

-- Neovim itself ships parsers for lua, markdown, query, vim and vimdoc, so
-- this list is the languages it does not cover.
require("nvim-treesitter").install({ "c", "cpp", "python" })

-- The main branch does not start highlighting on its own.
vim.api.nvim_create_autocmd("FileType", {
	callback = function(args)
		pcall(vim.treesitter.start, args.buf)
	end,
})
