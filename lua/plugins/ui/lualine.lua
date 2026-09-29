vim.pack.add({
	{ src = "https://github.com/nvim-lualine/lualine.nvim", name = "lualine" },
	{ src = "https://github.com/nvim-tree/nvim-web-devicons", name = "devicons" },
})

-- Dune statusline (savar95x dotfiles): gruvbox-material theme, no
-- separators, every section on the terminal background except the mode
-- block (a) and the location block (z), which keep the tan fill.
local bg = require("dune").BG
local theme = vim.deepcopy(require("lualine.themes.gruvbox-material"))
for _, mode in pairs(theme) do
	for _, section in ipairs({ "b", "c", "x", "y" }) do
		if mode[section] then
			mode[section].bg = bg
		end
	end
end

require("lualine").setup({
	options = {
		icons_enabled = true,
		theme = theme,
		component_separators = "",
		section_separators = "",
		disabled_filetypes = {
			statusline = { "pokedash" },
		},
		always_divide_middle = true,
		globalstatus = true,
	},
	sections = {
		lualine_a = {
			"mode",
			{
				function()
					local reg = vim.fn.reg_recording()
					if reg == "" then
						return ""
					end -- not recording
					return "MACRO " .. string.upper(tostring(reg))
				end,
			},
		},
		lualine_b = { "branch", "diff", "diagnostics" },
		lualine_c = { "filename" },
		lualine_x = { "lsp_status", "encoding", "filetype" },
		lualine_y = { "progress" },
		lualine_z = { "location" },
	},
	inactive_sections = {
		lualine_a = {},
		lualine_b = {},
		lualine_c = { "filename" },
		lualine_x = { "location" },
		lualine_y = {},
		lualine_z = {},
	},
})
