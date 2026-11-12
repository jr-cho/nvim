-- Right documentation panel: LSP hover + signature help for the cursor in the last editor window.
local M = {}

local api = vim.api

local WIDTH = 50
local state = { win = nil, buf = nil, last_editor = nil, tick = 0, lines = nil }
local group = api.nvim_create_augroup("ide_docpanel", { clear = true })
local timer = vim.uv.new_timer()

function M.is_open()
  return state.win ~= nil and api.nvim_win_is_valid(state.win)
end

local function is_editor_win(w)
  if not api.nvim_win_is_valid(w) or api.nvim_win_get_config(w).relative ~= "" then
    return false
  end
  return vim.w[w].ide_role == nil and vim.bo[api.nvim_win_get_buf(w)].buftype == ""
end

local function editor_win()
  if state.last_editor and is_editor_win(state.last_editor) then
    return state.last_editor
  end
  for _, w in ipairs(api.nvim_tabpage_list_wins(0)) do
    if is_editor_win(w) then
      return w
    end
  end
end

local function get_buf()
  if state.buf and api.nvim_buf_is_valid(state.buf) then
    return state.buf
  end
  local buf = api.nvim_create_buf(false, true)
  pcall(api.nvim_buf_set_name, buf, "ide://docpanel")
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "hide"
  vim.bo[buf].buflisted = false
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "markdown"
  state.buf = buf
  return buf
end

local function render(lines)
  local buf = get_buf()
  vim.bo[buf].modifiable = true
  api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  pcall(vim.treesitter.start, buf, "markdown")
end

local function placeholder()
  render({ "# Documentation", "", "Move the cursor over a symbol (hover + signature help)." })
end

-- Request hover + signature help for the cursor in the last editor window.
local function refresh()
  if not M.is_open() then
    return
  end
  local win = editor_win()
  if not win then
    return
  end
  local buf = api.nvim_win_get_buf(win)
  if #vim.lsp.get_clients({ bufnr = buf }) == 0 then
    return
  end
  state.tick = state.tick + 1
  local tick = state.tick
  local hover, sig, pending = nil, nil, 2

  local function done()
    pending = pending - 1
    if pending > 0 or tick ~= state.tick or not M.is_open() then
      return
    end
    local lines = {}
    if hover and #hover > 0 then
      vim.list_extend(lines, { "# Hover", "" })
      vim.list_extend(lines, hover)
    end
    if sig and #sig > 0 then
      if #lines > 0 then
        lines[#lines + 1] = ""
      end
      vim.list_extend(lines, { "# Signature", "" })
      vim.list_extend(lines, sig)
    end
    if #lines > 0 then -- keep the previous content when the answer is empty
      state.lines = lines
      render(lines)
    end
  end

  local function params(client)
    return vim.lsp.util.make_position_params(win, client.offset_encoding)
  end

  vim.lsp.buf_request_all(buf, "textDocument/hover", params, function(results)
    local out = {}
    for _, r in pairs(results) do
      if r.result and r.result.contents then
        local md = vim.lsp.util.convert_input_to_markdown_lines(r.result.contents)
        md = vim.split(table.concat(md, "\n"), "\n", { plain = true, trimempty = true })
        if #md > 0 then
          vim.list_extend(out, md)
          out[#out + 1] = ""
        end
      end
    end
    hover = out
    done()
  end)

  vim.lsp.buf_request_all(buf, "textDocument/signatureHelp", params, function(results)
    local out = {}
    local ft = vim.bo[buf].filetype
    for _, r in pairs(results) do
      if r.result and r.result.signatures and #r.result.signatures > 0 then
        local md = vim.lsp.util.convert_signature_help_to_markdown_lines(r.result, ft, {})
        if md and #md > 0 then
          vim.list_extend(out, md)
        end
      end
    end
    sig = out
    done()
  end)
end

local function debounced_refresh()
  timer:stop()
  timer:start(150, 0, vim.schedule_wrap(refresh))
end

function M.scroll(delta)
  if not M.is_open() then
    return
  end
  local keys = delta > 0 and "\5" or "\25" -- <C-e> / <C-y>
  api.nvim_win_call(state.win, function()
    vim.cmd("normal! " .. math.abs(delta) .. keys)
  end)
end

local function set_keys()
  vim.keymap.set({ "n", "i" }, "<A-j>", function()
    M.scroll(3)
  end, { desc = "Scroll doc panel down" })
  vim.keymap.set({ "n", "i" }, "<A-k>", function()
    M.scroll(-3)
  end, { desc = "Scroll doc panel up" })
end

local function unset_keys()
  pcall(vim.keymap.del, { "n", "i" }, "<A-j>")
  pcall(vim.keymap.del, { "n", "i" }, "<A-k>")
end

local function layout_fix()
  local ok, layout = pcall(require, "ide.layout")
  if ok and layout.fix then
    pcall(layout.fix)
  end
end

function M.open()
  if M.is_open() then
    return
  end
  local prev = api.nvim_get_current_win()
  if is_editor_win(prev) then
    state.last_editor = prev
  end
  vim.cmd("vertical botright " .. WIDTH .. "split")
  local win = api.nvim_get_current_win()
  state.win = win
  vim.w[win].ide_role = "docpanel"
  vim.w[win].ide_width = WIDTH
  local buf = get_buf()
  api.nvim_win_set_buf(win, buf)
  local wo = vim.wo[win]
  wo.winfixbuf = true
  wo.winfixwidth = true
  wo.wrap = true
  wo.linebreak = true
  wo.number = false
  wo.relativenumber = false
  wo.signcolumn = "no"
  wo.foldcolumn = "0"
  wo.statuscolumn = ""
  wo.cursorline = false
  wo.list = false
  wo.conceallevel = 2
  wo.concealcursor = "nvic"
  wo.winhighlight = "Normal:IdeDocNormal,EndOfBuffer:IdeDocNormal,FloatTitle:IdeDocTitle"
  if state.lines then
    render(state.lines)
  else
    placeholder()
  end
  if api.nvim_win_is_valid(prev) then
    api.nvim_set_current_win(prev)
  end

  api.nvim_create_autocmd("WinClosed", {
    group = group,
    pattern = tostring(win),
    once = true,
    callback = function()
      state.win = nil
      unset_keys()
      api.nvim_clear_autocmds({ group = group, event = { "CursorHold", "CursorHoldI", "WinEnter" } })
    end,
  })
  api.nvim_create_autocmd("WinEnter", {
    group = group,
    callback = function()
      local w = api.nvim_get_current_win()
      if is_editor_win(w) then
        state.last_editor = w
      end
    end,
  })
  api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
    group = group,
    callback = function()
      if is_editor_win(api.nvim_get_current_win()) then
        state.last_editor = api.nvim_get_current_win()
        debounced_refresh()
      end
    end,
  })
  set_keys()
  layout_fix()
  if api.nvim_win_is_valid(win) then
    api.nvim_win_set_width(win, WIDTH)
  end
  debounced_refresh()
end

function M.close()
  if not M.is_open() then
    return
  end
  local w = state.win
  state.win = nil
  unset_keys()
  pcall(api.nvim_win_close, w, true)
  layout_fix()
end

function M.toggle()
  if M.is_open() then
    M.close()
  else
    M.open()
  end
end

return M
