-- Running tests from the editor.
--
-- Under <leader>T, capitalised, because <leader>t is the terminal prefix. A
-- lowercase collision would make both prefixes wait out timeoutlen before
-- either could fire, which is exactly the sluggishness that raising timeoutlen
-- to 1000 would otherwise have introduced.
return {
	"nvim-neotest/neotest",

	dependencies = {
		"nvim-neotest/nvim-nio",
		"nvim-lua/plenary.nvim",
		"nvim-treesitter/nvim-treesitter",
		"nvim-neotest/neotest-python",
	},

	keys = {
		{ "<leader>Tt", function() require("neotest").run.run() end, desc = "Test nearest" },
		{ "<leader>Tf", function() require("neotest").run.run(vim.fn.expand("%")) end, desc = "Test file" },
		{ "<leader>Ts", function() require("neotest").summary.toggle() end, desc = "Test summary" },
		{ "<leader>To", function() require("neotest").output.open({ enter = true }) end, desc = "Test output" },
		{
			"<leader>Td",
			function()
				require("neotest").run.run({ strategy = "dap" })
			end,
			desc = "Debug nearest test",
		},
		{ "<leader>TS", function() require("neotest").run.stop() end, desc = "Stop test run" },
	},

	config = function()
		require("neotest").setup({
			adapters = {
				-- pytest and unittest. The runner is discovered from the
				-- project rather than named here.
				--
				-- justMyCode = false so the dap strategy can step into library
				-- code. Stopping at the boundary of your own source is the
				-- wrong default when the bug is in how you called something.
				require("neotest-python")({ dap = { justMyCode = false } }),
			},

			-- Failures appear inline, in the same virtual_lines style
			-- lua/lsp.lua configures for the language servers, so a failing
			-- assertion reads like any other diagnostic.
			diagnostic = { enabled = true },

			-- Do not steal the window on every run. <leader>To opens the
			-- output when you want it.
			output = { open_on_run = false },
		})
	end,
}
