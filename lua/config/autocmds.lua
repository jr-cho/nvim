-- General autocmds.
local aug = vim.api.nvim_create_augroup("config_autocmds", { clear = true })
local au = vim.api.nvim_create_autocmd

au("TextYankPost", {
  group = aug,
  desc = "Highlight yanked text",
  callback = function()
    vim.hl.on_yank()
  end,
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

-- filetype -> parser names that differ (nvim-treesitter used to register these)
vim.treesitter.language.register("latex", { "tex", "plaintex" })
vim.treesitter.language.register("bash", { "sh" })
vim.treesitter.language.register("git_rebase", { "gitrebase" })

au("FileType", {
  group = aug,
  desc = "Treesitter highlight/indent",
  callback = function(ev)
    if pcall(vim.treesitter.start, ev.buf) and vim.treesitter.indentexpr then
      vim.bo[ev.buf].indentexpr = "v:lua.vim.treesitter.indentexpr()"
    end
  end,
})

au({ "FocusGained", "BufEnter", "TermLeave" }, {
  group = aug,
  desc = "Reload files changed on disk",
  callback = function()
    if vim.fn.mode() ~= "c" then
      vim.cmd("checktime")
    end
  end,
})

au({ "BufEnter", "FileType" }, {
  group = aug,
  desc = "Buffer-local makeprg",
  callback = function(ev)
    if vim.bo[ev.buf].buftype ~= "" then
      return
    end
    if vim.bo[ev.buf].filetype == "tex" then
      vim.bo[ev.buf].makeprg = "latexmk -pdf -interaction=nonstopmode -synctex=1 %"
    elseif vim.fs.find("CMakeLists.txt", { upward = true, path = vim.api.nvim_buf_get_name(ev.buf) })[1] then
      vim.bo[ev.buf].makeprg = "cmake --build build"
    elseif vim.fs.find("Makefile", { upward = true, path = vim.api.nvim_buf_get_name(ev.buf) })[1] then
      vim.bo[ev.buf].makeprg = "make -j"
    end
  end,
})

au("QuickFixCmdPost", { group = aug, pattern = "[^l]*", command = "cwindow" })
