-- Autocommands. Each one gets its own named group so it can be found and
-- cleared, and so a test can assert it exists.
local function group(name)
	return vim.api.nvim_create_augroup(name, { clear = true })
end

-- Flash what was just yanked. The only feedback that a yank happened.
vim.api.nvim_create_autocmd("TextYankPost", {
	group = group("user_yank"),
	callback = function()
		vim.hl.on_yank({ timeout = 150 })
	end,
})

-- Reopen a file on the line you left it. Skips the case where the mark points
-- past the end of the file, which happens after the file shrank.
vim.api.nvim_create_autocmd("BufReadPost", {
	group = group("user_lastpos"),
	callback = function(args)
		local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
		if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(args.buf) then
			pcall(vim.api.nvim_win_set_cursor, 0, mark)
		end
	end,
})

-- Create the parent directory when saving to a path that does not exist yet.
-- Without this, :w on notes/week3/limits.md fails and you lose the buffer's
-- contents to a retry.
vim.api.nvim_create_autocmd("BufWritePre", {
	group = group("user_mkdir"),
	callback = function(args)
		if args.match:match("^%w%w+://") then
			return
		end
		vim.fn.mkdir(vim.fn.fnamemodify(args.match, ":p:h"), "p")
	end,
})

-- Close scratch windows with q. These are windows you read and dismiss, and
-- reaching for :q on them is friction with no purpose.
vim.api.nvim_create_autocmd("FileType", {
	group = group("user_quickclose"),
	pattern = { "help", "qf", "man", "checkhealth", "lspinfo" },
	callback = function(args)
		vim.bo[args.buf].buflisted = false
		vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = args.buf, silent = true })
	end,
})
