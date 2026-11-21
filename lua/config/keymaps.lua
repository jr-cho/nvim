-- All global keymaps.
local map = vim.keymap.set
local function sn(path, opts)
  return function()
    local fn = Snacks
    for part in path:gmatch("[^.]+") do
      fn = fn[part]
    end
    fn(opts)
  end
end
-- Pickers (leader / g prefixes)
local picks = {
  ["<leader><leader>"] = "smart",
  ["<leader>ff"] = "files",
  ["<leader>fg"] = "grep",
  ["<leader>fr"] = "recent",
  ["<leader>fp"] = "projects",
  ["<leader>fG"] = "git_files",
  ["<leader>fs"] = "git_status",
  ["<leader>fh"] = "help",
  ["<leader>fk"] = "keymaps",
  ["<leader>fl"] = "lsp_symbols",
  ["<leader>fL"] = "lsp_workspace_symbols",
  ["<leader>b"] = "buffers",
  ["<leader>d"] = "diagnostics",
  ["<leader>p"] = "commands",
  ["<leader>Gl"] = "git_log",
  gd = "lsp_definitions",
  grr = "lsp_references",
  gri = "lsp_implementations",
  grt = "lsp_type_definitions",
}
for lhs, p in pairs(picks) do
  map("n", lhs, sn("picker." .. p), { desc = p })
end
map({ "n", "x" }, "<leader>fw", sn("picker.grep_word"), { desc = "grep_word" })
map("n", "<leader>fc", sn("picker.files", { cwd = vim.fn.stdpath("config") }), { desc = "Config files" })
-- netrw in the current window; <leader>e toggles back to the file (inside netrw, `-` goes up a dir)
map("n", "-", "<cmd>Explore<cr>", { desc = "Netrw" })
map("n", "<leader>e", function()
  if vim.bo.filetype ~= "netrw" then
    return vim.cmd.Explore()
  end
  if not pcall(vim.cmd.Rexplore) then
    pcall(vim.cmd.buffer, "#")
  end
end, { desc = "Toggle netrw" })
-- Git, terminal, buffers
map("n", "<leader>g", sn("lazygit"), { desc = "Lazygit" })
map("n", "<leader>t", sn("terminal"), { desc = "Terminal" })
for _, k in ipairs({ "<C-`>", "<C-@>" }) do
  map({ "n", "t" }, k, sn("terminal"), { desc = "Terminal" })
end
map("n", "<leader>x", sn("bufdelete"), { desc = "Close buffer" })
map("n", "<Tab>", "<cmd>bnext<cr>", { desc = "Next buffer" })
map("n", "<S-Tab>", "<cmd>bprevious<cr>", { desc = "Prev buffer" })
-- LSP
map({ "n", "x" }, "<leader>la", vim.lsp.buf.code_action, { desc = "Code action" })
map("n", "<leader>lr", vim.lsp.buf.rename, { desc = "Rename" })
map({ "n", "x" }, "<leader>lf", function()
  vim.lsp.buf.format({ async = true })
end, { desc = "Format" })
map("n", "<leader>li", "<cmd>checkhealth vim.lsp<cr>", { desc = "LSP info" })
map("n", "<leader>ls", function()
  local c = vim.lsp.get_clients({ bufnr = 0, name = "clangd" })[1]
  if not c then
    return vim.notify("clangd is not attached", vim.log.levels.WARN)
  end
  c:request("textDocument/switchSourceHeader", vim.lsp.util.make_text_document_params(0), function(_, r)
    if r then
      vim.cmd.edit(vim.uri_to_fname(r))
    end
  end, 0)
end, { desc = "Switch source/header" })
-- Build / run
map("n", "<leader>cb", "<cmd>make<cr>", { desc = "Build" })
map("n", "<leader>cr", function()
  local root = vim.fs.find("pyproject.toml", { upward = true, path = vim.api.nvim_buf_get_name(0) })[1]
  if vim.bo.filetype == "python" then
    return Snacks.terminal(root and "uv run " .. vim.fn.expand("%") or "python3 " .. vim.fn.expand("%"))
  end
  vim.ui.input({ prompt = "Run: ", default = vim.g.run_cmd }, function(c)
    if c and c ~= "" then
      vim.g.run_cmd = c
      Snacks.terminal(c)
    end
  end)
end, { desc = "Run" })
-- Toggles
map("n", "<leader>uf", "<cmd>FormatToggle<cr>", { desc = "Toggle format on save" })
map("n", "<leader>uw", function()
  vim.wo.wrap = not vim.wo.wrap
end, { desc = "Toggle wrap" })
map("n", "<leader>uh", function()
  vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = 0 }), { bufnr = 0 })
end, { desc = "Toggle inlay hints" })
map("n", "<leader>ud", function()
  vim.diagnostic.enable(not vim.diagnostic.is_enabled())
end, { desc = "Toggle diagnostics" })
-- pi coding agent
map("n", "<leader>a", function()
  require("config.pi").toggle()
end, { desc = "pi" })
map({ "n", "x" }, "<leader>A", function()
  require("config.pi").send()
end, { desc = "pi: send reference" })
-- Editing / windows
map({ "n", "i", "v" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save" })
map("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight" })
map("t", "<Esc><Esc>", [[<C-\><C-n>]], { desc = "Terminal normal mode" })
for _, k in ipairs({ "<", ">" }) do
  map("v", k, k .. "gv")
end
for _, k in ipairs({ "h", "j", "k", "l" }) do
  map("n", "<C-" .. k .. ">", "<C-w>" .. k, { desc = "Window " .. k })
  map("t", "<A-" .. k .. ">", "<C-\\><C-n><C-w>" .. k, { desc = "Window " .. k })
end

-- which-key: pressing <leader> waits and shows the available keys
require("which-key").setup({
  preset = "classic",
  icons = { mappings = false },
  win = { border = "single" },
  spec = {
    { "<leader>f", group = "find" },
    { "<leader>l", group = "lsp" },
    { "<leader>c", group = "build" },
    { "<leader>G", group = "git" },
    { "<leader>u", group = "toggles" },
  },
})
