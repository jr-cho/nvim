-- Bottom panel: TERMINAL (multiple tabs) | PROBLEMS | OUTPUT | DEBUG CONSOLE.
-- One window (role "panel") whose buffer is switched per section.
local M = {}

local api = vim.api

local SECTIONS = { "terminal", "problems", "output", "debug" }
local LABELS = { terminal = "TERMINAL", problems = "PROBLEMS", output = "OUTPUT", debug = "DEBUG CONSOLE" }

local state = {
  win = nil,
  height = 12,
  section = "terminal",
  terms = {}, -- { { buf = n, job = n }, ... }
  cur = 0, -- index into terms
  bufs = {}, -- problems / output / placeholder buffers
  problem_items = {}, -- line -> item (problems buffer)
  problem_count = 0,
  last_editor = nil,
}

local ns = api.nvim_create_namespace("ide_panel")
local group = api.nvim_create_augroup("ide_panel", { clear = true })

local function set_default_hl()
  api.nvim_set_hl(0, "IdePanelTab", { default = true, link = "StatusLine" })
  api.nvim_set_hl(0, "IdePanelTabActive", { default = true, link = "StatusLine" })
  api.nvim_set_hl(0, "IdePanelTabSep", { default = true, link = "WinSeparator" })
  api.nvim_set_hl(0, "IdePanelNormal", { default = true, link = "Normal" })
end
set_default_hl()
api.nvim_create_autocmd("ColorScheme", { group = group, callback = set_default_hl })

local function layout_fix()
  local ok, layout = pcall(require, "ide.layout")
  if ok and layout.fix then
    pcall(layout.fix)
  end
end

local function valid_win(w)
  return w ~= nil and api.nvim_win_is_valid(w)
end

function M.is_open()
  return valid_win(state.win)
end

local function is_editor_win(w)
  if not api.nvim_win_is_valid(w) or api.nvim_win_get_config(w).relative ~= "" then
    return false
  end
  if vim.w[w].ide_role ~= nil then
    return false
  end
  return vim.bo[api.nvim_win_get_buf(w)].buftype == ""
end

-- Remember the last editor window so jumps never land inside the panel.
api.nvim_create_autocmd("WinEnter", {
  group = group,
  callback = function()
    local w = api.nvim_get_current_win()
    if is_editor_win(w) then
      state.last_editor = w
    end
  end,
})

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

---------------------------------------------------------------------- buffers

local function setup_buf(buf, name)
  vim.bo[buf].buflisted = false
  vim.bo[buf].swapfile = false
  vim.bo[buf].bufhidden = "hide"
  if name then
    pcall(api.nvim_buf_set_name, buf, name)
  end
end

local function special_buf(name, ft)
  local buf = api.nvim_create_buf(false, true)
  setup_buf(buf, name)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].filetype = ft
  vim.bo[buf].modifiable = false
  vim.keymap.set("n", "q", function()
    M.close()
  end, { buffer = buf, desc = "Close panel", nowait = true })
  return buf
end

local function get_buf(kind)
  local b = state.bufs[kind]
  if not (b and api.nvim_buf_is_valid(b)) then
    b = special_buf("ide://panel/" .. kind, "ide_panel_" .. kind)
    state.bufs[kind] = b
  end
  return b
end

local function set_lines(buf, lines)
  vim.bo[buf].modifiable = true
  api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
end

---------------------------------------------------------------------- winbar

local function redraw_bar()
  if M.is_open() then
    pcall(vim.cmd, "redrawstatus!")
  end
end

-- minwid encoding: 1..4 section, 100+i terminal i, 200 "+"
function M.click(minwid, _, _, _)
  minwid = tonumber(minwid)
  if not minwid then
    return
  end
  if minwid == 200 then
    M.term_new()
  elseif minwid >= 100 then
    state.cur = minwid - 100
    M.open("terminal")
  else
    M.open(SECTIONS[minwid])
  end
end

local function tab(id, text, active)
  local hl = active and "IdePanelTabActive" or "IdePanelTab"
  return ("%%%d@v:lua.require'ide.panel'.click@%%#%s#%s%%X%%#IdePanelNormal#"):format(id, hl, text)
end

