-- Statusline and tabline.
--
-- mini.statusline's default content is a starting point rather than a design:
-- it shows the full path, the file encoding and the byte size, and no git or
-- diagnostic state at all. A path is too long to read at a glance and the
-- encoding is the same on every file you will ever open here.
--
-- What this shows, left to right:
--   mode, coloured per mode
--   git branch and working-tree changes
--   diagnostic counts
--   the file name, not its path, with a marker when modified
--   which language servers are attached
--   filetype
--   line, column, and how far through the file you are
local M = {}

-- Truncation widths. Each section disappears below its width rather than the
-- line wrapping or the location being pushed off the end. The rightmost
-- sections are the ones worth keeping longest, so they get the lowest numbers.
local TRUNC = {
	mode = 120,
	git = 90,
	diagnostics = 90,
	lsp = 110,
	filetype = 100,
}

-- Name of the file, not its path, with a marker for modified and readonly.
-- mini.statusline's own section_filename shows a path relative to the working
-- directory, which is still most of a line inside a nested source tree.
local function filename()
	local name = vim.fn.expand("%:t")
	if name == "" then
		name = "[No Name]"
	end
	if vim.bo.modified then
		name = name .. " ●"
	end
	if vim.bo.readonly or not vim.bo.modifiable then
		name = name .. " "
	end
	return name
end

-- Which servers are attached, by name. "LSP" alone tells you something is
-- attached but not whether it is the one you expected, and on Python two
-- attach at once.
local function lsp()
	if vim.o.columns < TRUNC.lsp then
		return ""
	end
	local names = {}
	for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
		names[#names + 1] = client.name
	end
	if #names == 0 then
		return ""
	end
	table.sort(names)
	return " " .. table.concat(names, " ")
end

local function filetype()
	if vim.o.columns < TRUNC.filetype or vim.bo.filetype == "" then
		return ""
	end
	local icon = ""
	local ok, icons = pcall(require, "mini.icons")
	if ok then
		icon = icons.get("filetype", vim.bo.filetype) .. " "
	end
	return icon .. vim.bo.filetype
end

-- Line and column, and how far down the file the cursor is. The percentage is
-- what a scrollbar would tell you.
local function location()
	return "%2l:%-2v %P"
end

function M.active()
	local mode, mode_hl = MiniStatusline.section_mode({ trunc_width = TRUNC.mode })
	-- Uppercase. mini returns "Normal", and the mode is the one thing on this
	-- line read at a glance rather than examined.
	mode = mode:upper()
	local git = MiniStatusline.section_git({ trunc_width = TRUNC.git })
	local diff = MiniStatusline.section_diff({ trunc_width = TRUNC.git })
	local diagnostics = MiniStatusline.section_diagnostics({ trunc_width = TRUNC.diagnostics })

	return MiniStatusline.combine_groups({
		{ hl = mode_hl, strings = { mode } },
		{ hl = "MiniStatuslineDevinfo", strings = { git, diff, diagnostics } },
		"%<", -- truncate here first
		{ hl = "MiniStatuslineFilename", strings = { filename() } },
		"%=", -- push the rest right
		{ hl = "MiniStatuslineDevinfo", strings = { lsp(), filetype() } },
		{ hl = mode_hl, strings = { location() } },
	})
end

-- An inactive window shows only the file name. Anything else is a second
-- statusline competing with the one you are working in.
function M.inactive()
	return MiniStatusline.combine_groups({
		{ hl = "MiniStatuslineInactive", strings = { filename() } },
	})
end

return M
