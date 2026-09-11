local t = require("testkit")

t.run(function()
	t.truthy("Snacks global exists", _G.Snacks ~= nil)

	-- Modules this config turns on.
	for _, m in ipairs({ "picker", "explorer", "terminal", "input", "notifier", "bigfile" }) do
		t.truthy("snacks." .. m .. " available", Snacks[m] ~= nil)
	end

	-- Terminals must be reached with focus(), not toggle(). toggle() asks only
	-- whether the buffer sits in a window, so clicking off a floating terminal
	-- and pressing the key again closes the terminal instead of returning to
	-- it. That was a real bug in the previous config.
	t.truthy("Snacks.terminal.focus exists", type(Snacks.terminal.focus) == "function")

	local tt = vim.fn.maparg("<leader>tt", "n", false, true)
	t.truthy("<leader>tt is mapped", tt.callback ~= nil)

	-- Three positions must be three terminals. Snacks keys a terminal by cmd,
	-- cwd, env and count, and position is not part of that key, so without a
	-- distinct count all three keys share one terminal and only move it.
	local code = vim.api.nvim_get_current_win()
	local seen = {}
	for _, key in ipairs({ "<leader>tt", "<leader>tv", "<leader>th" }) do
		vim.fn.maparg(key, "n", false, true).callback()
		seen[#seen + 1] = vim.api.nvim_get_current_buf()
		vim.api.nvim_set_current_win(code)
	end
	t.truthy("float and vertical differ", seen[1] ~= seen[2])
	t.truthy("vertical and horizontal differ", seen[2] ~= seen[3])
	t.truthy("float and horizontal differ", seen[1] ~= seen[3])

	-- Picker and explorer keys.
	for _, key in ipairs({ "<leader>ff", "<leader>fg", "<leader>fb", "<leader>e" }) do
		local m = vim.fn.maparg(key, "n", false, true)
		t.truthy(key .. " is mapped", m.callback ~= nil or m.rhs ~= nil)
	end

	-- One notifier and one indent guide, not two. mini.notify and
	-- mini.indentscope must stay off while snacks owns these.
	t.check("mini.notify is off", _G.MiniNotify, nil)
	t.check("mini.indentscope is off", _G.MiniIndentscope, nil)

	-- <C-d> must NOT be mapped in terminal mode. It is EOF in every shell and
	-- is how a terminal is normally closed. Mapping it to leave terminal mode
	-- stole the key and left `exit` as the only way out, while buying nothing:
	-- snacks binds <Esc><Esc> for that, and <C-\><C-n> still works.
	t.check("<C-d> reaches the shell", vim.fn.maparg("<C-d>", "t"), "")

	-- The ways out that should exist.
	for _, k in ipairs({ "<A-t>", "<A-v>", "<A-h>" }) do
		t.truthy(k .. " hides a terminal from inside", vim.fn.maparg(k, "t") ~= "")
	end

	-- Project-wide find and replace. The picker greps but cannot rewrite, and
	-- rewriting across a tree by hand through :cdo is the kind of thing an IDE
	-- is for.
	for _, key in ipairs({ "<leader>fs", "<leader>fS" }) do
		local m = vim.fn.maparg(key, "n", false, true)
		t.truthy(key .. " is mapped", m.callback ~= nil or m.rhs ~= nil)
	end
end)
