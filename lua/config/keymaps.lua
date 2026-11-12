-- All global keymaps. ide.* modules are required lazily (pcall) at call time.
local map = vim.keymap.set

local function ide(mod, fn, ...)
  local args = { ... }
  return function()
    local ok, m = pcall(require, "ide." .. mod)
    if not ok then
      vim.notify("ide." .. mod .. " is not available", vim.log.levels.WARN)
      return
    end
    if m[fn] then m[fn](unpack(args)) end
  end
end

local function snacks(path, opts)
  return function()
    local fn = Snacks
    for part in path:gmatch("[^.]+") do fn = fn[part] end
    fn(opts)
  end
end

-- Files / search
map("n", "<leader><leader>", snacks("picker.smart"), { desc = "Find files (smart)" })
map("n", "<leader>e", ide("layout", "explorer_toggle"), { desc = "Explorer" })
map("n", "<leader>ff", snacks("picker.files"), { desc = "Files" })
map("n", "<leader>fg", snacks("picker.grep"), { desc = "Live grep" })
map({ "n", "x" }, "<leader>fw", snacks("picker.grep_word"), { desc = "Grep word/selection" })
map("n", "<leader>fr", snacks("picker.recent"), { desc = "Recent files" })
map("n", "<leader>fp", snacks("picker.projects"), { desc = "Projects" })
map("n", "<leader>fG", snacks("picker.git_files"), { desc = "Git files" })
map("n", "<leader>fs", snacks("picker.git_status"), { desc = "Git status" })
map("n", "<leader>fh", snacks("picker.help"), { desc = "Help" })
map("n", "<leader>fk", snacks("picker.keymaps"), { desc = "Keymaps" })
map("n", "<leader>fl", snacks("picker.lsp_symbols"), { desc = "Document symbols" })
map("n", "<leader>fL", snacks("picker.lsp_workspace_symbols"), { desc = "Workspace symbols" })
map("n", "<leader>fc", function()
  Snacks.picker.files({ cwd = vim.fn.stdpath("config") })
end, { desc = "Config files" })

-- Single-key leader maps
map("n", "<leader>b", snacks("picker.buffers"), { desc = "Buffers" })
map("n", "<leader>g", snacks("lazygit"), { desc = "Lazygit" })
map("n", "<leader>d", snacks("picker.diagnostics"), { desc = "Diagnostics" })
map("n", "<leader>t", ide("panel", "toggle"), { desc = "Terminal panel" })
map("n", "<leader>p", snacks("picker.commands"), { desc = "Commands" })
map("n", "<leader>z", snacks("zen"), { desc = "Zen mode" })
map("n", "<leader>h", ide("docpanel", "toggle"), { desc = "Doc panel" })
map("n", "<leader>x", function()
  local win = vim.api.nvim_get_current_win()
  -- no-op in IDE / winfixbuf windows (panel, docpanel, explorer, dap-repl)
  if vim.wo[win].winfixbuf or vim.w[win].ide_role or (vim.bo.buftype ~= "" and vim.bo.buftype ~= "terminal") then return end
  Snacks.bufdelete()
end, { desc = "Close buffer" })
map("n", "<leader>o", ide("panel", "open", "problems"), { desc = "Problems panel" })

