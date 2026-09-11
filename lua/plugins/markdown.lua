-- Markdown rendering.
return {
	-- Renders markdown inside the buffer. No browser, no node or deno build
	-- step, and the file stays editable while it renders.
	"MeanderingProgrammer/render-markdown.nvim",
	dependencies = { "nvim-treesitter/nvim-treesitter" },
	ft = { "markdown" },

	opts = {
		-- The default un-renders the whole buffer the moment you enter insert
		-- mode, repainting every line on every `i`. Rendering in insert too,
		-- with anti_conceal clearing only the cursor line, keeps the rest of
		-- the screen still.
		render_modes = { "n", "c", "t", "i" },
		anti_conceal = { enabled = true },
		heading = { sign = false },
		code = { sign = false, width = "block", min_width = 40, left_pad = 2, right_pad = 2 },
	},

	keys = {
		{ "<leader>um", "<cmd>RenderMarkdown buf_toggle<CR>", desc = "Toggle markdown rendering" },
	},
}
