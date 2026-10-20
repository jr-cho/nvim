-- Neovim 0.12+ config: vim.pack, native LSP, native completion

vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- experimental 0.12 message/cmdline UI: no "Press ENTER", highlighted cmdline
-- require("vim._core.ui2").enable()

-- options -------------------------------------------------------------------
local o = vim.opt
o.number = true
o.relativenumber = true
o.cursorline = true
o.cursorlineopt = "number" -- NvChad style: highlight line number only
o.signcolumn = "yes"
o.laststatus = 3           -- one global statusline (default one shows diagnostics + LSP progress)
o.fillchars = { eob = " " } -- hide ~ after end of buffer

o.expandtab = true
o.shiftwidth = 4
o.tabstop = 4
o.smartindent = true

o.ignorecase = true
o.smartcase = true
o.splitright = true
o.splitbelow = true
o.scrolloff = 8
o.wrap = false

o.mouse = "a"
o.clipboard = "unnamedplus"
o.undofile = true
o.updatetime = 250
o.timeoutlen = 400

o.winborder = "single" -- border on all floats (hover, diagnostics, signature)
o.pumborder = "single" -- border on completion menu (0.12)
o.pumheight = 12
o.completeopt = { "menuone", "noselect", "popup", "fuzzy" }

-- autocmds ------------------------------------------------------------------
vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Flash yanked text",
  callback = function() vim.hl.on_yank() end,
})

-- colorscheme (local file, no plugin) ---------------------------------------
vim.cmd.colorscheme("chadone")

-- diagnostics ---------------------------------------------------------------
vim.diagnostic.config({
  virtual_text = true, -- off by default since 0.11
  severity_sort = true,
})

-- lsp: server configs live in lsp/<name>.lua --------------------------------
vim.lsp.enable({ "clangd", "ty", "ruff" })

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("my.lsp", {}),
  callback = function(ev)
    local client = assert(vim.lsp.get_client_by_id(ev.data.client_id))
    local buf = ev.buf

    -- ty handles hover for Python; ruff only lints + formats
    if client.name == "ruff" then
      client.server_capabilities.hoverProvider = false
    end

    -- native completion: C-n/C-p move, C-y accept, C-e close
    if client:supports_method("textDocument/completion") then
      -- also trigger on letters, not just server trigger chars like "." and "->"
      local provider = client.server_capabilities.completionProvider
      provider.triggerCharacters = provider.triggerCharacters or {}
      for c in ("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_"):gmatch(".") do
        table.insert(provider.triggerCharacters, c)
      end
      vim.lsp.completion.enable(true, client.id, buf, { autotrigger = true })
    end

    -- format on save: clangd (uses .clang-format) and ruff
    if client:supports_method("textDocument/formatting") then
      vim.api.nvim_create_autocmd("BufWritePre", {
        group = vim.api.nvim_create_augroup("my.lsp.format." .. buf, { clear = true }),
        buffer = buf,
        callback = function()
          vim.lsp.buf.format({ bufnr = buf, id = client.id, timeout_ms = 1000 })
        end,
      })
    end
  end,
})

-- plugins (vim.pack) --------------------------------------------------------
-- build hooks must exist before the first vim.pack.add() call
vim.api.nvim_create_autocmd("PackChanged", {
  callback = function(ev)
    local name, kind = ev.data.spec.name, ev.data.kind
    if kind ~= "install" and kind ~= "update" then return end

    if name == "telescope-fzf-native.nvim" then
      vim.system({ "make" }, { cwd = ev.data.path }):wait()
    elseif name == "nvim-treesitter" and kind == "update" then
      if not ev.data.active then vim.cmd.packadd("nvim-treesitter") end
      vim.cmd("TSUpdate")
    end
  end,
})

-- order matters: mason puts tools on PATH before treesitter needs them
for _, plugin in ipairs({ "snacks", "mason", "treesitter", "telescope" }) do
  require("plugins." .. plugin)
end

-- keybinds last, so plugin modules exist
require("keymaps")
