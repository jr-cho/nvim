-- lua_ls: tuned for Neovim config editing (library paths are added by lazydev).
return {
  settings = {
    Lua = {
      runtime = { version = "LuaJIT" },
      completion = { callSnippet = "Replace" },
      workspace = { checkThirdParty = false },
      diagnostics = { globals = { "vim" } },
      hint = { enable = true },
      telemetry = { enable = false },
    },
  },
}
