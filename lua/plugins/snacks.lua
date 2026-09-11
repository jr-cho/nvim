-- snacks.nvim: the workflow layer.
--
-- The division with mini.nvim is fixed and should stay that way. Nine
-- capabilities exist in both suites, and choosing per module rather than per
-- suite is how a config ends up with two notifiers and two indent guides
-- fighting each other.
--   snacks owns: picker, explorer, terminal, image, input, notifier, bigfile.
--   mini owns:   editing verbs, statusline, tabline, icons, colours, diff.
return {
	"folke/snacks.nvim",
	priority = 1000,
	lazy = false,

	opts = {
		-- Listing a module here is what turns it on. Anything absent stays
		-- off, so this table is the full list of what snacks is doing.
		bigfile = { enabled = true },
		quickfile = { enabled = true },
		input = { enabled = true },
		notifier = { enabled = true, timeout = 3000 },
		indent = { enabled = true },
		picker = { enabled = true },
		explorer = { enabled = true },

		terminal = {
			-- Matches winborder in options.lua and the rest of the config.
			win = { border = "rounded" },
		},

		-- Inline images, and LaTeX maths rendered as maths rather than shown
		-- as source. This draws over the Kitty graphics protocol, which
		-- Ghostty speaks, so a $$ block in a note appears typeset in the
		-- buffer.
		--
		-- It shells out to work: latex and dvipng from MacTeX for the maths,
		-- magick for images. All four are installed. In a terminal with no
		-- graphics protocol it degrades to showing the source, which is what
		-- the previous config did all the time.
		image = { enabled = true },
	},

	keys = function()
		-- Each position carries its own count. Snacks keys a terminal by cmd,
		-- cwd, env and count; the window position is not part of that key, so
		-- without a count these three keys reach for one terminal and only
		-- move it around the screen.
		--
		-- cwd is left to snacks, which reads the window's working directory.
		-- Terminals are therefore per project: :lcd into another repository
		-- and these open that repository's terminal.
		local terms = {
			float = { count = 1, win = { position = "float", width = 0.88, height = 0.85 } },
			vertical = { count = 2, win = { position = "right", width = 0.4 } },
			horizontal = { count = 3, win = { position = "bottom", height = 0.35 } },
		}

		-- focus, never toggle. Snacks.terminal.toggle asks only whether the
		-- buffer sits in a window, so a visible-but-unfocused terminal gets
		-- closed rather than focused: click off a float, press the key, and it
		-- vanished instead of taking you back. focus answers all three states:
		-- open it, focus it, hide it.
		local function term(name)
			return function()
				Snacks.terminal.focus(nil, terms[name])
			end
		end

		return {
			-- Find
			{ "<leader>ff", function() Snacks.picker.files() end, desc = "Find files" },
			{ "<leader>fg", function() Snacks.picker.grep() end, desc = "Grep project" },
			{ "<leader>fb", function() Snacks.picker.buffers() end, desc = "Buffers" },
			{ "<leader>fh", function() Snacks.picker.help() end, desc = "Help pages" },
			{ "<leader>fk", function() Snacks.picker.keymaps() end, desc = "Keymaps" },
			{ "<leader>fd", function() Snacks.picker.diagnostics() end, desc = "Diagnostics" },
			{ "<leader>fr", function() Snacks.picker.recent() end, desc = "Recent files" },

			-- Explorer
			{ "<leader>e", function() Snacks.explorer() end, desc = "File explorer" },

			-- Terminals. Normal mode only: leader is Space, and a terminal
			-- forwards every keystroke to the program inside it, so a
			-- terminal-mode <leader>th would fire while you typed "the".
			{ "<leader>tt", term("float"), desc = "Toggle floating terminal" },
			{ "<leader>tv", term("vertical"), desc = "Toggle vertical terminal" },
			{ "<leader>th", term("horizontal"), desc = "Toggle horizontal terminal" },

			-- Dismissing from inside needs a chord no program expects.
			{ "<A-t>", term("float"), mode = "t", desc = "Hide floating terminal" },
			{ "<A-v>", term("vertical"), mode = "t", desc = "Hide vertical terminal" },
			{ "<A-h>", term("horizontal"), mode = "t", desc = "Hide horizontal terminal" },

			-- Git
			{ "<leader>gg", function() Snacks.lazygit() end, desc = "Lazygit" },
			{ "<leader>gb", function() Snacks.gitbrowse() end, desc = "Open in browser" },
		}
	end,
}
