-- LaTeX. Compiles with latexmk (MacTeX), views in Skim, jumps both ways.
--
-- vimtex is a vimscript plugin with no setup() function. Every option is a
-- global variable, and each one must be set before the plugin loads. Under
-- lazy.nvim that means `init`, not `config`.
return {
	"lervag/vimtex",

	-- lazy = false is deliberate and must not change. vimtex is already a
	-- filetype plugin, so it costs nothing at startup. Lazy loading it through
	-- the plugin manager breaks inverse search, because inverse search relies
	-- on a global command that must exist before Skim calls back into Neovim.
	-- Never replace this with ft = "tex".
	lazy = false,

	init = function()
		-- Treesitter highlights every buffer, so vimtex's own syntax engine
		-- would highlight each file a second time. Turn it off and let
		-- treesitter own highlighting. vimtex still owns compiling, viewing,
		-- motions, text objects and the table of contents.
		--
		-- util/tex.lua depends on this. With vimtex's syntax engine off, the
		-- cursor-in-math test has to read the treesitter parse tree instead.
		vim.g.vimtex_syntax_enabled = 0
		vim.g.vimtex_syntax_conceal_disable = 1

		vim.g.vimtex_compiler_method = "latexmk"
		vim.g.vimtex_compiler_latexmk = {
			aux_dir = "build",
			out_dir = "build",
			continuous = 1,
			options = {
				"-shell-escape",
				"-verbose",
				"-file-line-error",
				"-synctex=1",
				"-interaction=nonstopmode",
			},
		}

		-- Skim is the only macOS viewer with working forward and inverse search.
		vim.g.vimtex_view_method = "skim"
		vim.g.vimtex_view_skim_sync = 1 -- forward search after every compile
		vim.g.vimtex_view_skim_activate = 1 -- raise Skim on forward search
		vim.g.vimtex_view_skim_reading_bar = 1 -- highlight the synced line

		-- Warnings are noisy and mostly harmless. Open the quickfix list by
		-- hand with <localleader>le instead of having it steal focus on save.
		vim.g.vimtex_quickfix_mode = 0
		vim.g.vimtex_quickfix_open_on_warning = 0

		-- Missing \label references and overfull boxes are the two warnings
		-- worth keeping. Everything else is filtered out.
		vim.g.vimtex_quickfix_ignore_filters = {
			"Underfull",
			"Font Warning",
			"Package hyperref Warning",
		}

		vim.g.vimtex_toc_config = {
			name = "Contents",
			layers = { "content", "todo", "label" },
			split_width = 40,
			show_help = 0,
		}
	end,
}
