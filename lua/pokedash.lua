-- Start screen with a full-colour sprite.
--
-- art/charizard-shiny is 24-bit ANSI, where each cell is a half-block glyph
-- carrying a foreground colour for the top pixel and a background colour for
-- the bottom. Drawing that needs one highlight group per distinct colour pair,
-- which is why this is a module and not a start screen plugin: those render a
-- header as one virt_text chunk per line under a single highlight group, so
-- they cannot show more than one colour.

local M = {}

local ns = vim.api.nvim_create_namespace("pokedash")
local hl_cache = {}

-- Button colours, linked to groups the colourscheme owns so they follow it.
--
-- Directory is catppuccin's blue and reads as an actionable label. The key
-- hint links to NonText, which is dimmer than Comment: a hint should recede,
-- and Comment is the same grey as the label it sits beside.
--
-- Defined on every call rather than once at require time, so the buttons
-- follow a colourscheme change.
local function define_button_hl()
	vim.api.nvim_set_hl(0, "PokedashButton", { link = "Directory" })
	vim.api.nvim_set_hl(0, "PokedashKey", { link = "NonText" })
end

-- One highlight group per fg/bg pair, created on demand and reused.
local function hl_for(fg, bg)
	local key = (fg or "-") .. "/" .. (bg or "-")
	local name = hl_cache[key]
	if name then
		return name
	end
	name = "PokedashC" .. vim.fn.sha256(key):sub(1, 10)
	vim.api.nvim_set_hl(0, name, { fg = fg, bg = bg })
	hl_cache[key] = name
	return name
end

