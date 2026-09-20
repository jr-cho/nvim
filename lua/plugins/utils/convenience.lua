vim.pack.add({
	{ src = "https://github.com/okuuva/auto-save.nvim", name = "autosave" },
	{ src = "https://github.com/vladdoster/remember.nvim", name = "remember" },
	{ src = "https://github.com/Aasim-A/scrollEOF.nvim", name = "scrolleof" },
	{ src = "https://github.com/folke/flash.nvim", name = "flash" },
})

require("auto-save").setup({
	enabled = true,
	trigger_events = {
		immediate_save = { "BufLeave", "FocusLost", "QuitPre", "VimSuspend" },
		defer_save = { "InsertLeave" }, -- save after debounce
		cancel_deferred_save = { "InsertEnter" }, -- cancel pending save
	},
	debounce_delay = 1000,
	noautocmd = true,
})

-- Restore the cursor to where it was when a file was last open.
require("remember").setup({})

require("scrollEOF").setup({
	pattern = "*",
	insert_mode = false,
	floating = true,
	disabled_filetypes = { "terminal", "pokedash" },
	disabled_modes = { "t", "nt" },
})
