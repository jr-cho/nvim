local t = require("testkit")

t.run(function()
	-- Each mini module does nothing until it is set up, so the global it
	-- exports is the evidence that lua/plugins/mini.lua actually ran.
	for _, g in ipairs({ "MiniIcons", "MiniStatusline", "MiniTabline" }) do
		t.truthy(g .. " is active", _G[g] ~= nil)
	end

	-- mini.hues must stay off. It was tried as the colourscheme and replaced:
	-- generating a palette from a background and a foreground cannot know that
	-- keywords should be purple, and it left @keyword and @type the same grey
	-- as ordinary text. onedark owns colours now, in lua/plugins/colorscheme.lua.
	t.check("mini.hues is off", _G.MiniHues, nil)

	local normal = vim.api.nvim_get_hl(0, { name = "Normal" })
	t.check("background is onedark", string.format("#%06x", normal.bg), "#282c34")
	t.check("foreground is onedark", string.format("#%06x", normal.fg), "#abb2bf")

	-- mini.statusline owns the statusline, not Neovim's default.
	t.truthy("statusline is mini's", vim.o.statusline:match("MiniStatusline") ~= nil)

	-- One icon set, not two. Other plugins ask for nvim-web-devicons by name,
	-- and mock_nvim_web_devicons makes mini.icons answer to that name.
	--
	-- The mock registers a loader rather than populating package.loaded, so
	-- checking package.loaded proves nothing until something has required it.
	-- Require it here and check that what answers is mini.
	local ok, devicons = pcall(require, "nvim-web-devicons")
	t.truthy("nvim-web-devicons resolves", ok)
	local _, hl = devicons.get_icon("init.lua", "lua", { default = true })
	t.truthy("icons come from mini, not a second set", hl and hl:match("^MiniIcons") ~= nil)
end)
