-- Formatting: conform.nvim (format on save, LSP fallback).
return {
  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    cmd = "ConformInfo",
    init = function()
      vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
      -- :FormatToggle! only affects the current buffer
      vim.api.nvim_create_user_command("FormatToggle", function(args)
        if args.bang then
          vim.b.disable_autoformat = not vim.b.disable_autoformat
          vim.notify("Format on save (buffer): " .. (vim.b.disable_autoformat and "off" or "on"))
        else
          vim.g.disable_autoformat = not vim.g.disable_autoformat
          vim.notify("Format on save: " .. (vim.g.disable_autoformat and "off" or "on"))
        end
      end, { bang = true, desc = "Toggle format on save (! = buffer only)" })
    end,
    opts = {
      formatters_by_ft = {
        c = { "clang-format" },
        cpp = { "clang-format" },
        python = { "ruff_organize_imports", "ruff_format" },
        sh = { "shfmt" },
        bash = { "shfmt" },
        lua = { "stylua" },
        -- cmake: no formatter configured, LSP fallback applies
      },
      -- 4-space defaults when the project carries no config of its own
      formatters = {
        ["clang-format"] = {
          -- --fallback-style only takes preset names, so pass an inline --style when no config exists
          prepend_args = function(_, ctx)
            local found = vim.fs.find({ ".clang-format", "_clang-format" }, { path = ctx.dirname, upward = true })
            if #found == 0 then return { "--style={BasedOnStyle: LLVM, IndentWidth: 4}" } end
            return {}
          end,
        },
        stylua = {
          prepend_args = function(_, ctx)
            local found = vim.fs.find({ "stylua.toml", ".stylua.toml" }, { path = ctx.dirname, upward = true })
            if #found == 0 then return { "--indent-type", "Spaces", "--indent-width", "4" } end
            return {}
          end,
        },
      },
      default_format_opts = { lsp_format = "fallback" },
      format_on_save = function(buf)
        if vim.g.disable_autoformat or vim.b[buf].disable_autoformat then return nil end
        return { timeout_ms = 1000 }
      end,
    },
  },
}
