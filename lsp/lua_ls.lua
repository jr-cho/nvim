return {
  cmd = { "lua-language-server" },
  filetypes = { "lua" },
  root_markers = {
    { ".emmyrc.json", ".luarc.json", ".luarc.jsonc" },
    { ".luacheckrc", ".stylua.toml", "stylua.toml" },
    { ".git" },
  },
  settings = {
    Lua = {
      runtime = { version = "LuaJIT" },
      completion = { callSnippet = "Replace" },
      workspace = { checkThirdParty = false, library = { vim.env.VIMRUNTIME } },
      hint = { enable = true },
      telemetry = { enable = false },
    },
  },
}
