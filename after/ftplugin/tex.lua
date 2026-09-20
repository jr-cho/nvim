-- LaTeX buffer settings.
--
-- after/ftplugin runs once vimtex's own ftplugin has already run, so anything
-- set here is the last word.

-- Prose deserves a spell checker. z= corrects the word under the cursor,
-- ]s and [s move between mistakes.
vim.opt_local.spell = true
vim.opt_local.spelllang = "en_us"

-- Never hard-wrap. init.lua already wraps long lines on screen, and keeping one
-- paragraph on one line means a one-word edit is a one-word diff.
vim.opt_local.textwidth = 0

-- tex-fmt writes spaces, and the global default here is a hard tab. Without
-- this, every save would rewrite the indentation of every line you touched.
vim.opt_local.expandtab = true
vim.opt_local.shiftwidth = 2
vim.opt_local.softtabstop = 2

-- LaTeX commands under <leader>c, in addition to vimtex's own <localleader>l.
--
-- Reaching for backslash mid-sentence is awkward when every other command in
-- this config starts with Space, so the ones used constantly get a Space
-- binding too. vimtex's <localleader>l set is untouched and still works, and
-- it remains the full set: this is the handful worth a faster key.
--
-- <leader>c, not <leader>l. Making maplocalleader Space would put vimtex and
-- the LSP table under the same <leader>l prefix, and they collide on five
-- letters: la, li, lt, lo and ls are meaningful to both. c is free and reads
-- as compile.
--
-- Buffer-local, so <leader>c means nothing outside a .tex file.
local function map(lhs, rhs, desc)
	vim.keymap.set("n", lhs, rhs, { buffer = true, silent = true, desc = desc })
end

map("<leader>cc", "<cmd>VimtexCompile<CR>", "Compile (toggle continuous)")
map("<leader>cv", "<cmd>VimtexView<CR>", "View PDF in Skim")
map("<leader>ck", "<cmd>VimtexStop<CR>", "Stop compiling")
map("<leader>ce", "<cmd>VimtexErrors<CR>", "Errors")
map("<leader>ct", "<cmd>VimtexTocToggle<CR>", "Table of contents")
map("<leader>cl", "<cmd>VimtexClean<CR>", "Clean build directory")
map("<leader>cs", "<cmd>VimtexStatus<CR>", "Compiler status")