function M.winbar()
  local out = {}
  for i, s in ipairs(SECTIONS) do
    local active = state.section == s
    local label = LABELS[s]
    if s == "problems" and state.problem_count > 0 then
      label = label .. " (" .. state.problem_count .. ")"
    end
    if s == "terminal" then
      local parts = { tab(1, " TERMINAL ", active) }
      for ti = 1, #state.terms do
        local cur = ti == state.cur
        local txt = cur and (" [" .. ti .. "] ") or (" " .. ti .. " ")
        parts[#parts + 1] = tab(100 + ti, txt, active and cur)
      end
      parts[#parts + 1] = tab(200, " + ", false)
      out[#out + 1] = table.concat(parts)
    else
      out[#out + 1] = tab(i, " " .. label .. " ", active)
    end
  end
  return table.concat(out, "%#IdePanelTabSep#│%#IdePanelNormal#") .. "%#IdePanelNormal#"
end

---------------------------------------------------------------------- window

local function win_opts(win)
  local wo = vim.wo[win]
  wo.number = false
  wo.relativenumber = false
  wo.signcolumn = "no"
  wo.foldcolumn = "0"
  wo.statuscolumn = ""
  wo.cursorline = false
  wo.wrap = false
  wo.spell = false
  wo.list = false
  wo.winfixheight = true
  wo.winhighlight = "Normal:IdePanelNormal,EndOfBuffer:IdePanelNormal,WinBar:IdePanelNormal,WinBarNC:IdePanelNormal"
  wo.winbar = "%{%v:lua.require'ide.panel'.winbar()%}"
  vim.w[win].ide_role = "panel"
end

local function ensure_win()
  if M.is_open() then
    return state.win
  end
  local prev = api.nvim_get_current_win()
  vim.cmd("botright " .. state.height .. "split")
  state.win = api.nvim_get_current_win()
  -- the split inherits the current buffer; replaced right after by show()
  vim.w[state.win].ide_role = "panel"
  api.nvim_create_autocmd("WinClosed", {
    group = group,
    pattern = tostring(state.win),
    once = true,
    callback = function(ev)
      local w = tonumber(ev.match)
      if valid_win(w) then
        state.height = api.nvim_win_get_height(w)
      end
      state.win = nil
    end,
  })
  api.nvim_set_current_win(prev)
  return state.win
end

api.nvim_create_autocmd("WinResized", {
  group = group,
  callback = function()
    if M.is_open() then
      state.height = api.nvim_win_get_height(state.win)
    end
  end,
})

local function put_buf(buf)
  local win = state.win
  vim.wo[win].winfixbuf = false
  api.nvim_win_set_buf(win, buf)
  win_opts(win)
  vim.wo[win].winfixbuf = true
end

---------------------------------------------------------------------- terminals

local function term_index(buf)
  for i, t in ipairs(state.terms) do
    if t.buf == buf then
      return i
    end
  end
end

local function term_keymaps(buf)
  local function map(lhs, fn, desc)
    vim.keymap.set({ "t", "n" }, lhs, fn, { buffer = buf, desc = desc })
  end
  map("<A-]>", M.term_next, "Next terminal")
  map("<A-[>", M.term_prev, "Previous terminal")
  map("<A-n>", M.term_new, "New terminal")
  map("<A-x>", M.term_kill, "Kill terminal")
end

-- Creates a terminal buffer + job inside the panel window.
function M.term_new(opts)
  opts = opts or {}
  local win = ensure_win()
  local buf = api.nvim_create_buf(false, true)
  setup_buf(buf)
  put_buf(buf)
  local job
  api.nvim_win_call(win, function()
    job = vim.fn.jobstart(vim.o.shell, { term = true, cwd = opts.cwd })
  end)
  vim.bo[buf].buflisted = false
  vim.bo[buf].bufhidden = "hide"
  term_keymaps(buf)
  table.insert(state.terms, { buf = buf, job = job })
  state.cur = #state.terms
  state.section = "terminal"
  layout_fix()
  redraw_bar()
  if opts.focus ~= false then
    api.nvim_set_current_win(win)
    vim.cmd.startinsert()
  end
  return state.terms[state.cur]
end

-- Send a command line to the current terminal (creating one if needed).
function M.term_send(cmd)
  local t = state.terms[state.cur]
  if not t then
    t = M.term_new({ focus = false })
  else
    M.open("terminal", { focus = false })
  end
  vim.fn.chansend(t.job, cmd .. "\n")
end

local function term_show(i)
  local t = state.terms[i]
  if not t then
    return
  end
  state.cur = i
  put_buf(t.buf)
  redraw_bar()
end

function M.term_next()
  if #state.terms == 0 then
    return
  end
  state.section = "terminal"
  term_show(state.cur % #state.terms + 1)
  if api.nvim_get_current_win() == state.win then
    vim.cmd.startinsert()
  end
end

function M.term_prev()
  if #state.terms == 0 then
    return
  end
  state.section = "terminal"
  term_show((state.cur - 2) % #state.terms + 1)
  if api.nvim_get_current_win() == state.win then
    vim.cmd.startinsert()
  end
end

function M.term_kill()
  local t = state.terms[state.cur]
  if t then
    pcall(vim.fn.jobstop, t.job)
  end
end

-- A terminal process ended: drop its tab and buffer.
api.nvim_create_autocmd("TermClose", {
  group = group,
  callback = function(ev)
    local i = term_index(ev.buf)
    if not i then
      return
    end
    table.remove(state.terms, i)
    local buf = ev.buf
    vim.schedule(function()
      if #state.terms == 0 then
        state.cur = 0
        if state.section == "terminal" then
          M.close()
        end
      else
        if state.cur > #state.terms or state.cur >= i then
          state.cur = math.max(1, math.min(state.cur - (state.cur >= i and 1 or 0), #state.terms))
        end
        if M.is_open() and state.section == "terminal" and api.nvim_win_get_buf(state.win) == buf then
          term_show(state.cur)
        end
      end
      if api.nvim_buf_is_valid(buf) then
        if M.is_open() and api.nvim_win_get_buf(state.win) == buf then
          -- never wipe the buffer shown in the panel window
          local keep = get_buf("output")
          put_buf(keep)
        end
        pcall(api.nvim_buf_delete, buf, { force = true })
      end
      redraw_bar()
    end)
  end,
})

-- Entering the panel window on a terminal buffer starts insert mode.
api.nvim_create_autocmd("WinEnter", {
  group = group,
  callback = function()
    if M.is_open() and api.nvim_get_current_win() == state.win and vim.bo.buftype == "terminal" then
      vim.schedule(function()
        if api.nvim_get_current_win() == state.win and vim.bo.buftype == "terminal" then
          vim.cmd.startinsert()
        end
      end)
    end
  end,
})

---------------------------------------------------------------------- problems

local function icons()
  local d = require("ide.icons").diagnostics
  return {
    [vim.diagnostic.severity.ERROR] = { d.Error, "DiagnosticError" },
    [vim.diagnostic.severity.WARN] = { d.Warn, "DiagnosticWarn" },
    [vim.diagnostic.severity.INFO] = { d.Info, "DiagnosticInfo" },
    [vim.diagnostic.severity.HINT] = { d.Hint, "DiagnosticHint" },
  }
end

local QF_SEV = { E = 1, W = 2, I = 3, N = 3 }

local function collect_items()
  local items = {}
  for _, d in ipairs(vim.diagnostic.get()) do
    if api.nvim_buf_is_valid(d.bufnr) then
      items[#items + 1] = {
        file = api.nvim_buf_get_name(d.bufnr),
        lnum = d.lnum + 1,
        col = d.col + 1,
        sev = d.severity or 3,
        msg = (d.message or ""):gsub("\n.*", ""),
        source = d.source,
      }
    end
  end
  for _, q in ipairs(vim.fn.getqflist()) do
    if q.valid == 1 then
      local file = q.bufnr > 0 and api.nvim_buf_get_name(q.bufnr) or ""
      items[#items + 1] = {
        file = file,
        lnum = q.lnum,
        col = q.col,
        sev = QF_SEV[q.type] or 3,
        msg = (q.text or ""):gsub("^%s+", ""):gsub("\n.*", ""),
        source = "quickfix",
      }
    end
  end
  return items
end

function M.problems_refresh()
  local items = collect_items()
  state.problem_count = #items
  local buf = get_buf("problems")
  local by_file, files = {}, {}
  for _, it in ipairs(items) do
    if not by_file[it.file] then
      by_file[it.file] = {}
      files[#files + 1] = it.file
    end
    table.insert(by_file[it.file], it)
  end
  table.sort(files)
  local ic = icons()
  local lines, marks, map = {}, {}, {}
  if #items == 0 then
    lines[1] = "  No problems detected in the workspace."
    marks[1] = { 1, 0, "Comment", -1 }
  end
  for _, f in ipairs(files) do
    local rel = f == "" and "[No Name]" or vim.fn.fnamemodify(f, ":~:.")
    lines[#lines + 1] = " " .. rel .. " (" .. #by_file[f] .. ")"
    marks[#marks + 1] = { #lines, 0, "Directory", -1 }
    table.sort(by_file[f], function(a, b)
      return a.lnum == b.lnum and a.col < b.col or a.lnum < b.lnum
    end)
    for _, it in ipairs(by_file[f]) do
      local icon = ic[it.sev] or ic[3]
      local head = ("  %s  %s:%d:%d  "):format(icon[1], vim.fs.basename(f), it.lnum, it.col)
      local line = head .. it.msg
      local src = it.source and (" [" .. it.source .. "]") or ""
      lines[#lines + 1] = line .. src
      map[#lines] = { file = f, lnum = it.lnum, col = it.col }
      marks[#marks + 1] = { #lines, 2, icon[2], 2 + #icon[1] }
      marks[#marks + 1] = { #lines, #line, "Comment", #line + #src }
    end
  end
  state.problem_items = map
  set_lines(buf, lines)
  api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  for _, m in ipairs(marks) do
    local opts = { hl_group = m[3] }
    if m[4] == -1 then
      opts.end_row = m[1] - 1
      opts.end_col = #lines[m[1]]
    else
      opts.end_col = m[4]
    end
    pcall(api.nvim_buf_set_extmark, buf, ns, m[1] - 1, m[2], opts)
  end
  if not vim.b[buf].ide_problems_maps then
    vim.b[buf].ide_problems_maps = true
    vim.keymap.set("n", "<CR>", function()
      local it = state.problem_items[api.nvim_win_get_cursor(0)[1]]
      if not it then
        return
      end
      local w = editor_win()
      if not w then
        vim.cmd("aboveleft split")
        w = api.nvim_get_current_win()
        vim.w[w].ide_role = nil
      end
      api.nvim_set_current_win(w)
      if it.file ~= "" and vim.fn.expand("%:p") ~= it.file then
        vim.cmd.edit(vim.fn.fnameescape(it.file))
      end
      pcall(api.nvim_win_set_cursor, 0, { it.lnum, math.max(0, it.col - 1) })
      vim.cmd("normal! zz")
    end, { buffer = buf, desc = "Jump to problem" })
  end
  redraw_bar()
end

local timer = vim.uv.new_timer()
local function schedule_problems()
  timer:stop()
  timer:start(100, 0, vim.schedule_wrap(M.problems_refresh))
end
api.nvim_create_autocmd({ "DiagnosticChanged", "QuickFixCmdPost" }, { group = group, callback = schedule_problems })

---------------------------------------------------------------------- output

function M.output_clear()
  set_lines(get_buf("output"), {})
end

-- lines: string or list of strings. opts.hl: highlight group for these lines.
function M.output_append(lines, opts)
  opts = opts or {}
  if type(lines) == "string" then
    lines = vim.split(lines, "\n", { plain = true })
  end
  local clean = {}
  for _, l in ipairs(lines) do
    clean[#clean + 1] = (l:gsub("\r", ""))
  end
  if #clean == 0 then
    return
  end
  local buf = get_buf("output")
  local first = api.nvim_buf_line_count(buf)
  -- an empty buffer has one empty line: overwrite it
  local empty = first == 1 and api.nvim_buf_get_lines(buf, 0, 1, false)[1] == ""
  vim.bo[buf].modifiable = true
  if empty then
    api.nvim_buf_set_lines(buf, 0, 1, false, clean)
    first = 0
  else
    api.nvim_buf_set_lines(buf, first, first, false, clean)
  end
  vim.bo[buf].modifiable = false
  if opts.hl then
    for i = 0, #clean - 1 do
      pcall(api.nvim_buf_set_extmark, buf, ns, first + i, 0, { line_hl_group = opts.hl })
    end
  end
  -- auto-scroll every window showing the buffer
  local last = api.nvim_buf_line_count(buf)
  for _, w in ipairs(api.nvim_list_wins()) do
    if api.nvim_win_get_buf(w) == buf then
      pcall(api.nvim_win_set_cursor, w, { last, 0 })
    end
  end
end

---------------------------------------------------------------------- debug

local function debug_buf()
  local ok, dapui = pcall(require, "dapui")
  if ok and dapui.elements and dapui.elements.repl then
    local ok2, b = pcall(dapui.elements.repl.buffer)
    if ok2 and type(b) == "number" and api.nvim_buf_is_valid(b) then
      vim.bo[b].buflisted = false
      return b
    end
  end
  local b = get_buf("debug")
  set_lines(b, { "  Debug console unavailable (nvim-dap-ui not loaded or not set up)." })
  return b
end

---------------------------------------------------------------------- public

local function show(section)
  state.section = section
  if section == "terminal" then
    if #state.terms == 0 then
      M.term_new({ focus = false })
    else
      term_show(math.max(1, state.cur))
    end
    return
  end
  local buf
  if section == "problems" then
    M.problems_refresh()
    buf = get_buf("problems")
  elseif section == "output" then
    buf = get_buf("output")
  else
    buf = debug_buf()
  end
  put_buf(buf)
  redraw_bar()
end

-- opts.focus (default true): enter the panel window.
function M.open(section, opts)
  opts = opts or {}
  section = section or state.section or "terminal"
  ensure_win()
  show(section)
  layout_fix()
  if opts.focus ~= false and M.is_open() then
    api.nvim_set_current_win(state.win)
    if vim.bo.buftype == "terminal" then
      vim.cmd.startinsert()
    end
  end
end

function M.close()
  if not M.is_open() then
    return
  end
  state.height = api.nvim_win_get_height(state.win)
  local w = state.win
  state.win = nil
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
