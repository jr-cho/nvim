-- Loads every module under lua/plugins/, recursively.
--
-- Each of those modules calls vim.pack.add itself and configures what it
-- added, so there is no spec table to keep in order. A new file in any
-- subdirectory is picked up with no edit here.
local lua_path = vim.fn.stdpath("config") .. "/lua"
local plugin_dir = lua_path .. "/plugins"

local files = vim.fn.split(vim.fn.globpath(plugin_dir, "**/*.lua"), "\n")

for _, file in ipairs(files) do
	-- /Users/me/.config/nvim/lua/plugins/ui/lualine.lua -> plugins.ui.lualine
	local module_path = file:sub(#lua_path + 2):gsub("%.lua$", ""):gsub("/", ".")

	-- Do not require this file from itself.
	if module_path ~= "plugins.init" and module_path ~= "plugins" then
		local ok, err = pcall(require, module_path)
		if not ok then
			vim.notify("Error loading " .. module_path .. ": " .. err, vim.log.levels.ERROR)
		end
	end
end
