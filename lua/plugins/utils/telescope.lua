vim.pack.add({
	{ src = "https://github.com/nvim-telescope/telescope.nvim", name = "telescope" },
	{ src = "https://github.com/nvim-lua/plenary.nvim", name = "plenary" },
	{ src = "https://github.com/nvim-telescope/telescope-symbols.nvim", name = "telescope-symbols" },
	{ src = "https://github.com/nvim-telescope/telescope-ui-select.nvim", name = "telescope-ui-select" },
	{ src = "https://github.com/2kabhishek/nerdy.nvim", name = "telescope-nerdy" },
})

-- On ColorScheme as well as now, so a repaint does not take it back to the
-- colourscheme's own border colour.
local function border_hl()
	vim.api.nvim_set_hl(0, "TelescopeBorder", { fg = require("dune").GREY }) -- dune tan
end
border_hl()
vim.api.nvim_create_autocmd("ColorScheme", { callback = border_hl })

local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

-- Send the selected file(s) to Claude Code's context, without leaving the
-- picker open on top of it.
local function add_to_claude(prompt_bufnr)
	local picker = action_state.get_current_picker(prompt_bufnr)
	local selections = picker:get_multi_selection()
	if vim.tbl_isempty(selections) then
		local entry = action_state.get_selected_entry()
		if entry then
			selections = { entry }
		end
	end
	actions.close(prompt_bufnr)
	for _, entry in ipairs(selections) do
		local path = entry.path or entry.filename or entry.value
		if path then
			vim.cmd("ClaudeCodeAdd " .. vim.fn.fnameescape(path))
		end
	end
end

require("telescope").setup({
	defaults = {
		file_ignore_patterns = { ".git/", "%.csv", ".venv", ".node_modules", "node_modules", ".vscode" },
	},
	pickers = {
		-- select_drop jumps to the window already holding the file instead of
		-- opening a second copy of it in the current window.
		buffers = {
			show_all_buffers = true,
			mappings = {
				i = {
					["<CR>"] = actions.select_drop,
				},
				n = {
					["<CR>"] = actions.select_drop,
					["d"] = actions.delete_buffer,
				},
			},
		},
		find_files = {
			show_all_buffers = true,
			mappings = {
				i = {
					["<CR>"] = actions.select_drop,
					["<C-l>"] = add_to_claude,
				},
				n = {
					["<CR>"] = actions.select_drop,
					["<C-l>"] = add_to_claude,
				},
			},
		},
		live_grep = {
			additional_args = function()
				return { "--hidden" }
			end,
		},
	},
	extensions = {
		["ui-select"] = {
			require("telescope.themes").get_dropdown({}),
		},
	},
})

require("telescope").load_extension("ui-select")
require("telescope").load_extension("nerdy")
