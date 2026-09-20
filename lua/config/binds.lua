-- Keymap function
function Keymap(mode, key, binding, opts)
	local options = { noremap = true, silent = true }
	if opts then
		options = vim.tbl_extend("force", options, opts)
	end
	vim.keymap.set(mode, key, binding, options)
end

Keymap("n", "q:", ":") -- remove nonsense command
Keymap("n", "<leader>bd", function() -- delete buffer
	vim.cmd("bd")
	vim.cmd("echo 'Buffer deleted'")
end, { desc = "Delete buffer" })

-- Entering insert on a blank line clears its whitespace first, so the cursor
-- starts at the indent the file actually wants.
for _, bind in ipairs({ "i", "a", "A", "I" }) do
	Keymap("n", bind, function()
		if vim.fn.getline("."):match("^%s*$") then
			return [["_cc]]
		else
			return bind
		end
	end, { expr = true })
end

Keymap("i", "<C-BS>", "<C-W>") -- C-Backspace for whole words

Keymap("n", "<leader>d", "<cmd>lua vim.diagnostic.open_float()<CR>", { desc = "Diagnostic float" })
Keymap("n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>", { desc = "Go to definition" })

-- Terminal
Keymap("n", "<leader>tj", function() -- open term in new pane
	vim.cmd.vnew()
	vim.cmd.term()
	vim.cmd.startinsert()
end, { desc = "Terminal in a split" })
Keymap("n", "<leader>tk", function() -- open term in new tab
	vim.cmd.tabnew()
	vim.cmd.term()
	vim.cmd.startinsert()
end, { desc = "Terminal in a tab" })
Keymap("t", "<C-D>", "<C-\\><C-n>") -- escape terminal with c-d

-- Flash
Keymap("n", "ss", function()
	require("flash").jump({
		search = {
			mode = "fuzzy",
		},
		highlight = {
			backdrop = true,
		},
	})
end, { desc = "Flash jump" })
Keymap("n", "S", function()
	require("flash").treesitter()
end, { desc = "Flash treesitter" })
Keymap("n", "<leader>r", function()
	require("flash").remote()
end, { desc = "Flash remote" })
Keymap("n", "<leader>R", function()
	require("flash").treesitter_search()
end, { desc = "Flash treesitter search" })

-- Sessions
Keymap("n", "<leader>qj", function() -- quit and save session
	require("mini.sessions").write(".session")
	vim.cmd("wqa")
end, { desc = "Write session, then quit" })

Keymap("n", "<leader>qd", function() -- quit and delete session
	require("mini.sessions").delete(".session")
	vim.cmd("wqa")
end, { desc = "Delete session, then quit" })

-- Telescope
local builtin = require("telescope.builtin")

Keymap("n", "<leader>ff", function()
	builtin.find_files({ hidden = true })
end, { desc = "Find files" })

Keymap("n", "<leader>fn", function()
	local full_path = vim.api.nvim_buf_get_name(0)
	local dir = vim.fn.fnamemodify(full_path, ":h")
	require("telescope").extensions.file_browser.file_browser({
		path = dir,
	})
end, { desc = "File browser" })

Keymap("n", "<leader>fs", function() -- select sessions
	MiniSessions.select()
end, { desc = "Pick a session" })

Keymap("n", "<leader>fd", function() -- delete sessions
	MiniSessions.select("delete")
end, { desc = "Delete a session" })

Keymap("n", "<leader>fg", function()
	builtin.live_grep({ hidden = true })
end, { desc = "Live grep" })

Keymap("n", "<leader>fb", function()
	builtin.buffers({ show_all_buffers = true })
end, { desc = "Open buffers" })

-- Tabs
Keymap("n", "<C-T>l", function()
	vim.cmd("tabnext")
end, { desc = "Next tab" })

Keymap("n", "<C-T>h", function()
	vim.cmd("tabprevious")
end, { desc = "Previous tab" })

Keymap("n", "<C-T>j", function()
	vim.cmd("tabnew")
end, { desc = "New tab" })

Keymap("n", "<C-T>q", function()
	vim.cmd("tabclose")
end, { desc = "Close tab" })
