-- Formatting, on save and on demand.
--
-- Every binary below is a system install: stylua, prettier, shfmt and
-- clang-format from brew, ruff from ~/.local/bin, jq from the system. Nothing
-- here installs tools, and a formatter whose binary is missing does nothing
-- and says nothing, so tests/format.lua checks the PATH as well as the config.
return {
	"stevearc/conform.nvim",
	event = "BufWritePre",
	cmd = "ConformInfo",

	keys = {
		{
			"<leader>lf",
			function()
				require("conform").format({ async = true, lsp_format = "fallback" })
			end,
			mode = { "n", "v" },
			desc = "Format buffer",
		},
		{
			"<leader>uf",
			function()
				vim.g.disable_autoformat = not vim.g.disable_autoformat
				vim.notify("format on save " .. (vim.g.disable_autoformat and "off" or "on"))
			end,
			desc = "Toggle format on save",
		},
	},

	opts = {
		formatters_by_ft = {
			c = { "clang_format" },
			cpp = { "clang_format" },
			lua = { "stylua" },
			python = { "ruff_fix", "ruff_format" },
			json = { "jq" },
			sh = { "shfmt" },

			-- prettier, not mdformat. prettier aligns the pipes of a markdown
			-- table to the widest cell in each column, which is the reason a
			-- formatter is here at all, and it leaves $...$ untouched so a
			-- formatted note keeps its maths.
			markdown = { "prettier" },

			-- Trim trailing whitespace on any filetype with no formatter.
			["_"] = { "trim_whitespace" },
		},

		formatters = {
			-- conform's ruff_fix runs `ruff check --fix`, and F401 (unused
			-- import) is fixable by default, so every save deleted imports not
			-- referenced yet. That is wrong while a file is being written. The
			-- ruff server still reports the unused import as a diagnostic.
			--
			-- args is replaced wholesale rather than using prepend_args,
			-- because prepend_args would insert before the "check" subcommand
			-- and produce `ruff --ignore F401 check`, which is not valid.
			ruff_fix = {
				args = {
					"check",
					"--fix",
					"--ignore",
					"F401",
					"--force-exclude",
					"--exit-zero",
					"--no-cache",
					"--stdin-filename",
					"$FILENAME",
					"-",
				},
			},

			prettier = {
				-- Never reflow a paragraph. Soft wrap does the wrapping on
				-- screen, so one paragraph stays on one line and a one-word
				-- edit stays a one-word diff. Without this, prettier rewraps
				-- at 80 and every save rewrites lines you did not touch.
				prepend_args = { "--prose-wrap", "preserve" },
			},
		},

		default_format_opts = { lsp_format = "fallback" },

		format_on_save = function(bufnr)
			if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
				return
			end

			-- prettier is a Node program and pays for a cold interpreter start
			-- on the first markdown save of a session. That start alone takes
			-- longer than 1000ms, and conform answers a timeout by writing the
			-- file unformatted with only a line in :messages to say so.
			local timeout = vim.bo[bufnr].filetype == "markdown" and 3000 or 1000

			return { timeout_ms = timeout, lsp_format = "fallback" }
		end,
	},
}
