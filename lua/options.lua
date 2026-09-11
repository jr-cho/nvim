-- Editor options. No plugin reads this file and this file reads no plugin.
local o = vim.o

-- Indentation. Hard tabs. after/ftplugin overrides this for LaTeX and
-- markdown, where the format itself cares: four spaces of indent in markdown
-- is a code block, and a tab is not reliably four columns to every renderer.
o.expandtab = false
o.tabstop = 2
o.softtabstop = 2
o.shiftwidth = 2
o.smartindent = true

-- History. Undo survives a restart. Nothing else is written beside the file.
o.undofile = true
o.swapfile = false
o.backup = false

-- Search.
o.ignorecase = true
o.smartcase = true
o.incsearch = true
o.hlsearch = false

-- Display.
o.number = true
o.relativenumber = true
o.signcolumn = "yes"
o.cursorline = true
o.cursorlineopt = "both"
o.scrolloff = 8
o.sidescrolloff = 8
o.winborder = "rounded"
o.laststatus = 3
o.showmode = false
o.splitright = true
o.splitbelow = true
o.splitkeep = "screen"
-- How long Neovim waits for the next key of a mapping. 400 was carried over
-- from the old framework and is too short to finish <leader>tt at a normal
-- typing pace: the wait expires and Space alone runs, so the mapping never
-- fires.
--
-- 1000 is Neovim's own default. The cost of a longer wait is only felt where a
-- key is BOTH a complete mapping and the prefix of a longer one, which this
-- config avoids: <leader> alone is bound to nothing.
--
-- ttimeoutlen is a different option and stays at 50. That one governs terminal
-- key codes, and raising it would add real latency to <Esc>.
o.timeoutlen = 1000
o.updatetime = 250
o.confirm = true

-- Soft wrap. Display only. No newline reaches the file.
o.wrap = true
o.linebreak = true
o.breakindent = true
o.showbreak = "↪ "

-- Show the whitespace that hides bugs.
o.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- Per-project config. exrc trusts a .nvim.lua only after you confirm its hash.
o.exrc = true

-- Completion menu. "popup" shows documentation beside the menu.
o.completeopt = "menu,menuone,popup,noselect"
o.pumheight = 12

-- Native autocompletion, new in 0.12 and off by default. This is the whole
-- engine: no nvim-cmp, no blink.cmp, no sources to wire up.
--
-- Without it, omnifunc is still set on every LSP attach, so <C-x><C-o> works
-- by hand. This is only the difference between asking for the menu and having
-- it offered.
--
-- blink.cmp is the thing to add if this proves annoying: it brings fuzzy
-- matching that tolerates typos, buffer and path sources, and cmdline
-- completion. It is one spec and changes nothing else here.
o.autocomplete = true

-- Disable providers this config does not use, so :checkhealth stays readable.
vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0

-- System clipboard over OSC52, which works through SSH and needs no external
-- binary. Scheduled so the provider probe stays out of startup.
vim.schedule(function()
	vim.g.clipboard = "osc52"
	o.clipboard = "unnamedplus"
end)
