-- Cursor-in-math test, used to gate the maths snippets in snippets/tex.lua.
--
-- vimtex ships vimtex#syntax#in_mathzone(), but that function reads vim's own
-- syntax state, and plugins/vimtex.lua sets vimtex_syntax_enabled = 0 so
-- treesitter can own highlighting. The answer therefore has to come from the
-- parse tree instead.
--
-- The same test answers for markdown. The markdown_inline grammar wraps `$x$`
-- in a latex_block node and injects the latex parser into it, so a markdown
-- buffer grows the same inline_formula and displayed_equation nodes a .tex
-- buffer has. Reading the injected tree is what makes every maths snippet in
-- snippets/tex.lua work unchanged inside a note.

local M = {}

-- Every node in the latex grammar that means "the cursor is typing maths".
local MATH_NODES = {
	inline_formula = true, -- $x$ and \(x\)
	displayed_equation = true, -- $$x$$ and \[x\]
	math_environment = true, -- equation, align, gather, ...
}

-- Every node that means "the cursor is inside code, not prose".
--
-- This exists because `mk` and `dm` fire in text rather than in maths, and text
-- includes a code block. Without this test, typing a variable named mk in a
-- fenced block rewrote it as $$, and the note then held broken code.
local CODE_NODES = {
	-- markdown
	fenced_code_block = true,
	code_fence_content = true,
	indented_code_block = true,
	-- markdown_inline
	code_span = true,
	-- latex
	verbatim_environment = true,
}

-- The filetypes that can hold LaTeX maths. Anything else answers false without
-- touching a parser, so the test costs nothing in a Python or C buffer.
local MATH_FILETYPES = {
	tex = true,
	markdown = true,
}

-- The languages that count as prose here. Any other language under the cursor
-- means the cursor is inside a fenced block tagged with that language.
local PROSE_LANGS = {
	markdown = true,
	markdown_inline = true,
	latex = true,
}

-- The position the tests ask about.
--
-- The column is stepped back one character on purpose. A snippet fires with the
-- cursor just past the text it matched, and at the end of "$x$" that position
-- already belongs to the parent node. Asking about the character to the left
-- keeps the test inside the formula.
local function cursor_pos()
	local row, col = unpack(vim.api.nvim_win_get_cursor(0))
	return row - 1, math.max(col - 1, 0)
end

-- The parser for this buffer, re-parsed.
local function parsed()
	-- No language argument. The parser for a .tex buffer is latex and the
	-- parser for a .md buffer is markdown, and naming latex here would make the
	-- markdown case ask the wrong grammar for a tree it does not own.
	local parser = vim.treesitter.get_parser(0, nil, { error = false })
	if not parser then
		return nil
	end
	-- The buffer changed on the keystroke that triggered this snippet, so the
	-- tree is one edit stale until it is re-parsed. `true` re-parses every
	-- injected tree as well as the outer one.
	parser:parse(true)
	return parser
end

-- The treesitter node under the cursor.
--
-- ignore_injections decides which tree answers. The maths test needs the
-- injected tree, because markdown holds its formulas in an injected latex tree.
-- The code test needs the outer tree, because a fenced block injects the block's
-- own language and that tree's root is the block, not the document.
local function node_at_cursor(ignore_injections)
	if not parsed() then
		return nil
	end
	local row, col = cursor_pos()
	return vim.treesitter.get_node({
		pos = { row, col },
		ignore_injections = ignore_injections or false,
	})
end

-- True when any node from the cursor up to the root is in the given set.
local function ancestor_in(node, set)
	while node do
		if set[node:type()] then
			return true
		end
		node = node:parent()
	end
	return false
end

-- True when the cursor sits in a code block, a code fence or a code span.
--
-- Three cases, and they need two different questions.
--
-- 1. A fence tagged with a language injects that language's parser, and the
--    node chain from the cursor then ends at that tree's own root. Walking it
--    never reaches markdown's fenced_code_block, so the chain says nothing.
--    The language owning the cursor is what answers this one.
-- 2. A fence with no tag injects nothing and stays in the markdown tree.
-- 3. An inline `code span` lives in markdown_inline, which is itself an
--    injection, so that one needs the injected tree.
function M.in_code()
	if not MATH_FILETYPES[vim.bo.filetype] then
		return false
	end

	local parser = parsed()
	if not parser then
		return false
	end

	local row, col = cursor_pos()
	local tree = parser:language_for_range({ row, col, row, col })
	if tree and not PROSE_LANGS[tree:lang()] then
		return true
	end

	return ancestor_in(node_at_cursor(false), CODE_NODES)
		or ancestor_in(node_at_cursor(true), CODE_NODES)
end

-- True when the cursor sits inside maths.
function M.in_math()
	if not MATH_FILETYPES[vim.bo.filetype] then
		return false
	end
	return ancestor_in(node_at_cursor(false), MATH_NODES)
end

-- True in prose: not maths, and not code either.
--
-- Code has to be excluded by name. A fenced block is not a formula, so the
-- maths test alone calls it text, and `mk` would then rewrite a variable named
-- mk as $$ in the middle of a code sample.
--
-- Note the asymmetry. in_math() is false in a Python buffer, so in_text() is
-- true there. That is correct for how these two gate snippets: LuaSnip only
-- consults them from tex and markdown buffers in the first place.
function M.in_text()
	if not MATH_FILETYPES[vim.bo.filetype] then
		return true
	end

	return not M.in_math() and not M.in_code()
end

return M
