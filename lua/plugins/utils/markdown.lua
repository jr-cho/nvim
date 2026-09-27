-- Markdown. Renders in the buffer, previews in the browser.
--
-- render-markdown draws headings, tables, code blocks and checkboxes in place,
-- from the markdown parsers Neovim already ships. It turns off in insert mode,
-- so the raw text is what you edit.
--
-- markdown-preview opens the file in the browser and scrolls with the cursor.
-- It is the markdown counterpart of Skim for LaTeX.

-- markdown-preview runs a small server, shipped as a prebuilt binary that the
-- plugin downloads after install and after each update. vim.pack has no build
-- step, so this hook is the build step. It must exist before vim.pack.add,
-- because the first install fires it.
vim.api.nvim_create_autocmd("PackChanged", {
	callback = function(ev)
		local name, kind = ev.data.spec.name, ev.data.kind
		if name ~= "markdown-preview" or (kind ~= "install" and kind ~= "update") then
			return
		end
		if not ev.data.active then
			vim.cmd.packadd(name)
		end
		vim.fn["mkdp#util#install"]()
	end,
})

vim.pack.add({
	{ src = "https://github.com/MeanderingProgrammer/render-markdown.nvim", name = "render-markdown" },
	{ src = "https://github.com/iamcco/markdown-preview.nvim", name = "markdown-preview" },
})

require("render-markdown").setup({})
