local t = require("testkit")

t.run(function()
	-- Open a real file first.
	--
	-- number, relativenumber and signcolumn are window-local, and the start
	-- screen deliberately turns them off in its own buffer. With the dashboard
	-- focused these read as the dashboard's values, not the config's, and the
	-- test fails on settings that are perfectly correct everywhere else.
	vim.cmd("edit /tmp/editor-opts-test.lua")

	-- Indentation. Hard tabs everywhere; LaTeX and markdown override this in
	-- their own ftplugin because both formats care.
	t.check("expandtab off", vim.o.expandtab, false)
	t.check("shiftwidth", vim.o.shiftwidth, 2)
	t.check("tabstop", vim.o.tabstop, 2)

	-- Undo survives a restart. Nothing else is written beside the file.
	t.check("undofile on", vim.o.undofile, true)
	t.check("swapfile off", vim.o.swapfile, false)
	t.check("backup off", vim.o.backup, false)

	-- Search. No highlight left over after the search finishes.
	t.check("ignorecase", vim.o.ignorecase, true)
	t.check("smartcase", vim.o.smartcase, true)
	t.check("hlsearch off", vim.o.hlsearch, false)

	-- Display.
	t.check("number", vim.o.number, true)
	t.check("relativenumber", vim.o.relativenumber, true)
	t.check("wrap on", vim.o.wrap, true)
	t.check("linebreak on", vim.o.linebreak, true)
	t.check("scrolloff", vim.o.scrolloff, 8)
	t.check("winborder", vim.o.winborder, "rounded")
	t.check("signcolumn", vim.o.signcolumn, "yes")

	-- Mapping timeout. 400 was too short to finish <leader>tt at a normal
	-- typing pace. ttimeoutlen is a separate option governing terminal key
	-- codes and must stay low, or <Esc> gains real latency.
	t.check("timeoutlen", vim.o.timeoutlen, 1000)
	t.truthy("ttimeoutlen stays low", vim.o.ttimeoutlen <= 100)

	t.truthy("splitright", vim.o.splitright)
	t.truthy("splitbelow", vim.o.splitbelow)

	-- Autocommands.
	local function has(event, group)
		return #vim.api.nvim_get_autocmds({ event = event, group = group }) > 0
	end
	t.truthy("yank highlight", has("TextYankPost", "user_yank"))
	t.truthy("last position", has("BufReadPost", "user_lastpos"))
	t.truthy("mkdir on save", has("BufWritePre", "user_mkdir"))

	-- Keymaps that belong to no plugin.
	for _, k in ipairs({ "<leader>d", "]d", "[d", "<C-d>", "<C-u>", "n", "N" }) do
		t.truthy(k .. " is mapped", vim.fn.maparg(k, "n") ~= "" or vim.fn.maparg(k, "n", false, true).callback ~= nil)
	end

	-- j and k move by display line only when no count is given, so 5j still
	-- moves five real lines and macros behave as they did.
	t.truthy("j is an expr map", vim.fn.maparg("j", "n", false, true).expr == 1)
	t.truthy("k is an expr map", vim.fn.maparg("k", "n", false, true).expr == 1)

	vim.fn.delete("/tmp/editor-opts-test.lua")
end)
