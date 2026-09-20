-- LaTeX snippets.
--
-- Most of these expand the instant the trigger is typed, with no menu and no
-- confirm key. That only works because each one is gated on where the cursor
-- is: `mk` opens maths and so must fire in text, `//` builds a fraction and so
-- must fire in maths. util/tex.lua answers that question from the treesitter
-- parse tree.
--
-- ONE RULE WHEN ADDING A TRIGGER: no trigger may be a prefix of another one.
-- Autosnippets fire on the keystroke that completes a trigger, so if `;p` and
-- `;ph` both existed, `;p` would expand to \pi and the h would land after it.
-- That is why every Greek letter below is exactly one character after the
-- semicolon.
--
-- Edit this file and run :SnipReload to try a change without restarting nvim.

local ls = require("luasnip")
local tex = require("util.tex")

local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local fmta = require("luasnip.extras.fmt").fmta
local rep = require("luasnip.extras").rep

-- Where a snippet is allowed to fire. `condition` gates autoexpansion,
-- `show_condition` gates the entry in blink's completion menu.
local in_math = { condition = tex.in_math, show_condition = tex.in_math }
local in_text = { condition = tex.in_text, show_condition = tex.in_text }

-- This file is loaded for markdown too, through the filetype_extend call in
-- lua/plugins/init.lua, so every maths snippet below works inside a note.
--
-- The document-structure snippets must not come with it. \section and
-- \begin{itemize} are wrong in a markdown buffer, where the heading is # and
-- the list is -. in_tex_text is in_text plus a filetype test, and gates the
-- ones that only make sense in a real .tex file.
local function is_tex()
	return vim.bo.filetype == "tex"
end

local function in_tex_text_fn()
	return is_tex() and tex.in_text()
end

local in_tex_text = { condition = in_tex_text_fn, show_condition = in_tex_text_fn }
local in_md_text = {
	condition = function()
		return vim.bo.filetype == "markdown" and tex.in_text()
	end,
	show_condition = function()
		return vim.bo.filetype == "markdown" and tex.in_text()
	end,
}

-- s() with expand-as-you-type turned on.
local function auto(context, nodes, opts)
	if type(context) == "string" then
		context = { trig = context }
	end
	context.snippetType = "autosnippet"
	return s(context, nodes, opts)
end

-- auto() for a trigger written as a Lua pattern, e.g. "([%a])bar".
local function autore(trig, nodes, opts)
	return auto({ trig = trig, regTrig = true, wordTrig = false }, nodes, opts)
end

-- Plain text replacement, which is what most of these snippets are.
--
-- word decides whether the trigger may follow a letter or digit. Symbols like
-- `**` must (you type 2**3), words like `iff` must not, or typing "diff" would
-- expand the tail of it.
local function lit(trig, str, word, opts)
	return auto({ trig = trig, wordTrig = word }, t(str), opts)
end

local M = {}

