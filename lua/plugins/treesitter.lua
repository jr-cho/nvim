-- Treesitter parsers and highlighting.
--
-- Neovim ships the treesitter runtime and a handful of parsers itself: on
-- 0.12.4 that is c, lua, markdown, markdown_inline, vim, vimdoc and query.
-- This plugin is the installer for everything else, plus the query files that
-- turn a parse tree into highlights and textobjects.
return {
	"nvim-treesitter/nvim-treesitter",
	branch = "main",
	build = ":TSUpdate",
	lazy = false,

	-- The textobject queries are a separate repository. nvim-treesitter's main
	-- branch ships parsers and highlight queries only, with no
	-- queries/<lang>/textobjects.scm anywhere on the runtimepath, so
	-- mini.ai's @function.outer fails with "Can not get query for buffer".
	--
	-- This is a data package rather than a plugin: it is scheme queries, one
	-- file per language. Writing them by hand for six languages is not the
	-- same proposition as writing five twelve-line LSP server definitions.
	dependencies = {
		{ "nvim-treesitter/nvim-treesitter-textobjects", branch = "main" },
	},

	config = function()
		-- latex, markdown and markdown_inline are load-bearing, not cosmetic.
		-- lua/util/tex.lua answers "is the cursor inside maths" from the parse
		-- tree, and markdown_inline is what wraps $x$ in a latex_block with the
		-- latex parser injected into it. Remove any of the three and every
		-- maths snippet stops firing, with no error to say why.
		local parsers = {
			"c",
			"cpp",
			"python",
			"lua",
			"bash",
			"json",
			"markdown",
			"markdown_inline",
			"latex",
			"vim",
			"vimdoc",
			"query",
			"diff",
			"gitcommit",
		}

		-- install() is asynchronous and returns immediately. Missing parsers
		-- are fetched in the background on the first start; nothing here waits
		-- on the network, so a slow clone delays highlighting rather than
		-- Neovim itself.
		require("nvim-treesitter").install(parsers)

		-- Start highlighting for any buffer whose language has a parser.
		-- pcall because a filetype with no parser is ordinary, not an error.
		vim.api.nvim_create_autocmd("FileType", {
			group = vim.api.nvim_create_augroup("user_treesitter", { clear = true }),
			callback = function()
				pcall(vim.treesitter.start)
			end,
		})
	end,
}
