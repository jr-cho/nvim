local t = require("testkit")

t.run(function()
	t.check("tex_flavor", vim.g.tex_flavor, "latex")

	-- vimtex must load eagerly. Inverse search from Skim calls back into a
	-- global command that has to exist before Skim runs, and ft-loading vimtex
	-- breaks that.
	local spec = require("lazy.core.config").plugins.vimtex
	-- Declared is not installed. lazy runs `init` for every spec at startup,
	-- lazy-loaded or not, so the vim.g.vimtex_* globals below are set even
	-- when the clone failed and nothing is on disk.
	t.truthy("vimtex is on disk", spec.dir and vim.uv.fs_stat(spec.dir) ~= nil)
	t.check("vimtex loads eagerly", spec.lazy, false)
	t.check("vimtex has no ft trigger", spec.ft, nil)
	t.check("vimtex syntax off", vim.g.vimtex_syntax_enabled, 0)
	t.check("vimtex view method", vim.g.vimtex_view_method, "skim")
	t.check("vimtex compiler", vim.g.vimtex_compiler_method, "latexmk")

	local tex = require("util.tex")

	-- A brand new .tex file must open as tex, not plaintex.
	vim.cmd("edit /tmp/tex-test.tex")
	t.check("filetype of a new .tex", vim.bo.filetype, "tex")

	local function at(lines, row, col)
		vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
		vim.treesitter.get_parser(0, nil, { error = false }):parse(true)
		vim.api.nvim_win_set_cursor(0, { row, col })
	end

	at({ "Ordinary prose.", "An inline formula $x + y$ sits here." }, 1, 5)
	t.check("prose is not math", tex.in_math(), false)
	t.check("prose is text", tex.in_text(), true)

	at({ "Ordinary prose.", "An inline formula $x + y$ sits here." }, 2, 22)
	t.check("inside $...$ is math", tex.in_math(), true)
	t.check("inside $...$ is not text", tex.in_text(), false)

	-- verbatim is this filetype's code block. mk fires in text, and a code
	-- block is text as far as the maths test goes, so without in_code typing a
	-- variable named mk inside verbatim rewrote it as $$.
	at({ "Text.", "\\begin{verbatim}", "mk", "\\end{verbatim}" }, 3, 1)
	t.check("verbatim is code", tex.in_code(), true)
	t.check("verbatim is not text", tex.in_text(), false)

	-- LaTeX commands under <leader>c as well as vimtex's <localleader>l.
	-- Buffer-local, so they exist here and nowhere else.
	for _, k in ipairs({ "<leader>cc", "<leader>cv", "<leader>ck", "<leader>ce", "<leader>ct" }) do
		local m = vim.fn.maparg(k, "n", false, true)
		t.truthy(k .. " is mapped in a tex buffer", m.rhs ~= nil or m.callback ~= nil)
		t.check(k .. " is buffer-local", m.buffer, 1)
	end

	-- vimtex's own prefix must still work; the Space keys are an addition.
	t.truthy("<localleader>ll still compiles", vim.fn.maparg("\\ll", "n") ~= "")

	vim.fn.delete("/tmp/tex-test.tex")

	-- <leader>c must mean nothing outside a tex buffer.
	vim.cmd("enew")
	vim.bo.filetype = "lua"
	t.check("<leader>cc is not global", vim.fn.maparg("<leader>cc", "n"), "")
end)
