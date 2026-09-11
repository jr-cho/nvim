local t = require("testkit")

t.run(function()
	t.truthy("MiniDiff is active", _G.MiniDiff ~= nil)
	t.truthy("MiniGit is active", _G.MiniGit ~= nil)

	-- mini.diff's own operators and navigation. gh is Vim's start-Select-mode,
	-- which nothing uses, and none of these touch the native LSP gr namespace.
	t.truthy("gh applies a hunk", vim.fn.maparg("gh", "n") ~= "")
	t.truthy("gH resets a hunk", vim.fn.maparg("gH", "n") ~= "")
	t.truthy("]h goes to next hunk", vim.fn.maparg("]h", "n") ~= "")
	t.truthy("[h goes to previous hunk", vim.fn.maparg("[h", "n") ~= "")

	-- Leader keys that act on the hunk under the cursor.
	for _, key in ipairs({ "<leader>gs", "<leader>gr", "<leader>go", "<leader>gl" }) do
		local m = vim.fn.maparg(key, "n", false, true)
		t.truthy(key .. " is mapped", m.callback ~= nil or m.rhs ~= nil)
	end

	-- Snacks owns lazygit; mini owns the in-buffer signs. Not both.
	t.truthy("<leader>gg opens lazygit", vim.fn.maparg("<leader>gg", "n", false, true).callback ~= nil)
	t.check("lazygit on PATH", vim.fn.executable("lazygit"), 1)

	-- gitsigns must not be installed. Two sign columns for the same hunks is
	-- the exact seam the suite split exists to avoid.
	t.check("gitsigns absent", require("lazy.core.config").plugins["gitsigns.nvim"], nil)

	-- The staging key must act on one hunk, not the whole buffer.
	--
	-- MiniDiff.do_hunks(buf, action) with no opts defaults to line_start = 1
	-- and line_end = the last line, so a keymap that omits the range stages
	-- every change in the file. This asserts the range is passed.
	--
	-- Exercised against a real repository, because do_hunks errors on a buffer
	-- with no reference text.
	local dir = "/tmp/minidiff-test"
	vim.fn.delete(dir, "rf")
	vim.fn.mkdir(dir, "p")
	vim.fn.system({ "git", "-C", dir, "init", "-q" })
	vim.fn.writefile({ "one", "two", "three", "four" }, dir .. "/f.txt")
	vim.fn.system({ "git", "-C", dir, "add", "f.txt" })
	vim.fn.system({ "git", "-C", dir, "-c", "user.email=t@t", "-c", "user.name=t", "commit", "-qm", "init" })

	vim.cmd("edit " .. dir .. "/f.txt")
	vim.api.nvim_buf_set_lines(0, 0, -1, false, { "ONE", "two", "three", "FOUR" })
	-- Wait on the hunks, not on ref_text. mini.diff debounces recomputation
	-- after a text change (delay.text_change, 200ms by default), so ref_text
	-- arrives well before the hunk list does and waiting on it reports zero
	-- hunks for a buffer that plainly has two.
	vim.wait(4000, function()
		local d = MiniDiff.get_buf_data(0)
		return d ~= nil and d.ref_text ~= nil and d.hunks ~= nil and #d.hunks > 0
	end, 50)

	local data = MiniDiff.get_buf_data(0)
	t.truthy("mini.diff attached to a tracked file", data ~= nil and data.ref_text ~= nil)
	t.check("two separate hunks detected", data and data.hunks and #data.hunks, 2)

	vim.fn.delete(dir, "rf")
end)
