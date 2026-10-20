-- telescope: fuzzy finder, laid out NvChad-style
-- borderless look comes from Telescope* highlights in colors/chadone.lua
vim.pack.add({
  "https://github.com/nvim-lua/plenary.nvim",
  "https://github.com/nvim-telescope/telescope-fzf-native.nvim", -- built by PackChanged hook in init.lua
  { src = "https://github.com/nvim-telescope/telescope.nvim", version = vim.version.range("*") },
})

local telescope = require("telescope")
telescope.setup({
  defaults = {
    prompt_prefix = "   ",
    selection_caret = " ",
    entry_prefix = " ",
    sorting_strategy = "ascending",
    layout_config = {
      horizontal = { prompt_position = "top", preview_width = 0.55 },
      width = 0.87,
      height = 0.80,
    },
    mappings = {
      n = { ["q"] = require("telescope.actions").close },
    },
  },
})
pcall(telescope.load_extension, "fzf") -- skip if native sorter failed to build
-- keybinds in lua/keymaps.lua