-- Bottom panel (Ctrl-` ; terminals often send <C-@>)
map({ "n", "t" }, "<C-`>", ide("panel", "toggle"), { desc = "Toggle panel" })
map({ "n", "t" }, "<C-@>", ide("panel", "toggle"), { desc = "Toggle panel" })

-- Buffers
map("n", "<Tab>", "<cmd>bnext<cr>", { desc = "Next buffer" })
map("n", "<S-Tab>", "<cmd>bprevious<cr>", { desc = "Previous buffer" })

-- LSP group
map({ "n", "x" }, "<leader>la", vim.lsp.buf.code_action, { desc = "Code action" })
map("n", "<leader>lr", vim.lsp.buf.rename, { desc = "Rename" })
map({ "n", "x" }, "<leader>lf", function()
  local ok, conform = pcall(require, "conform")
  if ok then conform.format({ async = true, lsp_format = "fallback" }) else vim.lsp.buf.format({ async = true }) end
end, { desc = "Format" })
map("n", "<leader>ls", function()
  local clients = vim.lsp.get_clients({ bufnr = 0, name = "clangd" })
  if #clients == 0 then
    vim.notify("clangd is not attached", vim.log.levels.WARN)
    return
  end
  clients[1]:request("textDocument/switchSourceHeader", vim.lsp.util.make_text_document_params(0), function(err, result)
    if err then return vim.notify(tostring(err.message or err), vim.log.levels.ERROR) end
    if not result then return vim.notify("No source/header found", vim.log.levels.INFO) end
    vim.cmd.edit(vim.uri_to_fname(result))
  end, 0)
end, { desc = "Switch source/header" })
map("n", "<leader>li", "<cmd>checkhealth vim.lsp<cr>", { desc = "LSP info" })

-- Build group
map("n", "<leader>cb", "<cmd>Build<cr>", { desc = "Build" })
map("n", "<leader>cr", "<cmd>Run<cr>", { desc = "Run" })
map("n", "<leader>ct", "<cmd>Test<cr>", { desc = "Test" })
map("n", "<leader>cc", "<cmd>CMakeConfigure<cr>", { desc = "CMake configure" })

-- Git extras (gitsigns loaded on demand)
local function gs(fn, ...)
  local args = { ... }
  return function()
    local ok, g = pcall(require, "gitsigns")
    if ok and g[fn] then g[fn](unpack(args)) end
  end
end
map("n", "<leader>Gb", gs("blame_line", { full = true }), { desc = "Blame line" })
map("n", "<leader>Gp", gs("preview_hunk"), { desc = "Preview hunk" })
map("n", "<leader>Gs", gs("stage_hunk"), { desc = "Stage hunk" })
map("n", "<leader>Gr", gs("reset_hunk"), { desc = "Reset hunk" })
map("n", "<leader>Gd", gs("diffthis"), { desc = "Diff this" })
map("n", "<leader>Gl", snacks("picker.git_log"), { desc = "Git log" })

-- Toggles (Snacks.toggle objects are created on use)
map("n", "<leader>uh", function() Snacks.toggle.inlay_hints():toggle() end, { desc = "Toggle inlay hints" })
map("n", "<leader>uf", function()
  Snacks.toggle({
    name = "Format on save",
    get = function() return not vim.g.disable_autoformat end,
    set = function(state) vim.g.disable_autoformat = not state end,
  }):toggle()
end, { desc = "Toggle format on save" })
map("n", "<leader>uw", function() Snacks.toggle.option("wrap"):toggle() end, { desc = "Toggle wrap" })
map("n", "<leader>ud", function() Snacks.toggle.diagnostics():toggle() end, { desc = "Toggle diagnostics" })
map("n", "<leader>un", function() Snacks.toggle.option("relativenumber"):toggle() end, { desc = "Toggle relative number" })
map("n", "<leader>uP", ide("panel", "toggle"), { desc = "Toggle bottom panel" })

-- LSP navigation via Snacks pickers (K stays native hover)
map("n", "gd", snacks("picker.lsp_definitions"), { desc = "Definitions" })
-- gr* keeps Neovim's built-in prefix (grn rename, gra code action, ...); no bare `gr` map.
map("n", "grr", snacks("picker.lsp_references"), { desc = "References" })
map("n", "gri", snacks("picker.lsp_implementations"), { desc = "Implementations" })
map("n", "grt", snacks("picker.lsp_type_definitions"), { desc = "Type definitions" })
map("n", "gI", snacks("picker.lsp_implementations"), { desc = "Implementations" })
map("n", "gy", snacks("picker.lsp_type_definitions"), { desc = "Type definitions" })

-- Editing conveniences
map({ "n", "i", "v" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save" })
map("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight" })
map("t", "<Esc><Esc>", [[<C-\><C-n>]], { desc = "Terminal normal mode" })
map("v", "<", "<gv", { desc = "Indent left (keep selection)" })
map("v", ">", ">gv", { desc = "Indent right (keep selection)" })

-- Window navigation
for _, k in ipairs({ "h", "j", "k", "l" }) do
  map("n", "<C-" .. k .. ">", "<C-w>" .. k, { desc = "Window " .. k })
  -- Alt in terminal mode so shell Ctrl-L / Ctrl-K / Ctrl-H keep working
  map("t", "<A-" .. k .. ">", "<C-\\><C-n><C-w>" .. k, { desc = "Window " .. k })
end
