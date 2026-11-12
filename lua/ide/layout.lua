-- IDE workspace: persistent Explorer, window-order enforcer, startup and quit handling.
-- Target tree: row[ explorer, col[ row[editors..., docpanel], panel ] ]
-- Windows are identified by vim.w[win].ide_role: explorer | panel | docpanel (editors have none).
local M = {}

local EXPLORER_WIDTH = 30
local busy = false
local opening = false -- an explorer picker was requested but is not shown yet
local wanted = false -- explorer should be visible (false after an explicit close/toggle off)
local group = vim.api.nvim_create_augroup("ide_layout", { clear = true })

local function valid(win) return win and vim.api.nvim_win_is_valid(win) end
local function is_float(win) return vim.api.nvim_win_get_config(win).relative ~= "" end

---@return snacks.Picker?
local function explorer_picker()
  local ok, list = pcall(function() return Snacks.picker.get({ source = "explorer" }) end)
  return ok and list[1] or nil
end

--- The real split window of the Snacks explorer (layout box); tags it with role "explorer".
---@return integer?
function M.explorer_win()
  for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if not is_float(w) and vim.bo[vim.api.nvim_win_get_buf(w)].filetype == "snacks_layout_box" then
      vim.w[w].ide_role = "explorer"
      return w
    end
  end
end

---@param win integer
function M.is_ide_win(win)
  if not valid(win) then return false end
  return vim.w[win].ide_role ~= nil or vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "snacks_layout_box"
end

