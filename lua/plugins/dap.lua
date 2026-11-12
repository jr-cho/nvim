-- Debugging: nvim-dap + dap-ui (right sidebar only; REPL lives in ide.panel DEBUG CONSOLE).
-- Adapters: gdb (native DAP) for C/C++/Rust, debugpy for Python,.
local function dap() return require("dap") end
-- Last program launched (default for the next "Executable:" prompt).
local last_program

local function pick_program()
  local dap = require("dap")
  local default = last_program
  if not default then
    default = vim.fn.getcwd() .. (vim.fn.isdirectory("build") == 1 and "/build/" or "/")
  end
  local answer = vim.fn.input("Executable: ", default, "file")
  local stat = answer ~= "" and vim.uv.fs_stat(answer) or nil
  if not stat or stat.type ~= "file" or vim.fn.executable(answer) ~= 1 then
    vim.notify("Not an executable file: " .. answer, vim.log.levels.ERROR, { title = "Debug" })
    return dap.ABORT
  end
  last_program = answer
  return answer
end

-- Attach needs ptrace; with yama ptrace_scope != 0 gdb hangs silently.
local function pick_pid()
  local dap = require("dap")
  local f = io.open("/proc/sys/kernel/yama/ptrace_scope", "r")
  local scope = f and f:read("*l") or nil
  if f then f:close() end
  if scope and vim.trim(scope) ~= "0" then
    vim.notify(
      "Cannot attach: kernel.yama.ptrace_scope = " .. vim.trim(scope) .. " blocks ptrace of unrelated processes.\n"
        .. "Fix: echo 0 | sudo tee /proc/sys/kernel/yama/ptrace_scope",
      vim.log.levels.ERROR,
      { title = "Debug" }
    )
    return dap.ABORT
  end
  return require("dap.utils").pick_process() or dap.ABORT
end

local function pcall_call(mod, fn, ...)
  local ok, m = pcall(require, mod)
  if ok and m[fn] then return m[fn](...) end
end

return {
  {
    "mfussenegger/nvim-dap",
    lazy = true,
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "nvim-neotest/nvim-nio",
      "theHamsta/nvim-dap-virtual-text",
      "jay-babu/mason-nvim-dap.nvim",
      "mfussenegger/nvim-dap-python",
    },
    keys = {
      -- no F-keys: everything lives under <leader>D (which-key group "debug").
      -- <leader>DD = sticky debug mode: which-key stays open, so c/n/i/o/b... are single presses; <Esc> leaves.
      {
        "<leader>DD",
        function() require("which-key").show({ keys = "<leader>D", loop = true }) end,
        desc = "Debug mode (sticky)",
      },
      { "<leader>Dn", function() dap().step_over() end, desc = "Step over (next)" },
      { "<leader>Di", function() dap().step_into() end, desc = "Step into" },
      { "<leader>Do", function() dap().step_out() end, desc = "Step out" },
      { "<leader>Db", function() dap().toggle_breakpoint() end, desc = "Breakpoint" },
      {
        "<leader>DB",
        function() dap().set_breakpoint(vim.fn.input("Breakpoint condition: ")) end,
        desc = "Conditional breakpoint",
      },
      { "<leader>Dc", function() dap().continue() end, desc = "Continue" },
      { "<leader>Du", function() require("dapui").toggle() ; pcall_call("ide.layout", "fix") end, desc = "Toggle debug UI" },
      {
        "<leader>Dr",
        function() pcall_call("ide.panel", "open", "debug") end,
        desc = "Debug console",
      },
      { "<leader>Dl", function() dap().run_last() end, desc = "Run last" },
      {
        "<leader>Dt",
        function()
          dap().terminate()
          -- a session that never started fires no terminated event: clean up ourselves
          if not dap().session() then
            pcall(function() require("dapui").close() end)
            pcall_call("ide.layout", "fix")
          end
        end,
        desc = "Terminate",
      },
    },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")

      -- signs
      vim.fn.sign_define("DapBreakpoint", { text = require("ide.icons").dap.Breakpoint, texthl = "DapBreakpoint", linehl = "", numhl = "" })
      vim.fn.sign_define("DapBreakpointCondition", { text = require("ide.icons").dap.BreakpointCondition, texthl = "DapBreakpoint", linehl = "", numhl = "" })
      vim.fn.sign_define("DapLogPoint", { text = require("ide.icons").dap.LogPoint, texthl = "DapLogPoint", linehl = "", numhl = "" })
      vim.fn.sign_define("DapStopped", { text = require("ide.icons").dap.Stopped, texthl = "DapStopped", linehl = "DapStoppedLine", numhl = "" })
      vim.fn.sign_define("DapBreakpointRejected", { text = require("ide.icons").dap.BreakpointRejected, texthl = "DapBreakpointRejected", linehl = "", numhl = "" })

      -- single right-hand layout; repl/console are shown by ide.panel
      dapui.setup({
        layouts = {
          {
            position = "right",
            size = 40,
            elements = {
              { id = "scopes", size = 0.4 },
              { id = "breakpoints", size = 0.2 },
              { id = "stacks", size = 0.2 },
              { id = "watches", size = 0.2 },
            },
          },
        },
      })
      require("nvim-dap-virtual-text").setup({ virt_text_pos = "eol" })

      dap.listeners.after.event_initialized["ide_dapui"] = function()
        dapui.open()
        pcall_call("ide.panel", "open", "debug", { focus = false })
        pcall_call("ide.layout", "fix")
      end
      for _, ev in ipairs({ "event_terminated", "event_exited" }) do
        dap.listeners.before[ev]["ide_dapui"] = function()
          dapui.close()
          pcall_call("ide.layout", "fix")
        end
      end

      -- gdb native DAP (gdb >= 14)
      dap.adapters.gdb = {
        type = "executable",
        command = "gdb",
        args = { "--interpreter=dap", "--eval-command", "set print pretty on" },
      }
      dap.configurations.c = {
        {
          name = "Launch",
          type = "gdb",
          request = "launch",
          program = pick_program,
          cwd = "${workspaceFolder}",
          stopAtBeginningOfMainSubprogram = false,
        },
        {
          name = "Attach to process",
          type = "gdb",
          request = "attach",
          pid = pick_pid,
          cwd = "${workspaceFolder}",
        },
      }
      dap.configurations.cpp = dap.configurations.c
      dap.configurations.rust = dap.configurations.c

      -- python (debugpy from mason)
      local py = vim.fn.stdpath("data") .. "/mason/packages/debugpy/venv/bin/python"
      if vim.fn.executable(py) == 1 then
        require("dap-python").setup(py)
      else
        -- debugpy not installed yet: fall back to system python (works once debugpy is installed)
        require("dap-python").setup("python3")
      end

      -- .vscode/launch.json: nvim-dap >= 0.9 loads it automatically via providers.configs
    end,
  },
}
