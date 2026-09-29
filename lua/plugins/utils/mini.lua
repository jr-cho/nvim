vim.pack.add({ { src = "https://github.com/echasnovski/mini.nvim", name = "mini" } })

require("mini.pairs").setup() -- Bracket pairs and stuff

require("mini.ai").setup() -- Around and In extension for visual mode

require("mini.cursorword").setup() -- Underline current word below cursor (makes it easier to c and d)

require("mini.indentscope").setup({ -- shows indents
	symbol = "│",
	draw = {
		delay = 10,
		animation = require("mini.indentscope").gen_animation.linear({
			duration = 15,
			unit = "step",
			easing = "out",
		}),
	},
})

require("mini.trailspace").setup() -- Shows useless spaces

require("mini.sessions").setup({ -- dir based session management
	autoread = true,
	autowrite = true,
	file = ".session",
	force = { read = false, write = true, delete = true },
})

-- autowrite only saves a session that is already active, so a directory
-- without a .session never gets one. On a bare `nvim` that loaded no session,
-- make ./.session the active one and let autowrite create it on quit.
-- Runs after the autoread above because it is registered later.
-- `nvim file.txt` (and `git commit`) is skipped so it never overwrites a session.
vim.api.nvim_create_autocmd("VimEnter", {
	once = true,
	callback = function()
		if vim.fn.argc(-1) == 0 and vim.v.this_session == "" then
			vim.v.this_session = vim.fn.getcwd() .. "/.session"
		end
	end,
})

require("mini.surround").setup() -- Surround selections with characters

require("mini.move").setup({ -- move selection in visual mode
	mappings = {
		down = "J",
		up = "K",
	},
})

require("mini.icons").setup() -- Icon provider

local animate = require("mini.animate")
require("mini.animate").setup({
	cursor = {
		enable = false,
	},
	scroll = {
		timing = animate.gen_timing.linear({ duration = 100, unit = "total" }),
		subscroll = animate.gen_subscroll.equal({ max_output_steps = 60 }),
	},
})
