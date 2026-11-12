-- Build tasks (CMake / Make / uv): run jobs into the panel OUTPUT tab and fill quickfix.
local M = {}

local MARKERS = { "CMakeLists.txt", "Makefile", "pyproject.toml", ".git" }

-- gcc/clang, python tracebacks, cmake diagnostics. Only valid entries are kept.
local EFM = table.concat({
  "%f:%l:%c: %trror: %m",
  "%f:%l:%c: %tarning: %m",
  "%f:%l:%c: fatal %trror: %m",
  "%f:%l:%c: %tote: %m",
  "%f:%l: %trror: %m",
  "%f:%l: %tarning: %m",
  "%f:%l:%c: %m",
  '%A  File "%f"\\, line %l%.%#',
  "%ECMake Error at %f:%l%.%#",
  "%WCMake Warning at %f:%l%.%#",
}, ",")

local state = { job = nil, run_choice = {} }

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "Build" })
end

local function panel()
  local ok, p = pcall(require, "ide.panel")
  return ok and p or nil
end

local function root()
  local buf = vim.api.nvim_get_current_buf()
  local src = vim.bo[buf].buftype == "" and vim.api.nvim_buf_get_name(buf) ~= "" and vim.api.nvim_buf_get_name(buf) or vim.uv.cwd()
  return vim.fs.root(src, MARKERS) or vim.uv.cwd()
end

local function exists(path)
  return vim.uv.fs_stat(path) ~= nil
end

function M.detect(dir)
  dir = dir or root()
  if exists(dir .. "/CMakeLists.txt") then
    return "cmake"
  elseif exists(dir .. "/Makefile") or exists(dir .. "/makefile") then
    return "make"
  elseif exists(dir .. "/pyproject.toml") then
    return "uv"
  end
end

-- Last non-panel file buffer path (for `uv run <file>`).
local function current_file()
  local f = vim.api.nvim_buf_get_name(0)
  if f ~= "" and vim.bo.buftype == "" then
    return f
  end
  local p = vim.fn.expand("#:p")
  return p ~= "" and p or nil
end

