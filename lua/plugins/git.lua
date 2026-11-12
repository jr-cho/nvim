-- Git signs and hunk navigation. <leader>G* maps live in config/keymaps.lua.
return {
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      signs = {
        add = { text = "│" },
        change = { text = "│" },
        delete = { text = "_" },
        topdelete = { text = "‾" },
        changedelete = { text = "~" },
        untracked = { text = "│" },
      },
      current_line_blame = false,
      on_attach = function(buf)
        local gs = require("gitsigns")
        vim.keymap.set("n", "]h", function() gs.nav_hunk("next") end, { buffer = buf, desc = "Next hunk" })
        vim.keymap.set("n", "[h", function() gs.nav_hunk("prev") end, { buffer = buf, desc = "Prev hunk" })
      end,
    },
  },
}
