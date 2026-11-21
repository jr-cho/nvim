local filters = {
  lua = function(buf)
    local has_cfg = vim.fs.find(
      { "stylua.toml", ".stylua.toml" },
      { upward = true, path = vim.fs.dirname(vim.api.nvim_buf_get_name(buf)) }
    )[1]
    local cmd = { "stylua", "-" }
    if not has_cfg then
      vim.list_extend(cmd, { "--indent-type", "Spaces", "--indent-width", "4" })
    end
    return cmd
  end,
  c = function(buf)
    local name = vim.api.nvim_buf_get_name(buf)
    local has_cfg = vim.fs.find({ ".clang-format", "_clang-format" }, { upward = true, path = vim.fs.dirname(name) })[1]
    -- --fallback-style only takes preset names, so pass an inline style when no config exists
    return {
      "clang-format",
      "--assume-filename=" .. name,
      has_cfg and "--style=file" or "--style={BasedOnStyle: LLVM, IndentWidth: 4}",
    }
  end,
  sh = function()
    return { "shfmt" }
  end,
  bash = function()
    return { "shfmt" }
  end,
}
filters.cpp = filters.c

local function format(buf)
  if vim.g.disable_autoformat or vim.b[buf].disable_autoformat then
    return
  end
  local filter = filters[vim.bo[buf].filetype]
  if filter then
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local ok, res = pcall(function()
      return vim.system(filter(buf), { stdin = table.concat(lines, "\n") .. "\n" }):wait()
    end)
    if ok and res.code == 0 and res.stdout and res.stdout ~= "" then
      local out = vim.split(res.stdout:gsub("\n$", ""), "\n", { plain = true })
      if not vim.deep_equal(out, lines) then
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, out)
      end
    end
  elseif #vim.lsp.get_clients({ bufnr = buf, method = "textDocument/formatting" }) > 0 then
    vim.lsp.buf.format({ bufnr = buf, timeout_ms = 1000 })
  end
end

vim.api.nvim_create_autocmd("BufWritePre", {
  group = vim.api.nvim_create_augroup("config_format", { clear = true }),
  callback = function(ev)
    format(ev.buf)
  end,
})

vim.api.nvim_create_user_command("FormatToggle", function(o)
  local scope = o.bang and vim.b or vim.g
  scope.disable_autoformat = not scope.disable_autoformat
  vim.notify("Autoformat " .. (scope.disable_autoformat and "disabled" or "enabled") .. (o.bang and " (buffer)" or ""))
end, { bang = true, desc = "Toggle format on save (! = buffer only)" })
