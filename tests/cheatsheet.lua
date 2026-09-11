local t = require("testkit")

t.run(function()
	local cs = require("cheatsheet")

	t.truthy("<leader>? opens it", vim.fn.maparg("<leader>?", "n", false, true).callback ~= nil)
	t.truthy(":Cheatsheet exists", vim.api.nvim_get_commands({})["Cheatsheet"] ~= nil)

	vim.o.columns, vim.o.lines = 200, 50
	cs.open()
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	local text = table.concat(lines, "\n")

	-- Groups come from lua/keygroups.lua, the same list which-key names its
	-- prefixes with, so a new group appears in both without being added twice.
	for _, g in ipairs({ "FIND", "LSP", "GIT", "TERMINAL", "TEST", "NOTES" }) do
		t.truthy("lists the " .. g .. " group", text:find(g, 1, true) ~= nil)
	end

	-- Hand-curated non-leader keys.
	for _, k in ipairs({ "grn", "gsa", "K", "]h" }) do
		t.truthy("lists " .. k, text:find(k, 1, true) ~= nil)
	end

	t.truthy("shows a leader key", text:find("<leader>ff", 1, true) ~= nil)
	t.truthy("shows its description", text:find("Find files", 1, true) ~= nil)

	-- The sheet is curated, not a dump. Collecting every described mapping
	-- gave 319 entries: mini.bracketed alone contributes 102, and Neovim's own
	-- defaults arrive with descriptions like ":help &-default".
	t.truthy("stays curated", #lines < 60)
	t.truthy("is not empty", #lines > 15)
	t.check("no help-default noise", text:find("-default", 1, true), nil)

	-- Columns must balance. A sequential fill left every leftover group in the
	-- last column, and the sheet stayed the same height whether it had two
	-- columns or four.
	t.truthy("uses the width available", #lines < 35)

	local widest = 0
	for _, l in ipairs(lines) do
		widest = math.max(widest, vim.fn.strdisplaywidth(l))
	end
	t.truthy("never wider than the screen", widest <= vim.o.columns)

	t.truthy("q closes it", vim.fn.maparg("q", "n", false, true).buffer == 1)
end)
