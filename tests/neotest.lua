local t = require("testkit")

t.run(function()
	local neotest = require("neotest")
	t.truthy("neotest loaded", neotest ~= nil)
	t.truthy("neotest.run.run exists", type(neotest.run.run) == "function")
	t.truthy("neotest.summary exists", neotest.summary ~= nil)

	-- At least one adapter, or neotest finds no tests anywhere and reports
	-- nothing rather than failing.
	local config = require("neotest.config")
	t.truthy("at least one adapter registered", #config.adapters > 0)

	-- pytest must be reachable, or every run reports zero tests.
	t.check("pytest available", vim.fn.system({ "python3", "-m", "pytest", "--version" }) ~= "" and 1 or 0, 1)

	-- Keys live under <leader>T, capitalised, because <leader>t is the
	-- terminal prefix. A lowercase collision would make both wait out
	-- timeoutlen before either could fire.
	for _, k in ipairs({ "<leader>Tt", "<leader>Tf", "<leader>Ts", "<leader>To", "<leader>Td" }) do
		local m = vim.fn.maparg(k, "n", false, true)
		t.truthy(k .. " is mapped", m.callback ~= nil or m.rhs ~= nil)
	end

	-- The terminal prefix must still work. This is the collision guard.
	for _, k in ipairs({ "<leader>tt", "<leader>tv", "<leader>th" }) do
		local m = vim.fn.maparg(k, "n", false, true)
		t.truthy(k .. " still opens a terminal", m.callback ~= nil)
	end
end)
