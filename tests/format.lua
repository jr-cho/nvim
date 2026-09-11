local t = require("testkit")

t.run(function()
	local conform = require("conform")

	local expected = {
		c = "clang_format",
		cpp = "clang_format",
		lua = "stylua",
		python = "ruff_format",
		markdown = "prettier",
		json = "jq",
		sh = "shfmt",
	}
	for ft, formatter in pairs(expected) do
		local list = conform.formatters_by_ft[ft]
		t.truthy(ft .. " formats with " .. formatter, list and vim.tbl_contains(list, formatter))
	end

	-- A formatter whose binary is missing does nothing and says nothing. The
	-- file saves unformatted and the only trace is a line in :messages.
	for _, bin in ipairs({ "clang-format", "stylua", "ruff", "prettier", "jq", "shfmt" }) do
		t.check(bin .. " on PATH", vim.fn.executable(bin), 1)
	end

	-- ruff_fix must not delete an import you have not used yet. F401 is
	-- fixable by default, so every save removed imports mid-edit.
	local args = conform.formatters.ruff_fix.args
	t.truthy("ruff_fix ignores F401", vim.tbl_contains(args, "F401"))

	-- prettier must not reflow a paragraph. Soft wrap does the wrapping on
	-- screen, so one paragraph stays one line and a one-word edit stays a
	-- one-word diff.
	t.truthy("prettier preserves prose wrap", vim.tbl_contains(conform.formatters.prettier.prepend_args, "preserve"))

	-- prettier is a Node program and pays a cold interpreter start on the
	-- first markdown save. At the 1000ms used elsewhere that start times out
	-- and conform writes the file unformatted.
	--
	-- format_on_save is a field of the lazy spec's opts table, not a function
	-- on the conform module. Reading it off require("conform") returns nil.
	local opts = require("lazy.core.config").plugins["conform.nvim"].opts
	vim.cmd("edit /tmp/fmt-test.md")
	t.check("markdown save timeout", opts.format_on_save(vim.api.nvim_get_current_buf()).timeout_ms, 3000)
	vim.cmd("edit /tmp/fmt-test.lua")
	t.check("other filetypes keep 1000ms", opts.format_on_save(vim.api.nvim_get_current_buf()).timeout_ms, 1000)
	vim.fn.delete("/tmp/fmt-test.md")
	vim.fn.delete("/tmp/fmt-test.lua")

	t.truthy("<leader>uf toggles format on save", vim.fn.maparg("<leader>uf", "n", false, true).callback ~= nil)
	t.truthy("<leader>lf formats on demand", vim.fn.maparg("<leader>lf", "n", false, true).callback ~= nil)
end)
