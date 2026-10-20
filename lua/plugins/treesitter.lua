-- nvim-treesitter (main branch): installs parsers only
-- highlighting is built into nvim via vim.treesitter.start()
vim.pack.add({
  { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
})

local parsers = {
  "c", "cpp", "python", "lua",
  "vim", "vimdoc", "query", "bash",
  "markdown", "markdown_inline",
}

local function install_parsers()
  require("nvim-treesitter").install(parsers) -- async, no-op if already installed
end

if vim.fn.executable("tree-sitter") == 1 then
  install_parsers()
else
  -- first launch: wait for mason to install tree-sitter-cli
  vim.api.nvim_create_autocmd("User", {
    pattern = "MasonToolInstalled",
    callback = function(ev)
      if ev.data == "tree-sitter-cli" then
        install_parsers()
        return true -- remove autocmd
      end
    end,
  })
end

vim.api.nvim_create_autocmd("FileType", {
  callback = function(args)
    -- pcall: skip filetypes with no parser installed
    if not pcall(vim.treesitter.start, args.buf) then return end
    vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end,
})
