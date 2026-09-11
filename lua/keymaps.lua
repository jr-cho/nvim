-- Keymaps that belong to no plugin. Anything a plugin owns is declared in that
-- plugin's spec instead, so the spec is the whole story for that plugin.
local function map(mode, lhs, rhs, desc, opts)
	opts = vim.tbl_extend("force", { silent = true, desc = desc }, opts or {})
	vim.keymap.set(mode, lhs, rhs, opts)
end

-- Move by display line when no count is given. 5j still moves five real lines,
-- so counts and macros behave as they did before soft wrap was turned on.
map("n", "j", "v:count == 0 ? 'gj' : 'j'", "Down", { expr = true })
map("n", "k", "v:count == 0 ? 'gk' : 'k'", "Up", { expr = true })

-- Keep the cursor centred through half-page jumps and search hits.
map("n", "<C-d>", "<C-d>zz", "Half page down")
map("n", "<C-u>", "<C-u>zz", "Half page up")
map("n", "n", "nzzzv", "Next match")
map("n", "N", "Nzzzv", "Previous match")

-- Move the selected lines and reindent them.
map("v", "J", ":m '>+1<CR>gv=gv", "Move selection down")
map("v", "K", ":m '<-2<CR>gv=gv", "Move selection up")

-- Stay in visual mode after shifting, so > > > is three presses of one key.
map("v", "<", "<gv", "Unindent selection")
map("v", ">", ">gv", "Indent selection")

-- Paste over a selection without losing the register.
map("x", "<leader>p", [["_dP]], "Paste without yanking selection")

-- Window navigation, including out of a terminal buffer. <C-\><C-n> leaves
-- terminal mode first, otherwise the keys are typed into the shell.
for _, dir in ipairs({ "h", "j", "k", "l" }) do
	map("n", "<C-" .. dir .. ">", "<cmd>wincmd " .. dir .. "<CR>", "Window " .. dir)
	map("t", "<C-" .. dir .. ">", "<C-\\><C-n><cmd>wincmd " .. dir .. "<CR>", "Window " .. dir)
end
-- No <C-d> map in terminal mode.
--
-- It used to leave terminal mode, which stole the key from the shell. <C-d> is
-- EOF everywhere else and is how a shell is normally closed, so mapping it
-- meant `exit` was the only way out of the terminal.
--
-- The map bought nothing either way: snacks binds <Esc><Esc> to leave terminal
-- mode, and Neovim's own <C-\><C-n> still works.

-- Window size, without a mouse.
map("n", "<C-Up>", "<cmd>resize +2<CR>", "Taller window")
map("n", "<C-Down>", "<cmd>resize -2<CR>", "Shorter window")
map("n", "<C-Left>", "<cmd>vertical resize -2<CR>", "Narrower window")
map("n", "<C-Right>", "<cmd>vertical resize +2<CR>", "Wider window")

-- Buffers.
map("n", "<S-h>", "<cmd>bprevious<CR>", "Previous buffer")
map("n", "<S-l>", "<cmd>bnext<CR>", "Next buffer")

-- Diagnostics. These are not LSP-specific: vim.diagnostic covers any source.
map("n", "<leader>d", vim.diagnostic.open_float, "Diagnostic float")
map("n", "]d", function()
	vim.diagnostic.jump({ count = 1, float = true })
end, "Next diagnostic")
map("n", "[d", function()
	vim.diagnostic.jump({ count = -1, float = true })
end, "Previous diagnostic")

-- Clear search highlight and any floating window left over.
map("n", "<Esc>", "<cmd>nohlsearch<CR>", "Clear search highlight")
