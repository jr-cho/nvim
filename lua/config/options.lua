-- Editor options. Completion options are left to blink.cmp.
local o = vim.opt

o.number = true
o.relativenumber = true
o.cursorline = true
o.cursorlineopt = "number"
o.signcolumn = "yes"
o.laststatus = 3
o.fillchars = {
  eob = " ",
  foldopen = "\u{f078}",
  foldclose = "\u{f054}",
  fold = " ",
  foldsep = " ",
}

o.expandtab = true
o.shiftwidth = 4
o.tabstop = 4
o.smartindent = true

o.ignorecase = true
o.smartcase = true
o.splitright = true
o.splitbelow = true
o.splitkeep = "screen"
o.equalalways = false
o.scrolloff = 8
o.wrap = false
o.mouse = "a"
o.clipboard = "unnamedplus"
o.undofile = true
o.updatetime = 250
o.timeoutlen = 400
o.winborder = "single"
o.pumheight = 12
o.termguicolors = true
o.showmode = false
o.confirm = true

o.foldenable = true
o.foldlevel = 99
o.foldlevelstart = 99
o.foldmethod = "expr"
o.foldexpr = "v:lua.vim.treesitter.foldexpr()"
o.foldcolumn = "1"
