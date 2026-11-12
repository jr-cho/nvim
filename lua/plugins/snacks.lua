-- Snacks.nvim: dashboard, explorer (persistent sidebar, see ide/layout.lua), pickers, UI helpers.
local header = [[
███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║
██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║
██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║
╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝]]

local I = require("ide.icons")

return {
  {
    "folke/snacks.nvim",
    lazy = false,
    priority = 1000,
    ---@type snacks.Config
    opts = {
      bigfile = { enabled = true },
      dashboard = {
        enabled = true,
        preset = {
          header = header,
          -- stylua: ignore
          keys = {
            { icon = I.misc.file .. " ", key = "f", desc = "Find File", action = ":lua Snacks.picker.files()" },
            { icon = I.misc.new_file .. " ", key = "n", desc = "New File", action = ":ene | startinsert" },
            { icon = I.misc.text .. " ", key = "g", desc = "Find Text", action = ":lua Snacks.picker.grep()" },
            { icon = I.misc.recent .. " ", key = "r", desc = "Recent Files", action = ":lua Snacks.picker.recent()" },
            { icon = I.misc.project .. " ", key = "p", desc = "Projects", action = ":lua Snacks.picker.projects()" },
            { icon = I.misc.config .. " ", key = "c", desc = "Config", action = ":lua Snacks.picker.files({ cwd = vim.fn.stdpath('config') })" },
            { icon = I.misc.lazy .. " ", key = "L", desc = "Lazy", action = ":Lazy" },
            { icon = I.misc.mason .. " ", key = "M", desc = "Mason", action = ":Mason" },
            { icon = I.misc.quit .. " ", key = "q", desc = "Quit", action = ":qa" },
          },
        },
        sections = {
          { section = "header" },
          { section = "keys", gap = 1, padding = 1 },
          { icon = I.misc.recent .. " ", title = "Recent Files", section = "recent_files", cwd = true, limit = 5, indent = 2, padding = 1 },
          { icon = I.misc.project .. " ", title = "Projects", section = "projects", limit = 5, indent = 2, padding = 1 },
          { section = "startup" },
        },
      },
      explorer = { enabled = true, replace_netrw = true },
      image = { enabled = true },
      indent = { enabled = true },
      input = { enabled = true },
      notifier = { enabled = true, style = "compact", timeout = 3000 },
      picker = {
        enabled = true,
        ui_select = true,
        sources = {
          explorer = {
            layout = { layout = { width = 30, min_width = 30 } },
            auto_close = false,
            jump = { close = false },
            hidden = false,
            ignored = false,
            win = {
              list = {
                keys = {
                  -- closing by hand must also stop ide.layout from re-opening it
                  ["q"] = function() require("ide.layout").explorer_close() end,
                  ["<Esc>"] = function() require("ide.layout").explorer_close() end,
                },
              },
            },
          },
        },
      },
      quickfile = { enabled = true },
      scope = { enabled = true },
      scroll = { enabled = false },
      statuscolumn = {
        enabled = true,
        left = { "mark", "sign" },
        right = { "fold", "git" },
        folds = { open = true, git_hl = true },
      },
      terminal = { enabled = true },
      toggle = { enabled = true },
      words = { enabled = true },
      zen = { enabled = true },
      -- snap-confined lazygit cannot read the generated theme file in ~/.cache
      lazygit = { configure = not vim.startswith(vim.fn.exepath("lazygit"), "/snap/") },
    },
    config = function(_, opts)
      require("snacks").setup(opts)
      require("ide.layout").setup()
    end,
  },
  { "nvim-tree/nvim-web-devicons", lazy = true },
}
