-- gruvbox-material, the dune colourscheme.
--
-- Replaced onedark to match the dune setup (savar95x dotfiles): hard
-- background, transparent, so the terminal's #151515 shows through.
-- Accent colours elsewhere in this config come from lua/dune.lua.
vim.pack.add({
	{ src = "https://github.com/sainnhe/gruvbox-material", name = "gruvbox-material" },
	{ src = "https://github.com/tadaa/vimade", name = "vimade" },
})

vim.g.gruvbox_material_background = "hard"
vim.g.gruvbox_material_transparent_background = 1
vim.g.gruvbox_material_better_performance = 1
vim.cmd.colorscheme("gruvbox-material")

-- Dim the windows that are not focused.
require("vimade").setup({
	recipe = { "minimalist", { animate = true } },
	fadelevel = 0.8,
})
