local M = {}

local opts = { count = 1, win = { position = "right", width = 0.4 } }

function M.toggle()
  Snacks.terminal.toggle("pi", opts)
end

function M.send()
  local name = vim.api.nvim_buf_get_name(0)
  if name == "" then
    return vim.notify("pi: buffer has no file", vim.log.levels.WARN)
  end
  local text = "@" .. vim.fn.fnamemodify(name, ":.")
  local mode = vim.fn.mode()
  if mode:match("^[vV\22]") then
    local a, b = vim.fn.line("v"), vim.fn.line(".")
    if a > b then
      a, b = b, a
    end
    text = text .. (a == b and " (line %d)" or " (lines %d-%d)"):format(a, b)
    vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "nx", false)
  end
  local term = Snacks.terminal.get("pi", opts)
  if not term then
    return
  end
  term:show()
  term:focus()
  local job = vim.b[term.buf].terminal_job_id
  if job then
    vim.fn.chansend(job, text .. " ")
  end
  vim.cmd.startinsert()
end

return M
