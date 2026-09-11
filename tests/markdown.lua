local t = require("testkit")

t.run(function()
	local tex = require("util.tex")

	vim.cmd("edit /tmp/md-test.md")
	t.check("filetype of a new .md", vim.bo.filetype, "markdown")

	local function at(lines, row, col)
		vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
		vim.treesitter.get_parser(0, nil, { error = false }):parse(true)
		vim.api.nvim_win_set_cursor(0, { row, col })
	end

	-- markdown_inline wraps $x$ in a latex_block with the latex parser
	-- injected, so the same inline_formula node appears in a note as in a .tex
	-- file. That is what lets one snippet file serve both.
	at({ "Prose here.", "An inline formula $x + y$ sits here." }, 2, 22)
	t.check("markdown $...$ is math", tex.in_math(), true)
	at({ "Prose here.", "An inline formula $x + y$ sits here." }, 1, 5)
	t.check("markdown prose is text", tex.in_text(), true)

	-- Code must never be treated as prose. A fence tagged with a language
	-- injects that language's parser, so the node chain from the cursor never
	-- reaches markdown's fenced_code_block and an ancestor walk finds nothing.
	-- in_code asks which language owns the cursor for that case.
	at({ "```python", "x = 1", "```" }, 2, 1)
	t.check("tagged fence is code", tex.in_code(), true)
	at({ "```", "abc", "```" }, 2, 1)
	t.check("untagged fence is code", tex.in_code(), true)
	at({ "Text.", "", "    indented code", "" }, 3, 8)
	t.check("indented block is code", tex.in_code(), true)
	at({ "Use `xy` here." }, 1, 5)
	t.check("inline code span is code", tex.in_code(), true)
	at({ "Plain prose here." }, 1, 5)
	t.check("prose is not code", tex.in_code(), false)

	-- Buffer settings from after/ftplugin/markdown.lua.
	t.check("markdown spell", vim.opt_local.spell:get(), true)
	t.check("markdown expandtab", vim.opt_local.expandtab:get(), true)
	t.check("markdown textwidth", vim.opt_local.textwidth:get(), 0)
	t.truthy("gf finds .md", vim.tbl_contains(vim.opt_local.suffixesadd:get(), ".md"))

	-- Checkbox toggle, dashed and numbered.
	local toggle = vim.fn.maparg("<localleader>x", "n", false, true).callback
	t.truthy("checkbox map exists", toggle ~= nil)
	local function toggles(input, want)
		vim.api.nvim_buf_set_lines(0, 0, -1, false, { input })
		vim.api.nvim_win_set_cursor(0, { 1, 0 })
		pcall(toggle)
		return vim.api.nvim_get_current_line() == want
	end
	t.truthy("toggle - [ ]", toggles("- [ ] task", "- [x] task"))
	t.truthy("toggle - [X]", toggles("- [X] task", "- [ ] task"))
	t.truthy("toggle 1. [ ]", toggles("1. [ ] task", "1. [x] task"))
	t.truthy("toggle 2) [ ]", toggles("2) [ ] task", "2) [x] task"))
	t.truthy("toggle leaves prose alone", toggles("Some prose.", "Some prose."))

	-- The tex snippet file must reach a markdown buffer.
	t.truthy("markdown extends tex", vim.tbl_contains(require("luasnip").get_snippet_filetypes(), "tex"))

	-- Notes keys.
	for _, k in ipairs({ "<leader>nf", "<leader>ng", "<leader>nn" }) do
		t.truthy(k .. " is mapped", vim.fn.maparg(k, "n", false, true).callback ~= nil)
	end

	-- Grammar checking, narrowed to the two filetypes that hold prose. Its own
	-- default list names eighteen, including gitcommit, and this is a 257MB
	-- Java server.
	t.check("ltex is enabled", vim.lsp.is_enabled("ltex_plus"), true)
	t.check("ltex binary on PATH", vim.fn.executable("ltex-ls-plus"), 1)
	local ltex = vim.lsp.config.ltex_plus
	t.check("ltex filetype count", #ltex.filetypes, 2)
	t.truthy("ltex covers markdown", vim.tbl_contains(ltex.filetypes, "markdown"))
	t.truthy("ltex covers tex", vim.tbl_contains(ltex.filetypes, "tex"))

	-- Without these three handlers a word added through the code action is
	-- forgotten the moment Neovim closes.
	for _, h in ipairs({ "$/ltex/addToDictionary", "$/ltex/disableRules", "$/ltex/hideFalsePositives" }) do
		t.truthy("ltex persists " .. h, ltex.handlers[h] ~= nil)
	end

	-- A word added twice must be stored once. ltex sends the notification
	-- every time the code action is accepted, including on a word already in
	-- the file.
	local dict = vim.fn.stdpath("config") .. "/ltex/dictionary.txt"
	local saved = vim.fn.filereadable(dict) == 1 and vim.fn.readfile(dict) or nil
	vim.fn.delete(dict)
	local add = ltex.handlers["$/ltex/addToDictionary"]
	add(nil, { words = { ["en-US"] = { "eigenbasis" } } })
	add(nil, { words = { ["en-US"] = { "eigenbasis", "manifold" } } })
	t.check("dictionary does not repeat a word", #vim.fn.readfile(dict), 2)
	vim.fn.delete(dict)
	if saved then
		vim.fn.writefile(saved, dict)
	end

	vim.fn.delete("/tmp/md-test.md")
end)
