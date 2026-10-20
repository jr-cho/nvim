-- all keybinds in one place. loaded last (after plugins) from init.lua
local map = vim.keymap.set

-- general ---------------------------------------------------------------------
map("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight" })
map("n", "<C-s>", "<cmd>w<cr>", { desc = "Save" })
map("v", "<", "<gv", { desc = "Indent left, keep selection" })
map("v", ">", ">gv", { desc = "Indent right, keep selection" })

-- window movement: <C-hjkl> from normal AND terminal mode --------------------
for key, dir in pairs({ h = "left", j = "down", k = "up", l = "right" }) do
  map({ "n", "t" }, "<C-" .. key .. ">", "<cmd>wincmd " .. key .. "<cr>", { desc = "Window " .. dir })
end

-- file tree (snacks explorer) -------------------------------------------------
local function toggle_tree()
  local open = Snacks.picker.get({ source = "explorer" })
  if #open > 0 then
    for _, picker in ipairs(open) do picker:close() end
  else
    Snacks.explorer() -- follow_file is on by default: opens at current file
  end
end
map("n", "<C-n>", toggle_tree, { desc = "Toggle file tree" })
map("n", "<leader>e", toggle_tree, { desc = "Toggle file tree" })

-- terminals (snacks) ----------------------------------------------------------
-- NvChad binds. each kind keeps its own shell session (separate id via count)
local function term(id, win)
  return function() Snacks.terminal.toggle(nil, { count = id, win = win }) end
end
map({ "n", "t" }, "<A-i>", term(101, { position = "float", border = "single", width = 0.8, height = 0.7 }), { desc = "Toggle floating terminal" })
map({ "n", "t" }, "<A-h>", term(102, { position = "bottom", height = 0.3 }), { desc = "Toggle horizontal terminal" })
map({ "n", "t" }, "<A-v>", term(103, { position = "right", width = 0.4 }), { desc = "Toggle vertical terminal" })
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" }) -- for plain :terminal too

-- telescope -------------------------------------------------------------------
local tb = function(name) return function() require("telescope.builtin")[name]() end end
map("n", "<leader>ff", tb("find_files"), { desc = "Find files" })
map("n", "<leader>fg", tb("live_grep"), { desc = "Live grep" })
map("n", "<leader>fb", tb("buffers"), { desc = "Buffers" })
map("n", "<leader>fo", tb("oldfiles"), { desc = "Recent files" })
map("n", "<leader>fh", tb("help_tags"), { desc = "Help" })
map("n", "<leader>fd", tb("diagnostics"), { desc = "Diagnostics" })
map("n", "<leader>fw", tb("grep_string"), { desc = "Grep word under cursor" })

-- lsp (built-in defaults: K, grn, gra, grr, gri, grt, gO, <C-s> in insert) ----
map("i", "<C-Space>", function() vim.lsp.completion.get() end, { desc = "Trigger completion" })
map("n", "<leader>ih", function()
  vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
end, { desc = "Toggle inlay hints" })
