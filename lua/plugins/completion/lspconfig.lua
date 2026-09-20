vim.pack.add({
	{ src = "https://github.com/neovim/nvim-lspconfig", name = "lspconfig" },
	{ src = "https://github.com/saghen/blink.cmp", name = "blink" },
	{ src = "https://github.com/saghen/blink.lib", name = "blink-lib" },
})

-- Each server's own settings live in lsp/<name>.lua, which Neovim reads off
-- the runtimepath. Enabling a server here starts it for the filetypes that
-- file names.
vim.lsp.enable({
	"lua_ls",
	"clangd",
	"pyright",
	"ruff",
})

vim.o.winborder = "rounded"

-- On ColorScheme as well as now. The colourscheme module loads after this one
-- and repaints every group, which put the border back to its default.
local function border_hl()
	vim.api.nvim_set_hl(0, "BlinkCmpMenuBorder", { fg = "#61afef" }) -- onedark blue
end
border_hl()
vim.api.nvim_create_autocmd("ColorScheme", { callback = border_hl })

require("blink.cmp").setup({
	-- The rust matcher needs cargo at install time, which this machine does
	-- not have. The lua matcher is slower and needs nothing.
	fuzzy = { implementation = "lua" },
	appearance = { use_nvim_cmp_as_default = true },

	keymap = {
		["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
	},

	signature = {
		enabled = false,
	},

	completion = {
		trigger = {
			show_on_insert = true,
			show_on_trigger_character = true,
			show_on_keyword = true,
			show_on_backspace = true,
		},
		list = {
			selection = {
				preselect = false,
				auto_insert = true,
			},
		},
		menu = {
			auto_show = true,
			border = "rounded",
			min_width = 35,
			auto_show_delay_ms = 100,
		},
	},

	sources = {
		default = { "lsp", "snippets", "buffer", "path" },
	},
})

-- Load lazydev only once a lua buffer is open, then reload blink with it as a
-- source.
vim.api.nvim_create_autocmd("FileType", {
	pattern = "lua",
	callback = function()
		vim.pack.add({
			{ src = "https://github.com/folke/lazydev.nvim", name = "lazydev" },
		})
		require("lazydev").setup()
		require("blink.cmp").setup({
			fuzzy = { implementation = "lua" },
			sources = {
				default = { "lazydev", "lsp", "path", "snippets", "buffer" },
				providers = {
					lazydev = {
						name = "LazyDev",
						module = "lazydev.integrations.blink",
						-- make lazydev completions top priority (see `:h blink.cmp`)
						score_offset = 100,
					},
				},
			},
		})
	end,
})
