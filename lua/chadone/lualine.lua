-- chadone lualine theme, built from the palette (NvChad-statusline-like mode colors)
-- Usage: require("lualine").setup({ options = { theme = require("chadone.lualine") } })

local c = require("chadone.palette").base_30

-- one mode: a = bold mode block, b = lighter segment, c = statusline background
local function mode(color)
  return {
    a = { fg = c.black, bg = color, gui = "bold" },
    b = { fg = c.white, bg = c.one_bg2 },
    c = { fg = c.light_grey, bg = c.statusline_bg },
  }
end

return {
  normal = mode(c.blue),
  insert = mode(c.green),
  visual = mode(c.purple),
  replace = mode(c.red),
  command = mode(c.yellow),
  terminal = mode(c.vibrant_green),
  inactive = {
    a = { fg = c.grey_fg2, bg = c.statusline_bg },
    b = { fg = c.grey_fg2, bg = c.statusline_bg },
    c = { fg = c.grey_fg, bg = c.statusline_bg },
  },
}
