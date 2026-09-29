-- Dune palette for Neovim.
--
-- Reads ~/.config/dune/palette.env, the one file every part of the dune
-- setup takes its colours from, and returns it as a table:
--   require("dune").BG  -> "#151515"
-- Keys drop the DUNE_ prefix. A missing file gives the fallbacks below, so
-- Neovim still starts on a machine without the dune setup.
local M = {
	BG = "#151515",
	BG_ALT = "#212121",
	FG = "#fbf1c7",
	GREY = "#a89984",
	DIM = "#928374",
	C1 = "#d67b76",
	C5 = "#cb8e9e",
}

local f = io.open(os.getenv("HOME") .. "/.config/dune/palette.env", "r")
if f then
	for line in f:lines() do
		local key, value = line:match("^DUNE_([%w_]+)=(#%x%x%x%x%x%x)")
		if key then
			M[key] = value
		end
	end
	f:close()
end

return M
