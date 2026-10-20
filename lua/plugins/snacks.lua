-- snacks: file explorer (sidebar tree) + terminals
-- keybinds live in lua/keymaps.lua
vim.pack.add({
  "https://github.com/nvim-tree/nvim-web-devicons", -- nerd font file icons (tree + telescope)
  { src = "https://github.com/folke/snacks.nvim", version = vim.version.range("2") },
})

require("nvim-web-devicons").setup({})

require("snacks").setup({
  explorer = { enabled = true }, -- also replaces netrw: `nvim .` opens the tree
  picker = {
    enabled = true, -- explorer is a picker under the hood
    sources = {
      explorer = {
        layout = { layout = { width = 30, min_width = 30 } }, -- NvChad tree width
      },
    },
  },
  terminal = { enabled = true },
})