--- Normal (non-floating, non-IDE) windows of the current tab.
---@return integer[]
function M.editor_wins()
  local ret = {}
  for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if not is_float(w) and not M.is_ide_win(w) then ret[#ret + 1] = w end
  end
  return ret
end

local function role_wins(role)
  local ret = {}
  for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.w[w].ide_role == role then ret[#ret + 1] = w end
  end
  return ret
end

-- Top-level children of the window tree as a list of layout nodes.
local function top_children()
  local l = vim.fn.winlayout()
  if l[1] == "row" then return l[2] end
  return { l }
end
local function is_leaf(node, win) return node[1] == "leaf" and node[2] == win end

local function explorer_in_place(win)
  local c = top_children()
  return c[1] ~= nil and is_leaf(c[1], win)
end

-- Panel is in place when it is the last leaf of a col that is the top node or the last top-level child.
local function panel_in_place(win)
  local l = vim.fn.winlayout()
  local area = l
  if l[1] == "row" then area = l[2][#l[2]] end
  if area[1] ~= "col" then return false end
  return is_leaf(area[2][#area[2]], win)
end

-- Docpanel is in place when it is the last leaf of the editor area: either the last top-level
-- child (no panel) or the last leaf of the row above the panel.
local function docpanel_in_place(win)
  local c = top_children()
  local last = c[#c]
  if not last then return false end
  if is_leaf(last, win) then return #role_wins("panel") == 0 end
  if last[1] ~= "col" then return false end
  local above = last[2][1]
  return above and above[1] == "row" and is_leaf(above[2][#above[2]], win) or false
end

local function move_far_left(win, width)
  vim.api.nvim_win_call(win, function() vim.cmd("wincmd H") end)
  if valid(win) then vim.api.nvim_win_set_width(win, width) end
end

--- Idempotent, re-entrancy-guarded enforcer of the IDE window order.
function M.fix()
  if busy then return end
  busy = true
  local ok, err = pcall(function()
    local cur = vim.api.nvim_get_current_win()
    -- (0) docpanel to the far right; step (1) then puts the panel under editors + docpanel
    for _, w in ipairs(role_wins("docpanel")) do
      if not docpanel_in_place(w) then
        vim.api.nvim_win_call(w, function() vim.cmd("wincmd L") end)
      end
      -- the move may have resized it; always re-assert the configured width
      local want = vim.w[w].ide_width
      if want and valid(w) and vim.api.nvim_win_get_width(w) ~= want then vim.api.nvim_win_set_width(w, want) end
    end
    -- (1) panels to the bottom
    for _, w in ipairs(role_wins("panel")) do
      if not panel_in_place(w) then
        local h = vim.api.nvim_win_get_height(w)
        vim.api.nvim_win_call(w, function() vim.cmd("wincmd J") end)
        if valid(w) then vim.api.nvim_win_set_height(w, h) end
      end
    end
    -- (2) explorer at the far left
    local ex = M.explorer_win()
    if ex then
      if not explorer_in_place(ex) then move_far_left(ex, EXPLORER_WIDTH) end
      if vim.api.nvim_win_get_width(ex) ~= EXPLORER_WIDTH then vim.api.nvim_win_set_width(ex, EXPLORER_WIDTH) end
      vim.wo[ex].winfixwidth = true
    end
    -- (3) always keep one editor window
    if #M.editor_wins() == 0 then
      local panel = role_wins("panel")[1]
      local anchor = panel and { split = "above", win = panel }
        or (ex and { split = "right", win = ex })
        or { split = "left", win = -1 }
      local ph = panel and vim.api.nvim_win_get_height(panel)
      local b = vim.api.nvim_create_buf(true, false)
      local w = vim.api.nvim_open_win(b, false, anchor)
      if panel then vim.api.nvim_win_set_height(panel, vim.w[panel].ide_height or math.min(ph, 12)) end
      if ex and valid(ex) then vim.api.nvim_win_set_width(ex, EXPLORER_WIDTH) end
      cur = valid(cur) and cur or w
    end
    if valid(cur) then vim.api.nvim_set_current_win(cur) end
  end)
  busy = false
  if not ok then vim.notify("ide.layout.fix: " .. tostring(err), vim.log.levels.ERROR) end
end

-- Re-open the explorer if something else (e.g. :only, <C-w>o) closed it behind our back.
local pending = false
local function fix_later()
  if pending then return end
  pending = true
  vim.schedule(function()
    pending = false
    if wanted and not explorer_picker() and vim.v.exiting == vim.NIL then
      M.explorer_open({ focus = false })
    end
    M.fix()
  end)
end

-- Explorer ------------------------------------------------------------------

--- Open the explorer (no-op if visible). opts.focus = move focus into it; opts.cwd = root.
---@param opts? { focus?: boolean, cwd?: string }
function M.explorer_open(opts)
  opts = opts or {}
  local picker = explorer_picker()
  if picker then
    if opts.focus then picker:focus("list") end
    return picker
  end
  if opening then return end
  wanted, opening = true, true
  vim.defer_fn(function() opening = false end, 1000) -- safety net if on_show never fires
  local prev = vim.api.nvim_get_current_win()
  return Snacks.picker.explorer({
    cwd = opts.cwd,
    focus = opts.focus and "list" or false,
    on_show = function()
      vim.schedule(function()
        opening = false
        M.fix()
        if not opts.focus and valid(prev) and not M.is_ide_win(prev) then vim.api.nvim_set_current_win(prev) end
      end)
    end,
  })
end

function M.explorer_close()
  wanted = false
  local picker = explorer_picker()
  if picker then picker:close() end
  vim.schedule(M.fix)
end

--- VS Code semantics: closed -> open + focus; open but unfocused -> focus the list; focused -> close.
function M.explorer_toggle()
  local picker = M.explorer_win() and explorer_picker()
  if not picker then return M.explorer_open({ focus = true }) end
  local cur = vim.api.nvim_get_current_win()
  local focused = cur == picker.list.win.win or cur == picker.input.win.win
  if focused then
    M.explorer_close()
  else
    picker:focus("list")
  end
end

-- Quit handling ---------------------------------------------------------------

-- Close every IDE window and stop terminal jobs that would block quitting.
local function teardown()
  wanted = false
  local picker = explorer_picker()
  if picker then pcall(function() picker:close() end) end
  for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if not is_float(w) and M.is_ide_win(w) then pcall(vim.api.nvim_win_close, w, true) end
  end
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[b].buftype == "terminal" then
      local shown_in_editor = false
      for _, w in ipairs(vim.fn.win_findbuf(b)) do
        if vim.api.nvim_win_get_tabpage(w) == vim.api.nvim_get_current_tabpage() and not M.is_ide_win(w) then
          shown_in_editor = true
        end
      end
      local job = vim.b[b].terminal_job_id
      if not shown_in_editor and job then
        pcall(vim.fn.jobstop, job)
        pcall(vim.fn.jobwait, { job }, 300)
      end
    end
  end
end

local function on_quitpre()
  if #vim.api.nvim_list_tabpages() > 1 then return end
  local cur = vim.api.nvim_get_current_win()
  if M.is_ide_win(cur) or is_float(cur) then return end
  if #M.editor_wins() ~= 1 then return end
  local had_explorer = wanted and explorer_picker() ~= nil
  local ok_p, panel = pcall(require, "ide.panel")
  local ok_d, doc = pcall(require, "ide.docpanel")
  local had_panel = ok_p and panel.is_open()
  local had_doc = ok_d and doc.is_open()
  teardown()
  -- The quit may still be cancelled (unsaved-changes prompt). The prompt blocks, so a plain
  -- vim.schedule would run too early; restore on the first SafeState after QuitPre instead
  -- (never reached if Neovim exits).
  -- The prompt itself also reaches SafeState (mode "r"/"rm"); skip those until it is answered.
  vim.api.nvim_create_autocmd("SafeState", {
    group = group,
    callback = function()
      if vim.fn.mode():sub(1, 1) == "r" then return false end -- stay registered
      if vim.v.exiting ~= vim.NIL or not valid(cur) then return true end
      if had_explorer then M.explorer_open({ focus = false }) end
      if had_panel then panel.open() end
      if had_doc then doc.open() end
      vim.schedule(function()
        M.fix()
        if valid(cur) then
          vim.api.nvim_set_current_win(cur)
          vim.cmd.stopinsert()
        end
      end)
      return true -- one-shot: delete this autocmd
    end,
  })
end

-- Startup ---------------------------------------------------------------------

-- `nvim <dir>`: Snacks still opens its dashboard; replace it with a plain empty editor.
local function drop_dashboard()
  for _, w in ipairs(M.editor_wins()) do
    local b = vim.api.nvim_win_get_buf(w)
    if vim.bo[b].filetype == "snacks_dashboard" then
      vim.api.nvim_win_call(w, function() vim.cmd("enew") end)
      pcall(vim.api.nvim_buf_delete, b, { force = true })
    end
  end
end

local function startup()
  local dir_arg = vim.fn.argc() == 1 and vim.fn.isdirectory(vim.fn.argv(0)) == 1
  if not dir_arg then return end -- plain `nvim` / `nvim file`: no explorer until <leader>e
  vim.cmd.cd(vim.fn.fnameescape(vim.fn.argv(0)))
  drop_dashboard()
  local ed = M.editor_wins()[1] or vim.api.nvim_get_current_win()
  M.explorer_open({ focus = false })
  vim.defer_fn(function()
    drop_dashboard()
    M.fix()
    local e = M.editor_wins()[1] or ed
    if valid(e) then vim.api.nvim_set_current_win(e) end
  end, 250)
end

function M.setup()
  vim.api.nvim_clear_autocmds({ group = group })
  vim.api.nvim_create_autocmd("VimEnter", {
    group = group,
    once = true,
    callback = function() vim.schedule(startup) end,
  })
  if vim.v.vim_did_enter == 1 then vim.schedule(startup) end
  vim.api.nvim_create_autocmd("QuitPre", { group = group, callback = on_quitpre })
  vim.api.nvim_create_autocmd({ "WinClosed", "WinNew", "VimResized" }, { group = group, callback = fix_later })
  -- Re-root the explorer when the working directory changes.
  vim.api.nvim_create_autocmd("DirChanged", {
    group = group,
    callback = function(ev)
      local dir = vim.fn.fnamemodify(ev.file ~= "" and ev.file or vim.fn.getcwd(), ":p"):gsub("/$", "")
      vim.schedule(function()
        local picker = explorer_picker()
        if not picker or not wanted then return end
        local cur = (picker:cwd() or ""):gsub("/$", "")
        if cur == dir then return end
        local prev = vim.api.nvim_get_current_win()
        picker:close()
        M.explorer_open({ cwd = dir, focus = false })
        vim.defer_fn(function()
          if valid(prev) and not M.is_ide_win(prev) then vim.api.nvim_set_current_win(prev) end
        end, 150)
      end)
    end,
  })
end

return M
