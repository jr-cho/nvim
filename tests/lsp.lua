local t = require("testkit")

t.run(function()
	-- Servers this config enables.
	for _, name in ipairs({ "clangd", "lua_ls", "pyright", "ruff" }) do
		t.check(name .. " enabled", vim.lsp.is_enabled(name), true)
		t.truthy(name .. " has a config", vim.lsp.config[name] ~= nil)
		t.truthy(name .. " names a command", vim.lsp.config[name] and vim.lsp.config[name].cmd ~= nil)
	end

	-- Every server's binary must resolve. A config for a server that is not
	-- installed fails at attach time with a message that reads like a broken
	-- language server rather than a missing program.
	local bins = {
		clangd = "clangd",
		lua_ls = "lua-language-server",
		pyright = "pyright-langserver",
		ruff = "ruff",
	}
	for name, bin in pairs(bins) do
		t.check(name .. " binary on PATH", vim.fn.executable(bin), 1)
	end

	-- ruff must not answer hover, so pyright owns K alone and one keypress does
	-- not stack two windows.
	t.truthy("ruff disables hover", vim.lsp.config.ruff and vim.lsp.config.ruff.on_attach ~= nil)

	-- Diagnostics.
	local cfg = vim.diagnostic.config()
	t.check("virtual text off", cfg.virtual_text, false)
	t.truthy("virtual lines on current line", cfg.virtual_lines ~= nil and cfg.virtual_lines ~= false)
	t.truthy("severity sorted", cfg.severity_sort)

	-- The LSP keymap table. One prefix.
	local subs = { "r", "a", "d", "D", "i", "t", "R", "o", "f", "s", "h" }
	for _, sub in ipairs(subs) do
		local leader = vim.fn.maparg("<leader>l" .. sub, "n", false, true)
		t.truthy("<leader>l" .. sub .. " is mapped", leader.callback ~= nil or leader.rhs ~= nil)
	end

	-- <D-l> must stay unmapped, and this is a regression guard rather than a
	-- style preference.
	--
	-- Ghostty does not forward Command to the application: pressing Cmd+L
	-- delivers a bare "l". A <D-l> mapping therefore never matches, and the
	-- keys fall through as normal-mode commands with the leading "l" as a
	-- cursor move. Cmd+L r replaces a character, Cmd+L a enters insert mode,
	-- and Cmd+L D deletes to the end of the line. The binding silently edited
	-- the buffer every time it "failed".
	for _, sub in ipairs(subs) do
		local m = vim.fn.maparg("<D-l>" .. sub, "n", false, true)
		t.check("<D-l>" .. sub .. " is NOT mapped", m.callback == nil and m.rhs == nil, true)
	end
end)
