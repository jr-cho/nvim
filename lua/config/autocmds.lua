-- General autocmds (IDE layout lives in ide/layout.lua).
local aug = vim.api.nvim_create_augroup("config_autocmds", { clear = true })
local au = vim.api.nvim_create_autocmd

au("TextYankPost", {
  group = aug,
  desc = "Highlight yanked text",
  callback = function() vim.hl.on_yank() end,
})

au("BufReadPost", {
  group = aug,
  desc = "Restore last cursor position",
  callback = function(ev)
    local mark = vim.api.nvim_buf_get_mark(ev.buf, '"')
    local lines = vim.api.nvim_buf_line_count(ev.buf)
    if mark[1] > 0 and mark[1] <= lines then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

au("FileType", {
  group = aug,
  desc = "Close help-like windows with q",
  pattern = { "help", "qf", "checkhealth", "lspinfo", "man", "query" },
  callback = function(ev)
    vim.bo[ev.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = ev.buf, silent = true, desc = "Close window" })
  end,
})

au("VimResized", {
  group = aug,
  desc = "Re-apply IDE layout on resize",
  callback = function()
    local ok, layout = pcall(require, "ide.layout")
    if ok then pcall(layout.fix) end
  end,
})
