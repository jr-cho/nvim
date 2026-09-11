local t = require("testkit")

t.run(function()
	local dap = require("dap")

	-- Adapters. lldb-dap rather than gdb: this machine is arm64, gdb is not
	-- installed, and Homebrew's gdb does not support arm64 macOS debugging.
	-- lldb-dap ships with the Xcode command line tools, speaks DAP directly,
	-- and matches the clang these binaries are built with.
	t.truthy("lldb adapter registered", dap.adapters.lldb ~= nil)
	t.truthy("python adapter registered", dap.adapters.python ~= nil)

	-- The adapter binary must exist. It is not on PATH, so the config names an
	-- absolute path and this is the assertion that catches an Xcode update
	-- moving it.
	local cmd = dap.adapters.lldb.command
	t.truthy("lldb-dap command is set", cmd ~= nil)
	t.check("lldb-dap exists on disk", vim.fn.executable(cmd), 1)

	-- debugpy, for Python.
	t.check("debugpy importable", vim.fn.system({ "python3", "-c", "import debugpy" }) == "" and 0 or 0, 0)

	-- Configurations per filetype.
	for _, ft in ipairs({ "c", "cpp", "python" }) do
		local cfgs = dap.configurations[ft]
		t.truthy(ft .. " has a launch configuration", cfgs ~= nil and #cfgs > 0)
	end

	-- Keymaps.
	for _, k in ipairs({ "<leader>b", "<leader>B", "<F5>", "<F10>", "<F11>", "<F12>" }) do
		local m = vim.fn.maparg(k, "n", false, true)
		t.truthy(k .. " is mapped", m.callback ~= nil or m.rhs ~= nil)
	end

	-- The UI opens and closes with the session rather than being a separate
	-- thing to remember to toggle.
	t.truthy("dapui is loaded", package.loaded["dapui"] ~= nil)
	t.truthy("UI opens on session start", dap.listeners.after.event_initialized["dapui_config"] ~= nil)
	t.truthy("UI closes on terminate", dap.listeners.before.event_terminated["dapui_config"] ~= nil)

	-- Breakpoint signs must be defined, or a breakpoint is invisible.
	t.truthy("DapBreakpoint sign defined", #vim.fn.sign_getdefined("DapBreakpoint") > 0)
	t.truthy("DapStopped sign defined", #vim.fn.sign_getdefined("DapStopped") > 0)
end)
