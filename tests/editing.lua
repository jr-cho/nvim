local t = require("testkit")

t.run(function()
	for _, g in ipairs({
		"MiniAi", "MiniSurround", "MiniOperators", "MiniMove",
		"MiniSplitjoin", "MiniPairs", "MiniBracketed", "MiniAlign",
	}) do
		t.truthy(g .. " is active", _G[g] ~= nil)
	end

	-- mini.clue must stay off. which-key does this now, and running both would
	-- put two popups on one keypress.
	t.check("mini.clue is off", _G.MiniClue, nil)

	-- mini.operators must not eat the native LSP keys.
	--
	-- Its default replace prefix is `gr`, which takes the whole gr namespace
	-- and removes grn, gra, grr, gri, grt and grx. Its default sort prefix is
	-- `gs`, which is where surround lives here, and its exchange prefix is
	-- `gx`, which is Neovim's open-the-URL-under-the-cursor.
	--
	-- This is the assertion that keeps them apart.
	local lsp_maps = {
		grn = "rename",
		gra = "code_action",
		grr = "references",
		gri = "implementation",
		grt = "type_definition",
		grx = "codelens",
		gO = "document_symbol",
	}
	for lhs, fn in pairs(lsp_maps) do
		local desc = vim.fn.maparg(lhs, "n", false, true).desc or ""
		t.truthy(lhs .. " is still " .. fn, desc:match("vim%.lsp") ~= nil)
	end

	-- The operators, on keys that collide with nothing.
	for _, k in ipairs({ "g=", "gX", "gM", "gR" }) do
		t.truthy(k .. " is an operator", vim.fn.maparg(k, "n"):match("MiniOperators") ~= nil)
	end

	-- gx stays Neovim's own. Opening a URL is worth more than a second
	-- exchange key, and sort is disabled because :sort already exists.
	t.truthy("gx is not an operator", vim.fn.maparg("gx", "n"):match("MiniOperators") == nil)

	-- Surround lives under gs so plain s stays free for the built-in
	-- substitute and for jump plugins.
	t.truthy("gsa adds a surround", vim.fn.maparg("gsa", "n") ~= "")
	t.truthy("gsd deletes a surround", vim.fn.maparg("gsd", "n") ~= "")
	t.truthy("gsr replaces a surround", vim.fn.maparg("gsr", "n") ~= "")

	-- mini.ai gives function and class textobjects from the parse tree.
	vim.cmd("edit /tmp/mini-ai-test.lua")
	vim.api.nvim_buf_set_lines(0, 0, -1, false, {
		"local function outer()",
		"  return 1",
		"end",
	})
	vim.bo.filetype = "lua"

	-- Start the parser and parse before querying. Opening a real file parses
	-- on render, but nothing has rendered here, so without this the tree is
	-- empty and the query matches nothing: mini.ai then reports "No textobject
	-- af found" and the failure looks like a missing query rather than an
	-- unparsed buffer.
	vim.treesitter.start(0, "lua")
	vim.treesitter.get_parser(0, "lua"):parse(true)
	vim.api.nvim_win_set_cursor(0, { 2, 2 })

	-- pcall, and assert the shape defensively. A treesitter textobject with no
	-- query does not fail cleanly. If this reports false, either the lua
	-- parser or nvim-treesitter-textobjects is missing.
	local ok, region = pcall(MiniAi.find_textobject, "a", "f")
	t.truthy("af finds the enclosing function", ok and type(region) == "table")
	if ok and type(region) == "table" and region.from and region.to then
		t.check("function starts on line 1", region.from.line, 1)
		t.check("function ends on line 3", region.to.line, 3)
	end
	vim.fn.delete("/tmp/mini-ai-test.lua")

	-- which-key, centred. It finds the keys under a prefix itself, but cannot
	-- infer what a prefix is called, so the group labels are declared.
	local wk = require("which-key.config")
	t.check("which-key preset", wk.preset, "modern")
	t.check("popup is centred horizontally", wk.win.col, 0.5)
	-- row = -1 anchors the popup to the bottom. A fraction places the top edge,
	-- so 0.5 would sit it in the middle of the screen over the code.
	t.check("popup sits at the bottom", wk.win.row, -1)
	t.check("popup has a border", wk.win.border, "rounded")

	-- delay is the wait before the popup appears and is separate from
	-- timeoutlen, the wait for the next key of a mapping. The popup should
	-- arrive well before the mapping times out.
	t.truthy("popup appears before the mapping times out", wk.delay < vim.o.timeoutlen)

	-- Read the labels from lua/keygroups.lua, not from which-key. which-key
	-- empties the spec table it is handed, and that is the same table lazy
	-- holds as the plugin's opts, so after setup both read as zero entries.
	-- whichkey.lua passes it a deep copy for that reason.
	local labelled = {}
	for _, spec in ipairs(require("keygroups")) do
		labelled[spec[1]] = spec.group
	end
	for _, p in ipairs({ "<leader>f", "<leader>l", "<leader>t", "<leader>g", "<leader>T", "gs" }) do
		t.truthy(p .. " has a group label", labelled[p] ~= nil)
	end
end)
