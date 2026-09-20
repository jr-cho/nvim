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
