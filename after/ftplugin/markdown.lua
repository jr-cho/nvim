-- Markdown buffer settings.
--
-- This file is the markdown twin of after/ftplugin/tex.lua. Notes are prose
-- with maths in them, so the two filetypes want most of the same treatment.

-- Prose deserves a spell checker. z= corrects the word under the cursor,
-- ]s and [s move between mistakes.
vim.opt_local.spell = true
vim.opt_local.spelllang = "en_us"

-- Never hard-wrap. init.lua already wraps long lines on screen, and keeping one
-- paragraph on one line means a one-word edit is a one-word diff.
vim.opt_local.textwidth = 0

-- prettier writes spaces, and the global default in options.lua is a hard tab.
-- Without this, every save would rewrite the indentation of every list item you
-- touched. A hard tab is also ambiguous in markdown: four spaces of indent make
-- a code block, and a tab is not reliably four columns to every renderer.
vim.opt_local.expandtab = true
vim.opt_local.shiftwidth = 2
vim.opt_local.softtabstop = 2

-- gf on a link like [theory](topics/limits) opens topics/limits.md. Without
-- suffixesadd, gf looks for a file with no extension and reports that it does
-- not exist.
vim.opt_local.suffixesadd:prepend(".md")

-- The bullet that can carry a checkbox, as a Lua pattern.
--
-- Two forms, because markdown allows both. "- [ ] task" is the unordered one.
-- "1. [ ] task" and "1) [ ] task" are the ordered ones, and a numbered list of
-- steps is the shape a lab writeup takes, so leaving them out would mean the
-- key worked on half the lists in a notes tree.
local BULLETS = {
	"^(%s*[-*+] )", -- - [ ]   * [ ]   + [ ]
	"^(%s*%d+[.)] )", -- 1. [ ]  1) [ ]
}

-- Toggle the checkbox on the current line: [ ] becomes [x], and back.
-- Leaves a line that holds no checkbox alone rather than inventing one.
local function toggle_checkbox()
	local line = vim.api.nvim_get_current_line()

	for _, bullet in ipairs(BULLETS) do
		local ticked = line:gsub(bullet .. "%[ %]", "%1[x]", 1)
		if ticked ~= line then
			vim.api.nvim_set_current_line(ticked)
			return
		end

		local cleared = line:gsub(bullet .. "%[[xX]%]", "%1[ ]", 1)
		if cleared ~= line then
			vim.api.nvim_set_current_line(cleared)
			return
		end
	end

	vim.notify("no checkbox on this line", vim.log.levels.WARN)
end

vim.keymap.set("n", "<localleader>x", toggle_checkbox, {
	buffer = true,
	silent = true,
	desc = "Toggle checkbox",
})
