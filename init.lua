-- Entry point: leaders, then options, plugin manager, autocmds, keymaps.
vim.g.mapleader = " "
vim.g.maplocalleader = " "

require("config.options")
require("config.lazy")
require("config.autocmds")
require("config.keymaps")
require("ide.build") -- registers :Build, :Run, :Test, :CMakeConfigure, ...
