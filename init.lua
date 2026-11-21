-- Entry point: leaders, PATH, plugins (Snacks + which-key via vim.pack), config modules, colorscheme.
vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.env.PATH = vim.fn.stdpath("data") .. "/mason/bin:" .. vim.env.PATH
vim.pack.add({ "https://github.com/folke/snacks.nvim", "https://github.com/folke/which-key.nvim" }, { confirm = false })

for _, m in ipairs({ "options", "snacks", "lsp", "format", "autocmds", "keymaps" }) do
  require("config." .. m)
end
vim.cmd.colorscheme("chadone")
