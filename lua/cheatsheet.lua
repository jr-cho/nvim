-- A cheatsheet of every mapping that carries a description.
--
-- which-key answers "what follows this prefix" once you have already pressed
-- a key. This answers "what can I do", which is the question you have first.
--
-- Groups come from lua/keygroups.lua, the same list which-key names its
-- prefixes with, so a new group appears here without being added twice.
local M = {}

local ns = vim.api.nvim_create_namespace("cheatsheet")

-- Column width, and the gap between columns.
local COL_W = 46
local GAP = 2

-- What goes in, and what does not.
--
-- Every <leader> mapping is included: those are the ones chosen deliberately,
-- and they are what the sheet is for.
--
-- Everything else is curated by hand below. Dumping the rest is worse than
-- useless: Neovim's own defaults arrive with descriptions like
-- ":help &-default", and mini.nvim adds a few hundred more. A cheatsheet with
-- 300 entries answers nothing.
--
-- Every non-leader key worth knowing is listed here rather than collected,
-- because collect() takes leader mappings only.
--
-- Keep each key and its description inside COL_W together. A longer pair runs
-- into the next column.
--
-- The dashboard's own keys are left out on purpose. The dashboard prints them
-- on itself, beside the thing each one does.
local ESSENTIALS = {
	["lsp"] = {
		{ "K", "Hover" },
		{ "grn", "Rename symbol" },
		{ "gra", "Code action" },
		{ "grr", "References" },
		{ "gri", "Implementation" },
		{ "grt", "Type definition" },
		{ "gO", "Document symbols" },
		{ "<C-s>", "Signature help (insert)" },
		{ "]d / [d", "Next / previous diagnostic" },
	},
	["editing"] = {
		{ "af / if", "A function / its body" },
		{ "ac / ic", "A class / its body" },
		{ "sa / sd / sr", "Add / delete / replace surround" },
		{ "sf / sF", "Find the next / previous surround" },
		{ "sh", "Highlight a surround" },
		-- Neovim ships commenting since 0.10. No plugin sets these.
		{ "gc [v]", "Comment the selection" },
		{ "gcc", "Comment the line" },
		{ "gc{motion}", "Comment over a motion" },
		{ "J / K [v]", "Move the selection down / up" },
		{ "H / L [v]", "Move the selection left / right" },
		{ "< / > [v]", "Indent, keep the selection" },
		{ "i / a / I / A", "Insert, clearing whitespace" },
		{ "<C-BS>", "Delete a word (insert)" },
	},
	["moving"] = {
		{ "ss", "Flash jump" },
		{ "S", "Flash treesitter" },
		{ "<C-w> hjkl", "Move between windows" },
		{ "<C-d> / <C-u>", "Half page down / up" },
		{ "n / N", "Next / previous match" },
	},
	["telescope"] = {
		{ "<CR>", "Jump to the window holding the file" },
		{ "<C-t>", "Open the result in a new tab" },
		{ "<C-v>", "Open the result in a split" },
		{ "d", "Delete buffer (buffers picker, normal)" },
	},
	["tab"] = {
		{ "<C-t>l / <C-t>h", "Next / previous tab" },
		{ "<C-t>j", "New tab" },
		{ "<C-t>q", "Close tab, keep its buffers" },
	},
	["terminal"] = {
		{ "<C-d>", "Leave terminal mode" },
	},
}

