-- Treesitter (main branch): async parser install + highlight/indent per filetype.
local parsers = {
  "c", "cpp", "python", "bash", "lua", "luadoc", "cmake", "make",
  "json", "yaml", "toml", "markdown", "markdown_inline", "vim", "vimdoc", "query", "regex",
  "diff", "gitcommit", "git_rebase",
}

return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      -- parser compilation needs the tree-sitter CLI, which mason provides
      local mason_bin = vim.fn.stdpath("data") .. "/mason/bin"
      if not vim.env.PATH:find(mason_bin, 1, true) then
        vim.env.PATH = vim.env.PATH .. ":" .. mason_bin
      end

      local ts = require("nvim-treesitter")
      ts.setup()
      if vim.fn.executable("tree-sitter") == 1 then
        local installed = ts.get_installed("parsers")
        local missing = vim.tbl_filter(function(p) return not vim.list_contains(installed, p) end, parsers)
        if #missing > 0 then ts.install(missing) end -- async
      end

      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("ide_treesitter", { clear = true }),
        callback = function(ev)
          if not pcall(vim.treesitter.start, ev.buf) then return end
          vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end,
      })
    end,
  },
}
