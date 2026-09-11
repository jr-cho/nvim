-- LuaSnip.
--
-- Kept rather than replaced by vim.snippet or mini.snippets. Neither expands a
-- trigger as you type with no confirm key, and snippets/tex.lua is 420 lines
-- of maths triggers that depend on exactly that.
return {
	"L3MON4D3/LuaSnip",
	event = "InsertEnter",

	config = function()
		local ls = require("luasnip")

		ls.config.set_config({
			-- Without this every `mk` would need a completion menu and a
			-- confirm key. The tex snippets expand as you type.
			enable_autosnippets = true,

			-- Leaving a snippet's region ends it. Without these, moving the
			-- cursor back into a finished snippet re-enters it and the next
			-- <Tab> jumps to a placeholder already filled in.
			region_check_events = { "CursorMoved", "InsertLeave" },
			delete_check_events = "TextChanged",
			update_events = { "TextChanged", "TextChangedI" },
		})

		require("luasnip.loaders.from_lua").lazy_load({
			paths = { vim.fn.stdpath("config") .. "/snippets" },
		})

		-- A markdown buffer gets the tex snippet file too. Notes are prose
		-- with maths in them, and copying 420 lines of triggers into a second
		-- file would leave two copies to keep in step.
		--
		-- Safe because util/tex.lua answers "is the cursor in maths" from the
		-- parse tree, and markdown injects the latex parser into $...$. The
		-- LaTeX-only snippets in that file carry a filetype test of their own,
		-- so \section never offers itself in a note.
		ls.filetype_extend("markdown", { "tex" })

		vim.api.nvim_create_user_command("SnipReload", function()
			require("luasnip.loaders.from_lua").load({
				paths = { vim.fn.stdpath("config") .. "/snippets" },
			})
			vim.notify("Snippets reloaded")
		end, { desc = "Reload LuaSnip snippet files" })
	end,
}