-- ---------------------------------------------------------------------------
-- Entering and leaving maths
-- ---------------------------------------------------------------------------
M[#M + 1] = auto("mk", fmta([[$<>$<>]], { i(1), i(0) }), in_text)

-- Display maths. Two versions, because the delimiters differ by filetype.
-- \[ ... \] is the LaTeX form. Markdown renderers agree on $$ ... $$ and
-- disagree about \[, so a note gets the dollars.
M[#M + 1] = auto(
	"dm",
	fmta(
		[[
      \[
        <>
      \]
      <>
    ]],
		{ i(1), i(0) }
	),
	in_tex_text
)

M[#M + 1] = auto(
	"dm",
	fmta(
		[[
      $$
      <>
      $$
      <>
    ]],
		{ i(1), i(0) }
	),
	in_md_text
)

-- \text{} is the one way back to prose from inside a formula.
M[#M + 1] = auto("tt", fmta([[\text{<>}]], { i(1) }), in_math)

-- ---------------------------------------------------------------------------
-- Document structure. These are menu snippets, not autosnippets: they are
-- typed once per section, so a confirm keypress costs nothing.
-- ---------------------------------------------------------------------------
M[#M + 1] = s(
	"beg",
	fmta(
		[[
      \begin{<>}
        <>
      \end{<>}
    ]],
		{ i(1), i(2), rep(1) }
	),
	in_tex_text
)

M[#M + 1] = s("h1", fmta([[\section{<>}]], { i(1) }), in_tex_text)
M[#M + 1] = s("h2", fmta([[\subsection{<>}]], { i(1) }), in_tex_text)
M[#M + 1] = s("h3", fmta([[\subsubsection{<>}]], { i(1) }), in_tex_text)

M[#M + 1] = s(
	"itm",
	fmta(
		[[
      \begin{itemize}
        \item <>
      \end{itemize}
    ]],
		{ i(1) }
	),
	in_tex_text
)

M[#M + 1] = s(
	"enum",
	fmta(
		[[
      \begin{enumerate}
        \item <>
      \end{enumerate}
    ]],
		{ i(1) }
	),
	in_tex_text
)

M[#M + 1] = s(
	"fig",
	fmta(
		[[
      \begin{figure}[htbp]
        \centering
        \includegraphics[width=<>\textwidth]{<>}
        \caption{<>}
        \label{fig:<>}
      \end{figure}
    ]],
		{ i(1, "0.8"), i(2), i(3), i(4) }
	),
	in_tex_text
)

M[#M + 1] = s(
	"ali",
	fmta(
		[[
      \begin{align}
        <>
      \end{align}
    ]],
		{ i(1) }
	),
	in_tex_text
)

M[#M + 1] = s(
	"eqn",
	fmta(
		[[
      \begin{equation}
        \label{eq:<>}
        <>
      \end{equation}
    ]],
		{ i(1), i(2) }
	),
	in_tex_text
)

-- ---------------------------------------------------------------------------
-- Cross references and citations
-- ---------------------------------------------------------------------------
-- texlab completes the key itself once the brace is open, so these only have
-- to get you to the brace.
M[#M + 1] = s("cit", fmta([[\cite{<>}]], { i(1) }), in_tex_text)
M[#M + 1] = s("rf", fmta([[\cref{<>}]], { i(1) }), in_tex_text)
M[#M + 1] = s("lbl", fmta([[\label{<>}]], { i(1) }), in_tex_text)

-- ---------------------------------------------------------------------------
-- Fractions, powers and roots
-- ---------------------------------------------------------------------------
M[#M + 1] = auto("//", fmta([[\frac{<>}{<>}]], { i(1), i(2) }), in_math)
M[#M + 1] = auto("sq", fmta([[\sqrt{<>}]], { i(1) }), in_math)
M[#M + 1] = auto("nrt", fmta([[\sqrt[<>]{<>}]], { i(1), i(2) }), in_math)

M[#M + 1] = lit("sr", "^2", false, in_math)
M[#M + 1] = lit("cb", "^3", false, in_math)
M[#M + 1] = auto("td", fmta([[^{<>}]], { i(1) }), in_math)
M[#M + 1] = auto("__", fmta([[_{<>}]], { i(1) }), in_math)
M[#M + 1] = auto("ee", fmta([[e^{<>}]], { i(1) }), in_math)

-- x1 becomes x_1. The subscript is the most typed piece of notation there is
-- and the pattern is unambiguous inside maths.
M[#M + 1] = autore(
	"([%a])(%d)",
	f(function(_, snip)
		return snip.captures[1] .. "_" .. snip.captures[2]
	end),
	in_math
)

-- abar becomes \bar{a}, and the same shape for hats, vectors and tildes.
-- `dot` is deliberately absent: \cdot ends in "dot" preceded by a letter, so
-- the pattern would eat the output of the ** snippet below.
for suffix, cmd in pairs({ bar = "bar", hat = "hat", vec = "vec", tld = "tilde" }) do
	M[#M + 1] = autore(
		"([%a])" .. suffix,
		f(function(_, snip)
			return "\\" .. cmd .. "{" .. snip.captures[1] .. "}"
		end),
		in_math
	)
end

-- ---------------------------------------------------------------------------
-- Operators with limits
-- ---------------------------------------------------------------------------
M[#M + 1] = auto("sum", fmta([[\sum_{<>}^{<>} <>]], { i(1, "n=1"), i(2, [[\infty]]), i(3) }), in_math)
M[#M + 1] = auto("prd", fmta([[\prod_{<>}^{<>} <>]], { i(1, "n=1"), i(2, [[\infty]]), i(3) }), in_math)
M[#M + 1] = auto("lim", fmta([[\lim_{<> \to <>} <>]], { i(1, "n"), i(2, [[\infty]]), i(3) }), in_math)
M[#M + 1] = auto("int", fmta([[\int <> \, d<>]], { i(1), i(2, "x") }), in_math)
M[#M + 1] = auto("dint", fmta([[\int_{<>}^{<>} <> \, d<>]], { i(1, "0"), i(2, [[\infty]]), i(3), i(4, "x") }), in_math)
M[#M + 1] = auto("pdv", fmta([[\frac{\partial <>}{\partial <>}]], { i(1), i(2) }), in_math)
M[#M + 1] = auto("ddv", fmta([[\frac{d <>}{d <>}]], { i(1), i(2) }), in_math)

-- ---------------------------------------------------------------------------
-- Delimiters that grow with their contents.
--
-- The trigger names the bracket instead of using it. Typing `lr(` would hand
-- the open bracket to nvim-autopairs first, and its closing bracket would end
-- up parked inside the snippet.
-- ---------------------------------------------------------------------------
for trig, pair in pairs({
	lrp = { "(", ")" }, -- parenthesis
	lrb = { "[", "]" }, -- bracket
	lrc = { [[\{]], [[\}]] }, -- curly
	lrv = { "|", "|" }, -- vertical bar
	lra = { [[\langle]], [[\rangle]] }, -- angle
}) do
	M[#M + 1] = auto(trig, fmta([[\left<> <> \right<>]], { t(pair[1]), i(1), t(pair[2]) }), in_math)
end

M[#M + 1] = auto("cei", fmta([[\left\lceil <> \right\rceil]], { i(1) }), in_math)
M[#M + 1] = auto("flr", fmta([[\left\lfloor <> \right\rfloor]], { i(1) }), in_math)

-- ---------------------------------------------------------------------------
-- Matrices and cases
-- ---------------------------------------------------------------------------
M[#M + 1] = auto(
	"pmat",
	fmta(
		[[
      \begin{pmatrix}
        <>
      \end{pmatrix}
    ]],
		{ i(1) }
	),
	in_math
)

M[#M + 1] = auto(
	"cse",
	fmta(
		[[
      \begin{cases}
        <> & <> \\
        <> & <>
      \end{cases}
    ]],
		{ i(1), i(2), i(3), i(4) }
	),
	in_math
)

-- ---------------------------------------------------------------------------
-- Relations and arrows written as symbols. wordTrig is off for all of them,
-- because you type 2**3 and x<=y with no space in front.
-- ---------------------------------------------------------------------------
for trig, cmd in pairs({
	["->"] = [[\to ]],
	["!>"] = [[\mapsto ]],
	["=>"] = [[\implies ]],
	["=<"] = [[\impliedby ]],
	["!="] = [[\neq ]],
	["<="] = [[\le ]],
	[">="] = [[\ge ]],
	["~~"] = [[\approx ]],
	["=="] = [[&= ]],
	["**"] = [[\cdot ]],
	["..."] = [[\ldots ]],
	["xx"] = [[\times ]],
}) do
	M[#M + 1] = lit(trig, cmd, false, in_math)
end

-- ---------------------------------------------------------------------------
-- Relations written as words. wordTrig is on, so "diff" does not expand its
-- own tail into \iff.
-- ---------------------------------------------------------------------------
for trig, cmd in pairs({
	iff = [[\iff ]],
	iin = [[\in ]],
	nin = [[\notin ]],
	sub = [[\subset ]],
	cup = [[\cup ]],
	cap = [[\cap ]],
	AA = [[\forall ]],
	EE = [[\exists ]],
	ooo = [[\infty]],
	dag = [[\dagger]],
}) do
	M[#M + 1] = lit(trig, cmd, true, in_math)
end

-- ---------------------------------------------------------------------------
-- Blackboard, calligraphic and bold letters
-- ---------------------------------------------------------------------------
-- E is missing on purpose: EE is already \exists above.
for _, letter in ipairs({ "R", "N", "Z", "Q", "C", "F", "P" }) do
	M[#M + 1] = lit(letter .. letter, [[\mathbb{]] .. letter .. "}", true, in_math)
end

M[#M + 1] = auto("cal", fmta([[\mathcal{<>}]], { i(1) }), in_math)
M[#M + 1] = auto("bff", fmta([[\mathbf{<>}]], { i(1) }), in_math)
M[#M + 1] = auto("rmm", fmta([[\mathrm{<>}]], { i(1) }), in_math)

-- ---------------------------------------------------------------------------
-- Greek letters and the two operators that behave like them.
-- Exactly one character after the semicolon, so no trigger can shadow another.
-- Capital letter gives the capital Greek letter.
-- ---------------------------------------------------------------------------
local greek = {
	a = "alpha",
	b = "beta",
	c = "chi",
	d = "delta",
	D = "Delta",
	e = "epsilon",
	E = "varepsilon",
	f = "phi",
	F = "Phi",
	g = "gamma",
	G = "Gamma",
	h = "eta",
	j = "varphi",
	k = "kappa",
	l = "lambda",
	L = "Lambda",
	m = "mu",
	n = "nu",
	N = "nabla",
	o = "omega",
	O = "Omega",
	p = "pi",
	P = "Pi",
	q = "theta",
	Q = "Theta",
	r = "rho",
	s = "sigma",
	S = "Sigma",
	t = "tau",
	u = "upsilon",
	x = "xi",
	X = "Xi",
	y = "psi",
	Y = "Psi",
	z = "zeta",
}

for key, name in pairs(greek) do
	M[#M + 1] = lit(";" .. key, "\\" .. name .. " ", false, in_math)
end

-- ;; is \partial, which has no letter of its own left.
M[#M + 1] = lit(";;", [[\partial ]], false, in_math)

return M
