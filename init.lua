-- Entry point.
--
-- Order matters here and nowhere else in the config:
--   1. Leader keys, before any plugin can bind them.
--   2. Bootstrap the plugin manager.
--   3. Hand off to lazy, which loads everything under lua/plugins/.
--
-- Anything that is not one of those three things belongs in a module.

-- A plugin that maps <Leader> or <LocalLeader> reads whatever these hold at
-- the moment it binds. Setting them after lazy runs would leave those maps
-- pointing at the old key.
--
-- Backslash is also Vim's default when maplocalleader is unset, which is why
-- vimtex appeared to work in the previous config without this line. It worked
-- by accident.
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Neovim decides whether a .tex file is plain TeX or LaTeX by scanning it, and
-- calls anything without \documentclass, \usepackage or \begin{ "plaintex".
-- A brand new .tex file has none of those, so without this it opens as
-- plaintex and no LaTeX ftplugin or snippet ever runs.
vim.g.tex_flavor = "latex"

-- lazy.nvim, cloned on first start.
--
-- Neovim 0.12 ships vim.pack, which would remove this dependency. It is not
-- used here on purpose: it has no lazy loading, no dependency ordering and no
-- build hooks, and this config leans on all three. Revisit if that changes.
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.uv.fs_stat(lazypath) then
	local out = vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"--branch=stable",
		"https://github.com/folke/lazy.nvim.git",
		lazypath,
	})
	-- A failed clone leaves an empty directory that looks installed on the next
	-- start, so say so loudly rather than booting into a half state.
	if vim.v.shell_error ~= 0 then
		error("lazy.nvim clone failed:\n" .. out)
	end
end

vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
	spec = { { import = "plugins" } },

	-- No automatic update checks. A background git fetch on every start is a
	-- surprise dependency on the network, and `:Lazy sync` is one command.
	checker = { enabled = false },
	change_detection = { notify = false },

	-- The colorscheme lazy uses for its own install screen on a fresh clone,
	-- before any plugin has loaded.
	install = { colorscheme = { "habamax" } },
})

-- After lazy, so a plugin cannot claim an option or a key before this config
-- has had its say. Each module owns one thing and reads nothing from the
-- others.
require("options")
require("autocmds")
require("keymaps")
require("lsp")
require("notes")

-- Start screen. Draws a 24-bit colour sprite from art/, which nvdash could not
-- do: it renders its header as one virt_text chunk per line with a single
-- highlight group, so it cannot show more than one colour.
require("pokedash").setup()
require("cheatsheet").setup()
