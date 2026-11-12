-- UI chrome: bufferline, lualine, dropbar, which-key.

local I = require("ide.icons")

local function lsp_clients()
  local names = {}
  for _, c in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do names[#names + 1] = c.name end
  return #names > 0 and (I.misc.lsp .. " " .. table.concat(names, ",")) or ""
end

local function formatter()
  local ok, conform = pcall(require, "conform")
  if not ok then return "" end
  if vim.g.disable_autoformat or vim.b.disable_autoformat then return "fmt:off" end
  local names = {}
  for _, f in ipairs(conform.list_formatters(0)) do names[#names + 1] = f.name end
  return #names > 0 and (I.misc.config .. " " .. table.concat(names, ",")) or ""
end

return {
  {
    "akinsho/bufferline.nvim",
    version = "*",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      options = {
        mode = "buffers",
        diagnostics = "nvim_lsp",
        separator_style = "thin",
        always_show_bufferline = true,
        close_command = function(n) Snacks.bufdelete(n) end,
        right_mouse_command = function(n) Snacks.bufdelete(n) end,
        offsets = {
          { filetype = "snacks_layout_box", text = "EXPLORER", highlight = "IdeSidebarTitle", text_align = "left", separator = true },
        },
      },
    },
  },
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = function()
      local ok, theme = pcall(require, "chadone.lualine")
      return {
        options = {
          theme = ok and theme or "auto",
          globalstatus = true,
          component_separators = { left = "", right = "" },
          section_separators = { left = "", right = "" },
        },
        sections = {
          lualine_a = { "mode" },
          lualine_b = {
            { "branch", icon = I.git.branch },
            {
              "diff",
              symbols = { added = I.git.added .. " ", modified = I.git.modified .. " ", removed = I.git.removed .. " " },
              source = function()
                local d = vim.b.gitsigns_status_dict
                if d then return { added = d.added, modified = d.changed, removed = d.removed } end
              end,
            },
          },
          lualine_c = { {
            "diagnostics",
            sources = { "nvim_diagnostic" },
            symbols = {
              error = I.diagnostics.Error .. " ",
              warn = I.diagnostics.Warn .. " ",
              info = I.diagnostics.Info .. " ",
              hint = I.diagnostics.Hint .. " ",
            },
          }, { "filename", path = 1 } },
          lualine_x = {
            lsp_clients,
            formatter,
            "encoding",
            { "fileformat", symbols = { unix = "LF", dos = "CRLF", mac = "CR" } },
            "filetype",
          },
          lualine_y = { "progress" },
          lualine_z = {
            function()
              local pos = vim.api.nvim_win_get_cursor(0)
              return ("Ln %d, Col %d"):format(pos[1], pos[2] + 1)
            end,
          },
        },
      }
    end,
  },
  -- breadcrumbs: dropbar's default `enable`, but never in IDE windows (docpanel is markdown,
  -- panel terminals are buftype=terminal — both would otherwise get a breadcrumb winbar)
  {
    "Bekaboo/dropbar.nvim",
    event = "VeryLazy",
    opts = function()
      local default = require("dropbar.configs").opts.bar.enable
      return {
        bar = {
          enable = function(buf, win, info)
            win = win or vim.api.nvim_get_current_win()
            if vim.api.nvim_win_is_valid(win) and vim.w[win].ide_role then return false end
            return default(buf, win, info)
          end,
        },
      }
    end,
  },
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      preset = "modern",
      win = { border = "single" },
      spec = {
        { "<leader>f", group = "find" },
        { "<leader>l", group = "lsp" },
        { "<leader>c", group = "build" },
        { "<leader>D", group = "debug" },
        { "<leader>G", group = "git" },
        { "<leader>u", group = "toggles" },
      },
    },
  },
}
