local t = require("testkit")

t.run(function()
	vim.o.columns = 200
	vim.cmd("edit lua/options.lua")

	local function render()
		return vim.api.nvim_eval_statusline(vim.o.statusline, { winid = 0, maxwidth = 200 }).str
	end

	local s = render()

	-- The file name, not its path. mini.statusline's own section shows a path
	-- relative to the working directory, which is still most of a line inside a
	-- nested source tree.
	t.truthy("shows the file name", s:find("options.lua", 1, true) ~= nil)
	t.check("shows no directory path", s:find("lua/options.lua", 1, true), nil)
	t.check("shows no absolute path", s:find("/Users", 1, true), nil)

	-- The defaults this replaces. Encoding and byte size are the same on every
	-- file opened here and are never the thing being looked for.
	t.check("no file encoding", s:find("utf-8", 1, true), nil)
	t.check("no byte size", s:find("KiB", 1, true), nil)

	-- Mode, uppercase, at the left.
	t.truthy("shows the mode in caps", s:find("NORMAL", 1, true) ~= nil)

	-- Modified marker.
	vim.bo.modified = true
	t.truthy("marks a modified buffer", render():find("●", 1, true) ~= nil)
	vim.bo.modified = false
	t.check("unmarked when unmodified", render():find("●", 1, true), nil)

	-- Location, on the right.
	t.truthy("shows line and column", render():match("%d+:%d") ~= nil)

	-- An inactive window shows only the name. Anything else is a second
	-- statusline competing with the one being worked in.
	local inactive = require("statusline").inactive()
	t.truthy("inactive shows the name", inactive:find("options.lua", 1, true) ~= nil)
	t.check("inactive shows no mode", inactive:find("NORMAL", 1, true), nil)

	-- Tabline.
	t.truthy("tabline is mini's", vim.o.tabline:find("MiniTabline", 1, true) ~= nil)
	t.check("tab count sits on the right", MiniTabline.config.tabpage_section, "right")
	t.truthy("tabline shows icons", MiniTabline.config.show_icons)
end)
