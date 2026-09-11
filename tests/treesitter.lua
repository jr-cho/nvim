local t = require("testkit")

t.run(function()
	-- latex, markdown and markdown_inline are not optional. util/tex.lua reads
	-- the parse tree to decide whether the cursor is inside maths, and every
	-- LaTeX snippet stops firing without them, silently.
	local required = {
		"c", "cpp", "python", "lua", "bash", "json",
		"markdown", "markdown_inline", "latex", "vim", "vimdoc",
	}
	--
	-- The assertion has to be `== true`. vim.treesitter.language.add returns
	-- nil for a parser it cannot find and never raises, so pcall succeeds
	-- either way and a check for "not false" passes on every language in the
	-- list whether or not it is installed.
	for _, lang in ipairs(required) do
		local ok, added = pcall(vim.treesitter.language.add, lang)
		t.check(lang .. " parser installed", ok and added == true, true)
	end

	-- Highlighting is on for a real buffer, not merely available.
	vim.cmd("edit /tmp/ts-test.lua")
	vim.api.nvim_buf_set_lines(0, 0, -1, false, { "local x = 1" })
	vim.bo.filetype = "lua"
	pcall(vim.treesitter.start)
	t.truthy("highlighter active for lua", vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()] ~= nil)

	-- markdown injects the latex parser into $...$, which is the mechanism the
	-- maths snippets rely on in Task 9.
	vim.cmd("edit /tmp/ts-test.md")
	vim.api.nvim_buf_set_lines(0, 0, -1, false, { "Inline $x + y$ here." })
	vim.bo.filetype = "markdown"
	local parser = vim.treesitter.get_parser(0, nil, { error = false })
	t.truthy("markdown parser resolves", parser ~= nil)
	if parser then
		parser:parse(true)
		local node = vim.treesitter.get_node({ pos = { 0, 9 }, ignore_injections = false })
		local found = false
		while node do
			if node:type() == "inline_formula" then
				found = true
				break
			end
			node = node:parent()
		end
		t.truthy("latex is injected into markdown maths", found)
	end

	vim.fn.delete("/tmp/ts-test.lua")
	vim.fn.delete("/tmp/ts-test.md")
end)
