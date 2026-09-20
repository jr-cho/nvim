-- Entry point.
--
-- Order matters here and nowhere else in the config:
--   1. Leader keys, before any plugin can bind them.
--   2. Plugins, through vim.pack.
--   3. Autocommands, then keybinds, which read plugin modules at load time.
vim.g.mapleader = " "
vim.g.maplocalleader = ","

-- Keep the cursor near the middle of the window.
vim.opt.scrolloff = math.floor(vim.o.lines / 2) - 3

require("plugins.init")
require("config.autocmd")
require("config.binds")

-- Colourscheme
vim.cmd.colorscheme("catppuccin-mocha")

-- Line numbers
vim.opt.cursorline = true
vim.wo.relativenumber = true
vim.wo.number = true
vim.api.nvim_set_hl(0, "LineNr", { fg = "#6c7086" }) -- overlay0
vim.api.nvim_set_hl(0, "CursorLineNr", { fg = "#cba6f7", bold = true }) -- mauve

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

-- Undotree
vim.pack.add({ { src = "https://github.com/jiaoshijie/undotree", name = "undotree" } })
require("undotree").setup()
vim.keymap.set("n", "<leader>u", require("undotree").toggle, { desc = "Toggle undotree" })

-- Local project config
vim.o.exrc = true

-- Case handling and flash colours
vim.o.ignorecase = true
vim.o.smartcase = true
vim.api.nvim_set_hl(0, "FlashMatch", { fg = "#cba6f7", bold = true })
vim.api.nvim_set_hl(0, "FlashLabel", { fg = "#1e1e2e", bg = "#f38ba8", bold = false })
vim.api.nvim_set_hl(0, "FlashCurrent", { bg = "#cba6f7", fg = "#1e1e2e", bold = true })

-- Start screen and keybinding cheatsheet.
require("pokedash").setup()
require("cheatsheet").setup()
