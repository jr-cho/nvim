-- Completion: blink.cmp 1.x (prebuilt Rust fuzzy matcher) + friendly-snippets.
return {
  {
    "saghen/blink.cmp",
    version = "1.*",
    event = { "InsertEnter", "CmdlineEnter" },
    dependencies = { "rafamadriz/friendly-snippets" },
    opts = {
      keymap = {
        preset = "enter",
        ["<Tab>"] = { "snippet_forward", "select_next", "fallback" },
        ["<S-Tab>"] = { "snippet_backward", "select_prev", "fallback" },
      },
      -- Off in the DEBUG CONSOLE (Enter must submit, not accept a completion); otherwise blink's default.
      enabled = function()
        local ft = vim.bo.filetype
        return not (ft == "dap-repl" or ft == "dapui_watches" or ft == "dapui_hover")
      end,
      appearance = { nerd_font_variant = "mono" },
      completion = {
        menu = { border = "single" },
        documentation = { auto_show = true, window = { border = "single" } },
      },
      signature = { enabled = true, window = { border = "single" } },
      sources = {
        default = { "lsp", "path", "snippets", "buffer" },
        per_filetype = { lua = { inherit_defaults = true, "lazydev" } },
        providers = {
          lazydev = { name = "LazyDev", module = "lazydev.integrations.blink", score_offset = 100 },
        },
      },
      cmdline = { enabled = true, completion = { menu = { auto_show = true } } },
      fuzzy = { implementation = "prefer_rust_with_warning" },
    },
    opts_extend = { "sources.default" },
  },
  { "rafamadriz/friendly-snippets", lazy = true },
}