-- Resolve relative qf filenames against the job cwd, keep valid entries only.
local function fill_quickfix(lines, cwd, title)
  local parsed = vim.fn.getqflist({ lines = lines, efm = EFM }).items or {}
  local items = {}
  for _, it in ipairs(parsed) do
    if it.valid == 1 then
      local name = it.bufnr > 0 and vim.fn.bufname(it.bufnr) or ""
      local abs = name
      if name ~= "" and name:sub(1, 1) ~= "/" then
        for _, base in ipairs({ cwd, vim.uv.cwd() }) do
          if exists(base .. "/" .. name) then
            abs = vim.fs.normalize(base .. "/" .. name)
            break
          end
        end
      end
      items[#items + 1] = { filename = abs, lnum = it.lnum, col = it.col, type = it.type, text = it.text }
    end
  end
  vim.fn.setqflist({}, " ", { title = title, items = items })
  local p = panel()
  if p then
    pcall(p.problems_refresh)
  end
  return #items
end

-- Run `cmd` (argv list) streaming into OUTPUT. opts: cwd, title, on_success(), qf (default true).
local function job(cmd, opts)
  if state.job then
    notify("A task is already running", vim.log.levels.WARN)
    return
  end
  local p = panel()
  local cwd = opts.cwd or root()
  local title = opts.title or table.concat(cmd, " ")
  local collected = {}
  local partial = { stdout = "", stderr = "" }

  if p then
    p.output_clear()
    p.output_append({ "> " .. table.concat(cmd, " "), "  cwd: " .. cwd, "" }, { hl = "Comment" })
    p.open("output", { focus = false })
  end

  local function feed(stream)
    return function(_, data)
      if not data then
        return
      end
      vim.schedule(function()
        local text = partial[stream] .. data
        local lines = vim.split(text, "\n", { plain = true })
        partial[stream] = table.remove(lines)
        for _, l in ipairs(lines) do
          collected[#collected + 1] = l
        end
        if p and #lines > 0 then
          p.output_append(lines, stream == "stderr" and { hl = "DiagnosticWarn" } or nil)
        end
      end)
    end
  end

  local ok, obj = pcall(vim.system, cmd, {
    cwd = cwd,
    text = true,
    env = { LC_ALL = "C" },
    stdout = feed("stdout"),
    stderr = feed("stderr"),
  }, function(res)
    vim.schedule(function()
      state.job = nil
      for _, s in ipairs({ "stdout", "stderr" }) do
        if partial[s] ~= "" then
          collected[#collected + 1] = partial[s]
          if p then
            p.output_append({ partial[s] })
          end
        end
      end
      local n = 0
      if opts.qf ~= false then
        n = fill_quickfix(collected, cwd, title)
      end
      local msg = ("%s %s (exit %d)"):format(title, res.code == 0 and "succeeded" or "failed", res.code)
      if p then
        p.output_append({ "", msg }, { hl = res.code == 0 and "DiagnosticOk" or "DiagnosticError" })
      end
      if res.code == 0 then
        notify(msg .. (n > 0 and (", " .. n .. " warnings") or ""))
        if opts.on_success then
          opts.on_success()
        end
      else
        notify(msg, vim.log.levels.ERROR)
      end
    end)
  end)
  if not ok then
    notify("Failed to start: " .. tostring(obj), vim.log.levels.ERROR)
    return
  end
  state.job = obj
  return obj
end

---------------------------------------------------------------------- cmake

local function cmake_preset_names(dir)
  local f = dir .. "/CMakePresets.json"
  if not exists(f) then
    return {}
  end
  local ok, data = pcall(vim.json.decode, table.concat(vim.fn.readfile(f), "\n"))
  local names = {}
  if ok and data and data.configurePresets then
    for _, p in ipairs(data.configurePresets) do
      names[p.name] = true
    end
  end
  return names
end

local function save_all()
  vim.cmd("silent! wall")
end

-- clangd reads compile_commands.json only at startup: restart it so stale include errors clear.
local function restart_clangd()
  if #vim.lsp.get_clients({ name = "clangd" }) > 0 then
    pcall(vim.cmd, "lsp restart clangd")
  end
end

local function link_compile_commands(dir)
  local src, dst = dir .. "/build/compile_commands.json", dir .. "/compile_commands.json"
  if exists(src) and not vim.uv.fs_lstat(dst) then
    vim.uv.fs_symlink(src, dst)
  end
end

function M.cmake_configure(arg, then_cb)
  save_all()
  local dir = root()
  if vim.fn.executable("cmake") ~= 1 then
    return notify("cmake not found", vim.log.levels.ERROR)
  end
  local cmd
  if arg and arg ~= "" and cmake_preset_names(dir)[arg] then
    cmd = { "cmake", "--preset", arg }
  else
    cmd = {
      "cmake", "-S", dir, "-B", dir .. "/build",
      "-DCMAKE_BUILD_TYPE=" .. ((arg and arg ~= "") and arg or "Debug"),
      "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON",
    }
  end
  job(cmd, {
    cwd = dir,
    title = "CMake configure",
    on_success = function()
      link_compile_commands(dir)
      restart_clangd()
      if then_cb then
        then_cb()
      end
    end,
  })
end

function M.cmake_build()
  save_all()
  local dir = root()
  job({ "cmake", "--build", "build", "-j" }, { cwd = dir, title = "CMake build" })
end

local function find_executables(dir)
  local found = {}
  for name, t in vim.fs.dir(dir .. "/build", {
    depth = 4,
    skip = function(n)
      return n ~= "CMakeFiles" and n ~= "_deps" and true or false
    end,
  }) do
    local path = dir .. "/build/" .. name
    if t == "file" and vim.fn.executable(path) == 1 and not name:match("%.so[%.%d]*$") and not name:match("%.a$")
      and not name:match("%.cmake$") and not name:match("%.sh$") then
      found[#found + 1] = path
    end
  end
  table.sort(found)
  return found
end

local function pick(items, prompt, cb)
  local select = (_G.Snacks and Snacks.picker and Snacks.picker.select) or vim.ui.select
  select(items, { prompt = prompt }, function(choice)
    if choice then
      cb(choice)
    end
  end)
end

local function cmake_run()
  local dir = root()
  local exes = find_executables(dir)
  if #exes == 0 then
    return notify("No executables in build/ (run :Build first)", vim.log.levels.WARN)
  end
  local function go(exe)
    state.run_choice[dir] = exe
    panel().term_send(vim.fn.shellescape(exe))
  end
  local saved = state.run_choice[dir]
  if saved and vim.tbl_contains(exes, saved) then
    return go(saved)
  elseif #exes == 1 then
    return go(exes[1])
  end
  pick(exes, "Run executable", go)
end

---------------------------------------------------------------------- tasks

function M.build()
  save_all()
  local dir = root()
  local kind = M.detect(dir)
  if kind == "cmake" then
    if exists(dir .. "/build/CMakeCache.txt") then
      M.cmake_build()
    else
      M.cmake_configure(nil, M.cmake_build)
    end
  elseif kind == "make" then
    job({ "make", "-j" }, { cwd = dir, title = "make" })
  elseif kind == "uv" and vim.fn.executable("uv") == 1 then
    job({ "uv", "sync" }, { cwd = dir, title = "uv sync" })
  elseif vim.bo.filetype == "python" and current_file() then
    if kind == "uv" then
      notify("uv not installed: syntax-checking the current file instead", vim.log.levels.WARN)
    end
    job({ "python3", "-m", "py_compile", current_file() }, { cwd = dir, title = "py_compile" })
  elseif kind == "uv" then
    notify("uv not installed: nothing to sync", vim.log.levels.WARN)
  else
    notify("No build system detected (CMakeLists.txt, Makefile, pyproject.toml)", vim.log.levels.WARN)
  end
end

local function python_run(dir)
  local f = current_file()
  if not f then
    return notify("No file to run", vim.log.levels.WARN)
  end
  local cmd = vim.fn.executable("uv") == 1 and ("uv run " .. vim.fn.shellescape(f)) or ("python3 " .. vim.fn.shellescape(f))
  panel().term_send("cd " .. vim.fn.shellescape(dir) .. " && " .. cmd)
end

-- Executable regular files directly in `dir` (scripts allowed).
local function make_executables(dir)
  local found = {}
  for name, t in vim.fs.dir(dir) do
    if t == "file" and vim.fn.executable(dir .. "/" .. name) == 1 then
      found[#found + 1] = name
    end
  end
  table.sort(found)
  return found
end

local function make_run(dir, p)
  local function send(cmd)
    p.term_send("cd " .. vim.fn.shellescape(dir) .. " && " .. cmd)
  end
  local exes = make_executables(dir)
  if #exes == 1 then
    return send("./" .. vim.fn.shellescape(exes[1]))
  elseif #exes > 1 then
    return pick(exes, "Run executable", function(exe)
      send("./" .. vim.fn.shellescape(exe))
    end)
  end
  vim.ui.input({ prompt = "make target: " }, function(target)
    if target ~= nil then
      send("make " .. target)
    end
  end)
end

function M.run()
  save_all()
  local dir = root()
  local kind = M.detect(dir)
  local p = panel()
  if not p then
    return notify("ide.panel unavailable", vim.log.levels.ERROR)
  end
  if kind == "cmake" then
    cmake_run()
  elseif kind == "make" then
    make_run(dir, p)
  elseif kind == "uv" or vim.bo.filetype == "python" then
    python_run(dir)
  else
    notify("Nothing to run", vim.log.levels.WARN)
  end
end

function M.test()
  save_all()
  local dir = root()
  local kind = M.detect(dir)
  if kind == "cmake" then
    job({ "ctest", "--test-dir", "build", "--output-on-failure" }, { cwd = dir, title = "ctest" })
  elseif kind == "make" then
    job({ "make", "test" }, { cwd = dir, title = "make test" })
  elseif kind == "uv" then
    local cmd = vim.fn.executable("uv") == 1 and { "uv", "run", "pytest" } or { "python3", "-m", "pytest" }
    job(cmd, { cwd = dir, title = "pytest" })
  else
    notify("No tests detected", vim.log.levels.WARN)
  end
end

function M.clean()
  local dir = root()
  local kind = M.detect(dir)
  if kind == "cmake" then
    job({ "cmake", "--build", "build", "--target", "clean" }, { cwd = dir, title = "CMake clean", qf = false })
  elseif kind == "make" then
    job({ "make", "clean" }, { cwd = dir, title = "make clean", qf = false })
  else
    notify("Nothing to clean for " .. tostring(kind), vim.log.levels.WARN)
  end
end

local function preset_complete()
  local names = vim.tbl_keys(cmake_preset_names(root()))
  vim.list_extend(names, { "Debug", "Release", "RelWithDebInfo", "MinSizeRel" })
  return names
end

vim.api.nvim_create_user_command("Build", M.build, { desc = "Build the project" })
vim.api.nvim_create_user_command("Run", M.run, { desc = "Run the project" })
vim.api.nvim_create_user_command("Test", M.test, { desc = "Run the tests" })
vim.api.nvim_create_user_command("CMakeConfigure", function(o)
  M.cmake_configure(o.args)
end, { nargs = "?", complete = preset_complete, desc = "CMake configure [preset|build_type]" })
vim.api.nvim_create_user_command("CMakeBuild", M.cmake_build, { desc = "CMake build" })
vim.api.nvim_create_user_command("BuildClean", M.clean, { desc = "Clean build artifacts" })

return M