-- Turn one ANSI line into { text = "...", spans = { {start, stop, hl}, ... } }.
-- Columns are byte offsets, which is what nvim_buf_set_extmark wants.
local function parse_line(line)
	local text, spans, fg, bg = {}, {}, nil, nil
	local col, i = 0, 1
	while i <= #line do
		local a, b, c, ni = line:match("^\27%[38;2;(%d+);(%d+);(%d+)m()", i)
		if a then
			fg = string.format("#%02x%02x%02x", a, b, c)
			i = ni
		else
			a, b, c, ni = line:match("^\27%[48;2;(%d+);(%d+);(%d+)m()", i)
			if a then
				bg = string.format("#%02x%02x%02x", a, b, c)
				i = ni
			else
				local reset = select(2, line:find("^\27%[0?m", i))
				if reset then
					fg, bg = nil, nil
					i = reset + 1
				else
					local b1 = line:byte(i)
					local len = b1 >= 240 and 4 or b1 >= 224 and 3 or b1 >= 192 and 2 or 1
					local ch = line:sub(i, i + len - 1)
					text[#text + 1] = ch
					if fg or bg then
						local last = spans[#spans]
						if last and last[3] == hl_for(fg, bg) and last[2] == col then
							last[2] = col + len
						else
							spans[#spans + 1] = { col, col + len, hl_for(fg, bg) }
						end
					end
					col = col + len
					i = i + len
				end
			end
		end
	end
	return table.concat(text), spans
end

-- The one sprite. art/ holds charizard-shiny and nothing else, so there is no
-- pool to draw from and no weighting to do.
local function sprite_path()
	local path = vim.fn.stdpath("config") .. "/art/charizard-shiny"
	if vim.fn.filereadable(path) == 1 then
		return path
	end
	return nil
end

-- Telescope, since that is what this config uses for finding things.
M.buttons = {
	{
		key = "f",
		icon = "",
		label = "Find file",
		cmd = 'lua require("telescope.builtin").find_files({ hidden = true })',
	},
	{ key = "o", icon = "", label = "Recent files", cmd = 'lua require("telescope.builtin").oldfiles()' },
	{
		key = "w",
		icon = "",
		label = "Find word",
		cmd = 'lua require("telescope.builtin").live_grep({ hidden = true })',
	},
	{
		key = "e",
		icon = "",
		label = "File browser",
		cmd = 'lua require("telescope").extensions.file_browser.file_browser()',
	},
	{ key = "q", icon = "", label = "Quit", cmd = "qa" },
}

-- Width of one button row, laid out as: icon, gap, label, filler, key.
-- Every row is padded to the same width so the key hints form a straight
-- right-hand column. Icon widths are measured rather than assumed: nerd font
-- glyphs are not all the same display width, and hardcoding two columns left
-- one row shifted against the others.
local BUTTON_W = 34

local function button_text(b)
	local icon_w = vim.fn.strdisplaywidth(b.icon)
	local label_w = vim.fn.strdisplaywidth(b.label)
	local key_w = vim.fn.strdisplaywidth(b.key)
	local filler = BUTTON_W - icon_w - 1 - label_w - key_w
	return b.icon .. " " .. b.label .. string.rep(" ", math.max(1, filler)) .. b.key
end

-- opts.sprite renders that file instead of art/charizard-shiny.
function M.open(opts)
	opts = opts or {}
	define_button_hl()

	local buf = vim.api.nvim_create_buf(false, true)
	local win = vim.api.nvim_get_current_win()

	local sprite_lines, sprite_spans = {}, {}
	local path = opts.sprite or sprite_path()
	if path then
		local f = io.open(path, "rb")
		if f then
			local data = f:read("*a")
			f:close()
			for line in (data .. "\n"):gmatch("([^\n]*)\n") do
				local text, spans = parse_line(line)
				-- The file ends with a bare colour reset and no final newline,
				-- which parses to an empty row that would paint a blank line.
				if text ~= "" then
					sprite_lines[#sprite_lines + 1] = text
					sprite_spans[#sprite_spans + 1] = spans
				end
			end
		end
	end

	local winw = vim.api.nvim_win_get_width(win)
	local winh = vim.api.nvim_win_get_height(win)

	local sprite_w = 0
	for _, l in ipairs(sprite_lines) do
		sprite_w = math.max(sprite_w, vim.fn.strdisplaywidth(l))
	end

	local btn_w = BUTTON_W

	local content_w = math.max(sprite_w, btn_w)
	local left = math.max(0, math.floor((winw - content_w) / 2))
	local total_h = #sprite_lines + 1 + #M.buttons
	local top = math.max(0, math.floor((winh - total_h) / 2))

	local lines, spans_at = {}, {}
	for _ = 1, top do
		lines[#lines + 1] = ""
	end

	local pad = string.rep(" ", left)
	for i, l in ipairs(sprite_lines) do
		lines[#lines + 1] = pad .. l
		spans_at[#lines] = { offset = #pad, spans = sprite_spans[i] }
	end

	lines[#lines + 1] = ""

	-- Centre the button block on its own width rather than reusing the
	-- sprite's padding. The sprite is wider, so sharing its left edge pushed
	-- the buttons off centre.
	local btn_left = math.max(0, math.floor((winw - BUTTON_W) / 2))
	local btn_pad = string.rep(" ", btn_left)

	local button_rows = {}
	for _, b in ipairs(M.buttons) do
		lines[#lines + 1] = btn_pad .. button_text(b)
		button_rows[#lines] = { btn = b, left = btn_left }
	end

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

	for row, entry in pairs(spans_at) do
		for _, s in ipairs(entry.spans) do
			vim.api.nvim_buf_set_extmark(buf, ns, row - 1, entry.offset + s[1], {
				end_col = entry.offset + s[2],
				hl_group = s[3],
			})
		end
	end

	-- The key hint is dimmed so the eye lands on the label first.
	for row, entry in pairs(button_rows) do
		local line = lines[row]
		local key_start = #line - #entry.btn.key
		vim.api.nvim_buf_set_extmark(buf, ns, row - 1, entry.left, {
			end_row = row - 1,
			end_col = key_start,
			hl_group = "PokedashButton",
		})
		vim.api.nvim_buf_set_extmark(buf, ns, row - 1, key_start, {
			end_row = row - 1,
			end_col = #line,
			hl_group = "PokedashKey",
		})
	end

	vim.bo[buf].modifiable = false
	vim.bo[buf].buftype = "nofile"
	vim.bo[buf].filetype = "pokedash"
	vim.bo[buf].buflisted = false

	for _, b in ipairs(M.buttons) do
		vim.keymap.set("n", b.key, "<cmd>" .. b.cmd .. "<CR>", { buffer = buf, silent = true, desc = b.label })
	end

	vim.api.nvim_win_set_buf(win, buf)

	-- number, relativenumber, cursorline, signcolumn, fillchars and list are
	-- WINDOW-local, not buffer-local. Setting them for the dashboard leaves
	-- them set on the window afterwards, so opening a file from here would give
	-- a buffer with no line numbers. Save what was there and put it back when
	-- the dashboard buffer leaves the window.
	local saved = {}
	local wopts = { "number", "relativenumber", "cursorline", "signcolumn", "fillchars", "list" }
	for _, o in ipairs(wopts) do
		saved[o] = vim.wo[win][o]
	end

	vim.wo[win].number = false
	vim.wo[win].relativenumber = false
	vim.wo[win].cursorline = false
	vim.wo[win].signcolumn = "no"
	vim.wo[win].fillchars = "eob: "
	vim.wo[win].list = false

	vim.api.nvim_create_autocmd({ "BufWinLeave", "BufUnload" }, {
		buffer = buf,
		once = true,
		callback = function()
			if not vim.api.nvim_win_is_valid(win) then
				return
			end
			for _, o in ipairs(wopts) do
				vim.wo[win][o] = saved[o]
			end
		end,
	})

	return buf
end

function M.setup()
	vim.api.nvim_create_autocmd("VimEnter", {
		group = vim.api.nvim_create_augroup("pokedash", { clear = true }),
		callback = function()
			-- Only for a bare `nvim`: no file arguments, nothing piped in, and
			-- no other buffer already holding content.
			if vim.fn.argc(-1) > 0 or vim.fn.line2byte("$") ~= -1 then
				return
			end
			M.open()
		end,
	})
end

return M
