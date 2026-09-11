-- Test helper for headless Neovim checks. Lives under lua/ so that require
-- can find it: Neovim searches lua/ inside the runtimepath, and the config
-- directory is on that path.
--
-- Plugins load on the VeryLazy event, which fires after UIEnter. A headless
-- Neovim has no UI, so a test that reads plugin state immediately sees nothing.
-- M.run defers the check onto the event loop, which is late enough.
local M = {}

local failures = {}

function M.check(name, got, want)
	if got ~= want then
		table.insert(failures, string.format("%s: got %s, want %s", name, vim.inspect(got), vim.inspect(want)))
	else
		print("ok   " .. name)
	end
end

function M.truthy(name, got)
	if got then
		print("ok   " .. name)
	else
		table.insert(failures, name .. ": got falsy value")
	end
end

function M.finish()
	for _, f in ipairs(failures) do
		print("FAIL " .. f)
	end
	os.exit(#failures == 0 and 0 or 1)
end

-- Runs fn once the event loop is ready, then exits with the right status.
--
-- A test that only makes synchronous checks passes no second argument. A test
-- that has to wait for window events passes async = true, and is then
-- responsible for calling M.finish() itself. Without that split, M.run would
-- exit while a deferred check was still queued and the check would never run.
function M.run(fn, async)
	-- Watchdog. Without qa! ending the process, a test whose checks never
	-- complete would hang the runner forever. Exit 2 instead, so a hang is
	-- distinguishable from a failure (1) and a pass (0).
	vim.defer_fn(function()
		-- Print whatever already failed before the hang. Exiting straight to 2
		-- would throw away the diagnostics of checks that did run.
		for _, f in ipairs(failures) do
			print("FAIL " .. f)
		end
		print("TIMEOUT: checks did not complete within 30s")
		os.exit(2)
	end, 30000)

	vim.defer_fn(function()
		local ok, err = pcall(fn)
		if not ok then
			table.insert(failures, "error: " .. tostring(err))
			M.finish()
			return
		end
		if not async then
			M.finish()
		end
	end, 800)
end

return M
