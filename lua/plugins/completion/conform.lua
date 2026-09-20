vim.pack.add({
	{ src = "https://github.com/stevearc/conform.nvim", name = "conform" },
	{ src = "https://github.com/mfussenegger/nvim-lint", name = "lint" },
})

require("conform").setup({
	formatters_by_ft = {
		c = { "clang-format" },
		cpp = { "clang-format" },
		lua = { "stylua" },
		python = { "ruff_format" },
	},
	format_on_save = true,
	undojoin = true,
})

local lint = require("lint")

-- Only show diagnostics close to the cursor
vim.diagnostic.config({
	virtual_text = {
		spacing = 4,
		prefix = function(diagnostic)
			local icons = {
				[vim.diagnostic.severity.ERROR] = " ",
				[vim.diagnostic.severity.WARN] = "󰉀 ",
				[vim.diagnostic.severity.INFO] = " ",
				[vim.diagnostic.severity.HINT] = "󰌵 ",
			}
			return icons[diagnostic.severity] or ""
		end,
	},
	signs = false,
	underline = true,
	update_in_insert = false,
})

-- Auto-run the linter only for the configured filetypes
vim.api.nvim_create_autocmd("BufWritePost", {
	callback = function()
		local ft = vim.bo.filetype
		if lint.linters_by_ft[ft] then
			lint.try_lint()
		end
	end,
})
