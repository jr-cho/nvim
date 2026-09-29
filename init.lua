-- Entry point.
--
-- Order matters here and nowhere else in the config:
--   1. Leader keys, before any plugin can bind them.
--   2. Plugins, through vim.pack.
--   3. Autocommands, then keybinds, which read plugin modules at load time.
vim.g.mapleader = " "
vim.g.maplocalleader = ","

-- Neovim decides whether a .tex file is plain TeX or LaTeX by scanning it, and
-- calls anything without \documentclass, \usepackage or \begin{ "plaintex".
-- A brand new .tex file has none of those, so without this it opens as
-- plaintex and no LaTeX ftplugin or snippet ever runs.
vim.g.tex_flavor = "latex"

-- Keep the cursor near the middle of the window.
vim.opt.scrolloff = math.floor(vim.o.lines / 2) - 3

require("plugins.init")
require("config.autocmd")
require("config.binds")

-- Line numbers. Their colours belong to the colourscheme,
-- lua/plugins/ui/gruvbox.lua.
vim.opt.cursorline = true
vim.wo.relativenumber = true
vim.wo.number = true

-- Windows
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.o.winborder = "rounded"

-- Tabs
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = false

-- Undo
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.opt.undofile = true

-- Search highlighting
vim.opt.hlsearch = false
vim.opt.incsearch = true
vim.opt.termguicolors = true

vim.opt.wrap = false
vim.o.autoindent = true

-- Mouse off, except in terminal buffers (Claude Code) so the wheel scrolls.
vim.opt.mouse = ""
vim.api.nvim_create_autocmd({ "BufEnter", "TermOpen" }, {
	callback = function()
		vim.opt.mouse = vim.bo.buftype == "terminal" and "a" or ""
	end,
})

-- One global statusline, not one per split.
vim.opt.laststatus = 3

-- Undotree
vim.pack.add({ { src = "https://github.com/jiaoshijie/undotree", name = "undotree" } })
require("undotree").setup()
vim.keymap.set("n", "<leader>u", require("undotree").toggle, { desc = "Toggle undotree" })

-- Local project config
vim.o.exrc = true

-- Case handling and flash colours
vim.o.ignorecase = true
vim.o.smartcase = true
-- Dune palette: magenta, red and background (lua/dune.lua).
local dune = require("dune")
vim.api.nvim_set_hl(0, "FlashMatch", { fg = dune.C5, bold = true })
vim.api.nvim_set_hl(0, "FlashLabel", { fg = dune.BG, bg = dune.C1, bold = false })
vim.api.nvim_set_hl(0, "FlashCurrent", { bg = dune.C5, fg = dune.BG, bold = true })

-- Start screen and keybinding cheatsheet.
require("pokedash").setup()
require("cheatsheet").setup()
