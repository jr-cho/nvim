-- claudecode.nvim: Claude Code, talking to this editor.
--
-- The plugin opens a WebSocket server and writes a lock file under
-- ~/.claude/ide/. The claude CLI finds that file and connects, which is the
-- same protocol the VS Code extension speaks. Claude then sees the current
-- selection, opens files here, and shows its edits as diffs to accept or deny.
vim.pack.add({ { src = "https://github.com/coder/claudecode.nvim", name = "claudecode" } })

require("claudecode").setup({
	terminal = {
		-- The native provider, which is Neovim's own terminal in a split. The
		-- previous config used snacks, and snacks is not in this one.
		provider = "native",
		split_side = "right",
		split_width_percentage = 0.4,
	},
})

-- vim.keymap.set, not the global Keymap. Keymap is defined in
-- lua/config/binds.lua, which init.lua requires after this file, so the global
-- does not exist yet while a plugin module is loading.
local function map(mode, lhs, rhs, desc)
	vim.keymap.set(mode, lhs, rhs, { noremap = true, silent = true, desc = desc })
end

-- Normal mode only. A terminal forwards every keystroke, so a terminal-mode
-- <leader>a... would fire while typing to Claude.
map("n", "<leader>ac", "<cmd>ClaudeCode<cr>", "Toggle Claude")
map("n", "<leader>af", "<cmd>ClaudeCodeFocus<cr>", "Focus Claude")
map("n", "<leader>ar", "<cmd>ClaudeCode --resume<cr>", "Resume a Claude session")
map("n", "<leader>aC", "<cmd>ClaudeCode --continue<cr>", "Continue last Claude session")
map("n", "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", "Select Claude model")
map("n", "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", "Add buffer to Claude")

-- Visual mode sends the selected lines as an @file#Lstart-end mention.
map("v", "<leader>as", "<cmd>ClaudeCodeSend<cr>", "Send selection to Claude")

-- Answers to a diff Claude has proposed.
map("n", "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", "Accept Claude diff")
map("n", "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", "Deny Claude diff")

-- Hide Claude from inside its own terminal.
map("t", "<A-a>", "<cmd>ClaudeCodeFocus<cr>", "Hide Claude")
