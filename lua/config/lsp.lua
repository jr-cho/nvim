vim.g.tex_flavor = "latex"

vim.diagnostic.config({
  virtual_text = true,
  severity_sort = true,
  float = { border = "single", source = true },
})

vim.lsp.enable({ "clangd", "lua_ls", "bashls", "neocmake", "ty", "ruff", "texlab" })

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("config_lsp_attach", { clear = true }),
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if not client then
      return
    end
    if client:supports_method("textDocument/completion") then
      vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
    end
    if client:supports_method("textDocument/inlayHint") then
      vim.lsp.inlay_hint.enable(true, { bufnr = ev.buf })
    end
    if client.name == "ruff" then
      client.server_capabilities.hoverProvider = false
    end
  end,
})
