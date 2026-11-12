-- LSP: mason (installer), mason-lspconfig (auto-enable), nvim-lspconfig (server defaults), lazydev.
-- Per-server overrides live in lsp/<server>.lua.
local icons = require("ide.icons").diagnostics

local function setup_diagnostics()
  local E = vim.diagnostic.severity
  vim.diagnostic.config({
    virtual_text = { prefix = "●" },
    severity_sort = true,
    underline = true,
    update_in_insert = false,
    float = { border = "single", source = true },
    signs = {
      text = { [E.ERROR] = icons.Error, [E.WARN] = icons.Warn, [E.INFO] = icons.Info, [E.HINT] = icons.Hint },
    },
  })
end

-- Non-LSP tools (formatters, linters, debug adapters) installed through the mason registry.
local function ensure_tools()
  local tools = { "clang-format", "stylua", "shfmt", "shellcheck", "debugpy" }
  local registry = require("mason-registry")
  registry.refresh(function()
    for _, name in ipairs(tools) do
      local ok, pkg = pcall(registry.get_package, name)
      if ok and not pkg:is_installed() and not pkg:is_installing() then
        pkg:install()
      end
    end
  end)
end

return {
  { "neovim/nvim-lspconfig", event = { "BufReadPre", "BufNewFile" } },
  {
    "mason-org/mason.nvim",
    version = "^2",
    cmd = "Mason",
    build = ":MasonUpdate",
    opts = { ui = { border = "single" } },
  },
  {
    "mason-org/mason-lspconfig.nvim",
    version = "^2",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = { "mason-org/mason.nvim", "neovim/nvim-lspconfig", "saghen/blink.cmp" },
    config = function()
      setup_diagnostics()

      -- Advertise blink.cmp capabilities to every server.
      local ok, blink = pcall(require, "blink.cmp")
      if ok then
        vim.lsp.config("*", { capabilities = blink.get_lsp_capabilities() })
      end

      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("ide_lsp_attach", { clear = true }),
        callback = function(ev)
          local client = vim.lsp.get_client_by_id(ev.data.client_id)
          if not client then return end
          if client.name == "ruff" then
            client.server_capabilities.hoverProvider = false -- ty provides hover
          end
          if client:supports_method("textDocument/inlayHint") then
            vim.lsp.inlay_hint.enable(true, { bufnr = ev.buf })
          end
        end,
      })

      local servers = { "clangd", "lua_ls", "bashls", "neocmake", "ty", "ruff" }

      require("mason-lspconfig").setup({ ensure_installed = servers, automatic_enable = { exclude = { "stylua" } } }) -- stylua is run by conform
      ensure_tools()
    end,
  },
  {
    "folke/lazydev.nvim",
    ft = "lua",
    opts = {
      library = {
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
        "snacks.nvim",
      },
    },
  },
}
