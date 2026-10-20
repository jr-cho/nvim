-- mason: installs external binaries into nvim's data dir and puts them on PATH
-- installer only; LSP servers configured natively in lsp/*.lua
vim.pack.add({
  { src = "https://github.com/mason-org/mason.nvim", version = vim.version.range("2") },
})

require("mason").setup({ ui = { border = "single" } })

local tools = {
  "tree-sitter-cli", -- needed by nvim-treesitter to compile parsers
  "clangd",
  "ty",
  "ruff",
}

-- auto-install missing tools in background
local registry = require("mason-registry")
registry.refresh(function()
  for _, name in ipairs(tools) do
    local ok, pkg = pcall(registry.get_package, name)
    if ok and not pkg:is_installed() and not pkg:is_installing() then
      vim.schedule(function() vim.notify("mason: installing " .. name) end)
      pkg:install({}, function(success, err)
        vim.schedule(function()
          if not success then
            vim.notify("mason: failed " .. name .. ": " .. tostring(err), vim.log.levels.ERROR)
            return
          end
          vim.notify("mason: installed " .. name)
          -- lets treesitter react once tree-sitter-cli lands
          vim.api.nvim_exec_autocmds("User", { pattern = "MasonToolInstalled", data = name })
          -- start servers for already-open buffers
          vim.cmd("doautoall FileType")
        end)
      end)
    end
  end
end)
