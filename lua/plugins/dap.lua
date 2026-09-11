-- Debugging.
--
-- The previous config had none, and deliberately: tests/plugins.lua asserted
-- nvim-dap was absent. This is the largest single gap between that config and
-- an IDE, and the one that matters most for a C and C++ project. Stepping
-- through a segfault beats adding printf and rebuilding.
return {
	"mfussenegger/nvim-dap",

	dependencies = {
		{ "rcarriga/nvim-dap-ui", dependencies = { "nvim-neotest/nvim-nio" } },
		"theHamsta/nvim-dap-virtual-text",
		"mfussenegger/nvim-dap-python",
	},

	keys = {
		{ "<leader>b", function() require("dap").toggle_breakpoint() end, desc = "Toggle breakpoint" },
		{
			"<leader>B",
			function()
				vim.ui.input({ prompt = "Breakpoint condition: " }, function(cond)
					if cond and cond ~= "" then
						require("dap").set_breakpoint(cond)
					end
				end)
			end,
			desc = "Conditional breakpoint",
		},
		{ "<F5>", function() require("dap").continue() end, desc = "Debug: continue" },
		{ "<F10>", function() require("dap").step_over() end, desc = "Debug: step over" },
		{ "<F11>", function() require("dap").step_into() end, desc = "Debug: step into" },
		{ "<F12>", function() require("dap").step_out() end, desc = "Debug: step out" },
		{ "<leader>du", function() require("dapui").toggle() end, desc = "Debug: toggle UI" },
		{ "<leader>dr", function() require("dap").repl.toggle() end, desc = "Debug: REPL" },
		{ "<leader>dt", function() require("dap").terminate() end, desc = "Debug: terminate" },
	},

	config = function()
		local dap = require("dap")
		local dapui = require("dapui")

		dapui.setup()
		require("nvim-dap-virtual-text").setup({})

		-- Open the UI with the session and close it when the session ends, so
		-- there is no separate thing to remember to toggle.
		dap.listeners.after.event_initialized["dapui_config"] = function()
			dapui.open()
		end
		dap.listeners.before.event_terminated["dapui_config"] = function()
			dapui.close()
		end
		dap.listeners.before.event_exited["dapui_config"] = function()
			dapui.close()
		end

		-- lldb-dap, not gdb.
		--
		-- This machine is arm64. gdb is not installed, and Homebrew's gdb does
		-- not support arm64 macOS debugging, so the usual
		-- `gdb --interpreter=dap` advice does not apply here. lldb-dap ships
		-- with the Xcode command line tools, speaks DAP natively, and matches
		-- the clang these binaries are compiled with.
		--
		-- The absolute path is deliberate: lldb-dap is not on PATH. If an
		-- Xcode update moves it, tests/dap.lua fails on the executable check
		-- rather than the failure surfacing as a debug session that never
		-- starts.
		local lldb_dap = "/Library/Developer/CommandLineTools/usr/bin/lldb-dap"

		dap.adapters.lldb = {
			type = "executable",
			command = lldb_dap,
			name = "lldb",
		}

		local c_config = {
			{
				name = "Launch",
				type = "lldb",
				request = "launch",
				-- Asks for the binary rather than guessing it. A guess is
				-- wrong often enough that the prompt is faster overall.
				program = function()
					return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
				end,
				cwd = "${workspaceFolder}",
				stopOnEntry = false,
				args = {},
			},
		}
		dap.configurations.c = c_config
		dap.configurations.cpp = c_config

		-- debugpy. Passing the interpreter explicitly stops it picking up
		-- whichever python happens to be first on PATH inside a virtualenv.
		require("dap-python").setup(vim.fn.exepath("python3"))

		-- A breakpoint that never binds, on macOS:
		--
		-- lldb matches breakpoints by comparing the path Neovim sends against
		-- the path recorded in the binary's debug info. Neovim resolves
		-- symlinks, macOS makes /tmp a symlink to /private/tmp, and a binary
		-- compiled as /tmp/x/main.c therefore records /tmp while Neovim sends
		-- /private/tmp. The session runs to completion and exits 0, and the
		-- log says "Breakpoint unverified" if you go looking.
		--
		-- Nothing to configure. It only bites when testing under /tmp, which
		-- real projects are not.

		-- Breakpoint signs, in the palette mini.hues generated. Without these
		-- a breakpoint is set but invisible.
		vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DiagnosticError" })
		vim.fn.sign_define("DapBreakpointCondition", { text = "◆", texthl = "DiagnosticWarn" })
		vim.fn.sign_define("DapLogPoint", { text = "◆", texthl = "DiagnosticInfo" })
		vim.fn.sign_define("DapStopped", { text = "▶", texthl = "DiagnosticOk", linehl = "Visual" })
	end,
}