local function collect()
	local groups, order = {}, {}
	local labels = {}
	for _, g in ipairs(require("keygroups")) do
		labels[g[1]] = g.group
	end

	local function bucket_for(lhs)
		-- Longest prefix wins, so <leader>T lands in "test" rather than in a
		-- shorter prefix that also matches.
		local best, best_len = nil, -1
		for prefix, name in pairs(labels) do
			local lit = prefix:gsub("<leader>", " ")
			if #lit > best_len and lhs:sub(1, #lit) == lit and #lhs > #lit then
				best, best_len = name, #lit
			end
		end
		return best
	end

	local function add(name, lhs, desc)
		if not groups[name] then
			groups[name] = {}
			order[#order + 1] = name
		end
		table.insert(groups[name], { lhs = lhs, desc = desc })
	end

	for _, mode in ipairs({ "n", "x" }) do
		for _, m in ipairs(vim.api.nvim_get_keymap(mode)) do
			-- Leader mappings only. A leading space is what <leader> becomes.
			if m.desc and m.desc ~= "" and m.lhs:sub(1, 1) == " " then
				local name = bucket_for(m.lhs) or "leader"
				local tag = mode == "x" and " [v]" or ""
				add(name, (m.lhs:gsub("^ ", "<leader>")) .. tag, m.desc)
			end
		end
	end

	for name, entries in pairs(ESSENTIALS) do
		for _, e in ipairs(entries) do
			add(name, e[1], e[2])
		end
	end

	for _, list in pairs(groups) do
		table.sort(list, function(a, b)
			return a.lhs < b.lhs
		end)
	end
	table.sort(order)
	return groups, order
end

-- Lay the groups out across columns, keeping each group whole.
--
-- Balanced packing, not a sequential fill. Filling each column to an average
-- height and moving on left every leftover block in the final column: the
-- sheet stayed 54 rows tall whether it had two columns or four, because one
-- column held everything the earlier ones had not taken.
--
-- Placing each group in whichever column is currently shortest keeps the
-- columns within one group of each other.
local function layout(groups, order, cols)
	local blocks = {}
	for _, name in ipairs(order) do
		local block = { name:upper() }
		for _, e in ipairs(groups[name]) do
			local pad = COL_W - vim.fn.strdisplaywidth(e.lhs) - vim.fn.strdisplaywidth(e.desc)
			block[#block + 1] = e.lhs .. string.rep(" ", math.max(1, pad)) .. e.desc
		end
		block[#block + 1] = ""
		blocks[#blocks + 1] = block
	end

	-- Tallest first, so the big groups are placed while there is still room to
	-- balance around them.
	table.sort(blocks, function(a, b)
		return #a > #b
	end)

	local columns = {}
	for i = 1, cols do
		columns[i] = {}
	end

	for _, b in ipairs(blocks) do
		local shortest, len = 1, #columns[1]
		for i = 2, cols do
			if #columns[i] < len then
				shortest, len = i, #columns[i]
			end
		end
		for _, l in ipairs(b) do
			columns[shortest][#columns[shortest] + 1] = l
		end
	end

	return columns
end

function M.open()
	local groups, order = collect()

	-- As many columns as fit, up to four. Three was too few: at 200 columns the
	-- sheet came to 54 rows against 44 of usable height, so it scrolled while a
	-- fourth column sat unused.
	local cols = math.max(1, math.min(4, math.floor((vim.o.columns - 8) / (COL_W + GAP))))
	local columns = layout(groups, order, cols)

	local height = 0
	for _, c in ipairs(columns) do
		height = math.max(height, #c)
	end

	local lines, marks = {}, {}
	for row = 1, height do
		local parts = {}
		local col_at = 0
		for i, c in ipairs(columns) do
			local text = c[row] or ""
			-- A group heading is a line with no gap run in it.
			if text ~= "" and not text:find("  ") then
				marks[#marks + 1] = { row - 1, col_at, col_at + #text, "CheatsheetGroup" }
			elseif text ~= "" then
				local key = text:match("^(%S+)")
				if key then
					marks[#marks + 1] = { row - 1, col_at, col_at + #key, "CheatsheetKey" }
				end
			end
			parts[#parts + 1] = text .. string.rep(" ", math.max(0, COL_W + GAP - vim.fn.strdisplaywidth(text)))
			col_at = col_at + #parts[#parts]
			if i == #columns then
				parts[#parts] = text
			end
		end
		lines[#lines + 1] = " " .. table.concat(parts)
	end

	local buf = vim.api.nvim_create_buf(false, true)

	-- mini.trailspace paints trailing whitespace red, and the sprite's empty
	-- cells are spaces. The rest are off for the same reason: none of them
	-- have anything to say about a start screen.
	vim.b[buf].minitrailspace_disable = true
	vim.b[buf].minicursorword_disable = true
	vim.b[buf].miniindentscope_disable = true
	vim.b[buf].minianimate_disable = true
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].modifiable = false
	vim.bo[buf].buftype = "nofile"
	vim.bo[buf].filetype = "cheatsheet"

	vim.api.nvim_set_hl(0, "CheatsheetGroup", { link = "Title" })
	vim.api.nvim_set_hl(0, "CheatsheetKey", { link = "Identifier" })
	for _, m in ipairs(marks) do
		pcall(vim.api.nvim_buf_set_extmark, buf, ns, m[1], m[2] + 1, {
			end_col = m[3] + 1,
			hl_group = m[4],
		})
	end

	local width = math.min(vim.o.columns - 4, cols * (COL_W + GAP) + 2)
	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = math.min(height, vim.o.lines - 6),
		row = math.floor((vim.o.lines - math.min(height, vim.o.lines - 6)) / 2) - 1,
		col = math.floor((vim.o.columns - width) / 2),
		style = "minimal",
		border = "rounded",
		title = " Cheatsheet ",
		title_pos = "center",
	})
	vim.wo[win].cursorline = false

	for _, key in ipairs({ "q", "<Esc>" }) do
		vim.keymap.set("n", key, "<cmd>close<CR>", { buffer = buf, silent = true })
	end
end

function M.setup()
	vim.api.nvim_create_user_command("Cheatsheet", M.open, { desc = "Show the keybinding cheatsheet" })
	vim.keymap.set("n", "<leader>?", M.open, { silent = true, desc = "Cheatsheet" })
end

return M
