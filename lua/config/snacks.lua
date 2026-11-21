-- Snacks.nvim (the only plugin): dashboard, picker, terminal, lazygit, bigfile.
local header = [[
     ██╗███████╗██████╗ ██╗ ██████╗██╗  ██╗ ██████╗
     ██║██╔════╝██╔══██╗██║██╔════╝██║  ██║██╔═══██╗
     ██║█████╗  ██████╔╝██║██║     ███████║██║   ██║
██   ██║██╔══╝  ██╔══██╗██║██║     ██╔══██║██║   ██║
╚█████╔╝███████╗██║  ██║██║╚██████╗██║  ██║╚██████╔╝
 ╚════╝ ╚══════╝╚═╝  ╚═╝╚═╝ ╚═════╝╚═╝  ╚═╝ ╚═════╝]]

require("snacks").setup({
  bigfile = { enabled = true },
  dashboard = {
    enabled = true,
    preset = {
      header = header,
      -- stylua: ignore
      keys = {
        { icon = "\u{ea7b} ", key = "f", desc = "Find File", action = ":lua Snacks.picker.files()" },
        { icon = "\u{ea7f} ", key = "n", desc = "New File", action = ":ene | startinsert" },
        { icon = "\u{ea6d} ", key = "g", desc = "Find Text", action = ":lua Snacks.picker.grep()" },
        { icon = "\u{ea6e} ", key = "q", desc = "Quit", action = ":qa" },
      },
    },
    sections = { { section = "header" }, { section = "keys", gap = 1, padding = 1 } },
  },
  picker = { enabled = true, ui_select = true },
  terminal = { enabled = true },
  -- snap-confined lazygit cannot read the generated theme file in ~/.cache
  lazygit = { enabled = true, configure = not vim.startswith(vim.fn.exepath("lazygit"), "/snap/") },
})
