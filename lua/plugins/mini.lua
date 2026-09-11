-- mini.nvim.
--
-- One repository, ~45 independent modules. Each is enabled by an explicit
-- setup() call below and does nothing until it gets one, so this file is the
-- full list of what mini is doing in this config.
--
-- The split with snacks.nvim is deliberate and should stay this way: nine
-- capabilities exist in both, and picking from each ad hoc is how a config
-- ends up with two notifiers and two indent guides fighting each other.
--   mini   owns editing and appearance.
--   snacks owns workflow: picker, explorer, terminal, images.
return {
	"echasnovski/mini.nvim",
	version = false,

	config = function()
		-- No colourscheme here. mini.hues was tried and replaced by real
		-- onedark in lua/plugins/colorscheme.lua: generating a palette from two
		-- base colours cannot know that keywords should be purple, and left
		-- @keyword and @type the same grey as ordinary text.
		require("mini.icons").setup()

		-- snacks and other plugins ask for nvim-web-devicons by name. This makes
		-- mini.icons answer to that name so there is one icon set, not two.
		MiniIcons.mock_nvim_web_devicons()

		-- Content lives in lua/statusline.lua. The default shows a full path,
		-- the encoding and the byte size, and no git or diagnostic state.
		require("mini.statusline").setup({
			content = {
				active = function()
					return require("statusline").active()
				end,
				inactive = function()
					return require("statusline").inactive()
				end,
			},
			use_icons = true,
		})

		require("mini.tabline").setup({
			show_icons = true,
			-- The tab-page count belongs on the right, away from the buffer
			-- names. On the left it shifts every name across the moment a
			-- second tab exists.
			tabpage_section = "right",
			format = function(buf_id, label)
				local suffix = vim.bo[buf_id].modified and " ● " or ""
				return MiniTabline.default_format(buf_id, label) .. suffix
			end,
		})

		-- ---------------------------------------------------------------
		-- Editing verbs
		-- ---------------------------------------------------------------

		-- Extra a/i textobjects, including function and class from the parse
		-- tree. The treesitter layer is what makes af and ac work.
		local ai = require("mini.ai")
		ai.setup({
			n_lines = 500,
			custom_textobjects = {
				f = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }),
				c = ai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }),
			},
		})

		-- Surround under gs, not s. Plain s is wanted by the built-in
		-- substitute and by jump plugins, and taking it costs more than the
		-- two extra keystrokes save.
		require("mini.surround").setup({
			mappings = {
				add = "gsa",
				delete = "gsd",
				find = "gsf",
				find_left = "gsF",
				highlight = "gsh",
				replace = "gsr",
				update_n_lines = "gsn",
			},
		})

		-- Operators, moved off every key they would otherwise take.
		--
		-- The defaults are g=, gx, gm, gr and gs, and three of those are
		-- already spoken for:
		--   gr  is the whole native LSP namespace. Taking it removes grn,
		--       gra, grr, gri, grt and grx, which is rename, code action,
		--       references, implementation, type definition and codelens.
		--   gs  is where surround lives, two lines above.
		--   gx  is Neovim's open-the-URL-under-the-cursor.
		--
		-- sort is disabled rather than moved. :sort already does it, and every
		-- remaining g-key worth having costs more than it returns.
		require("mini.operators").setup({
			evaluate = { prefix = "g=" },
			exchange = { prefix = "gX" },
			multiply = { prefix = "gM" },
			replace = { prefix = "gR" },
			sort = { prefix = "" },
		})

		-- Move a selection with Alt+hjkl, reindenting as it goes.
		require("mini.move").setup()

		-- Split and join argument lists with gS.
		require("mini.splitjoin").setup()

		-- Autopairs.
		require("mini.pairs").setup()

		-- [b ]b buffers, [q ]q quickfix, and so on.
		require("mini.bracketed").setup()

		-- Align with ga and gA.
		require("mini.align").setup()

		-- No mini.clue. which-key does this in lua/plugins/whichkey.lua: it
		-- discovers the keys under a prefix on its own, where mini.clue needed
		-- every one listed by hand.

		-- ---------------------------------------------------------------
		-- Git
		-- ---------------------------------------------------------------

		-- Hunk signs, staging and the diff overlay. This replaces gitsigns.
		-- snacks has no equivalent, and lazygit covers the parts that want a
		-- full interface rather than an inline one.
		--
		-- The default mappings are kept: gh applies a hunk as an operator, gH
		-- resets one, [h and ]h navigate, [H and ]H jump to first and last.
		-- gh is Vim's start-Select-mode, which nothing uses, and none of them
		-- touch the native LSP gr namespace.
		require("mini.diff").setup({
			view = { style = "sign", signs = { add = "▎", change = "▎", delete = "" } },
		})

		-- :Git commands, plus the blame and log buffers.
		require("mini.git").setup()

		local function gmap(lhs, rhs, desc)
			vim.keymap.set("n", lhs, rhs, { silent = true, desc = desc })
		end

		-- Act on the hunk under the cursor.
		--
		-- The range is not optional. MiniDiff.do_hunks(buf, action) with no
		-- opts defaults to line_start = 1 and line_end = the last line of the
		-- buffer, so omitting it stages or discards every change in the file
		-- rather than the one you are looking at. Discarding a whole file by
		-- accident is not a recoverable mistake.
		local function hunk(action)
			return function()
				local line = vim.fn.line(".")
				MiniDiff.do_hunks(0, action, { line_start = line, line_end = line })
			end
		end

		gmap("<leader>gs", hunk("apply"), "Stage hunk under cursor")
		gmap("<leader>gr", hunk("reset"), "Reset hunk under cursor")
		gmap("<leader>go", MiniDiff.toggle_overlay, "Toggle diff overlay")
		gmap("<leader>gl", function()
			vim.cmd("Git log --oneline -20 -- " .. vim.fn.expand("%"))
		end, "History for this file")
	end,
}
