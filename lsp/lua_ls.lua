-- lua-language-server.
return {
	cmd = { "lua-language-server" },
	filetypes = { "lua" },
	root_markers = { ".luarc.json", ".luarc.jsonc", ".stylua.toml", ".git" },
	settings = {
		Lua = {
			runtime = { version = "LuaJIT" },
			workspace = {
				checkThirdParty = false,
				library = {
					vim.env.VIMRUNTIME .. "/lua",
					"${3rd}/luv/library",
				},
			},
			-- Snacks and MiniIcons are set by their plugins at runtime, so the
			-- server would otherwise report every use of them as undefined.
			diagnostics = { globals = { "vim", "Snacks", "MiniIcons" } },
			telemetry = { enable = false },
			-- stylua does this, through conform in Task 7.
			format = { enable = false },
		},
	},
}
