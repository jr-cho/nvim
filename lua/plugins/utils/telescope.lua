vim.pack.add({
	{ src = "https://github.com/nvim-telescope/telescope.nvim", name = "telescope" },
	{ src = "https://github.com/nvim-lua/plenary.nvim", name = "plenary" },
	{ src = "https://github.com/nvim-telescope/telescope-symbols.nvim", name = "telescope-symbols" },
	{ src = "https://github.com/nvim-telescope/telescope-ui-select.nvim", name = "telescope-ui-select" },
	{ src = "https://github.com/nvim-telescope/telescope-file-browser.nvim", name = "telescope-file-browser" },
	{ src = "https://github.com/2kabhishek/nerdy.nvim", name = "telescope-nerdy" },
})

-- On ColorScheme as well as now, so a repaint does not take it back to the
-- colourscheme's own border colour.
local function border_hl()
	vim.api.nvim_set_hl(0, "TelescopeBorder", { fg = "#61afef" }) -- onedark blue
end
border_hl()
vim.api.nvim_create_autocmd("ColorScheme", { callback = border_hl })

local actions = require("telescope.actions")

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
				},
				n = {
					["<CR>"] = actions.select_drop,
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
		file_browser = {
			theme = "ivy",
			hijack_netrw = true,
		},
		["ui-select"] = {
			require("telescope.themes").get_dropdown({}),
		},
	},
})

require("telescope").load_extension("file_browser")
require("telescope").load_extension("ui-select")
require("telescope").load_extension("nerdy")
