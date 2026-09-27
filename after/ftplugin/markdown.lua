-- Markdown buffer settings.

-- Prose deserves a spell checker. z= corrects the word under the cursor,
-- ]s and [s move between mistakes.
vim.opt_local.spell = true
vim.opt_local.spelllang = "en_us"

-- Browser preview under <leader>c, the same key that views the PDF in a .tex
-- file. Buffer-local, so <leader>cv means nothing outside markdown.
vim.keymap.set("n", "<leader>cv", "<cmd>MarkdownPreviewToggle<CR>", {
	buffer = true,
	silent = true,
	desc = "Preview in browser",
})
