local t = require("testkit")

-- The two things every later layer assumes: the config loads, and the leader
-- keys are what its keymaps will be written against.
t.run(function()
	t.check("leader is space", vim.g.mapleader, " ")
	t.check("localleader is backslash", vim.g.maplocalleader, "\\")
	t.check("tex_flavor", vim.g.tex_flavor, "latex")

	-- A Lua error in init.lua still lets Neovim start, so "it opened" is not
	-- evidence that it loaded.
	t.check("no startup errors", vim.v.errmsg, "")

	-- lazy bootstrapped itself and is managing the spec, rather than the clone
	-- having silently failed and left an empty directory behind.
	t.truthy("lazy is loaded", package.loaded["lazy"] ~= nil)
	local plugins = require("lazy.core.config").plugins
	t.truthy("lazy manages plugins", vim.tbl_count(plugins) > 0)

	-- Declared is not installed. lazy keeps a spec entry for a plugin whose
	-- clone failed, so stat the directory too.
	for name, spec in pairs(plugins) do
		t.truthy(name .. " is on disk", spec.dir and vim.uv.fs_stat(spec.dir) ~= nil)
	end

	-- No update check on startup. A background git fetch every time Neovim
	-- opens is an unannounced dependency on the network.
	t.check("no background update checker", require("lazy.core.config").options.checker.enabled, false)
end)
