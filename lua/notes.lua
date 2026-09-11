-- Notes.
--
-- A notes tree is a directory of markdown files and nothing else. No index, no
-- database, no second tool. The picker reads a directory faster than an index
-- would, so these three keys are the whole feature.
--
-- Set vim.g.notes_dir to point somewhere other than ~/SCHOOL. options.lua
-- turns exrc on, so a per-project .nvim.lua is read after you confirm its hash.
local function notes_dir()
	return vim.fn.expand(vim.g.notes_dir or "~/SCHOOL")
end

local function map(lhs, rhs, desc)
	vim.keymap.set("n", lhs, rhs, { silent = true, desc = desc })
end

map("<leader>nf", function()
	Snacks.picker.files({ cwd = notes_dir(), title = "Notes" })
end, "Find note")

map("<leader>ng", function()
	Snacks.picker.grep({ cwd = notes_dir(), title = "Grep notes" })
end, "Grep notes")

-- Asks for a path relative to the notes root, creates any missing directory in
-- it, and opens the file. autocmds.lua also creates parent directories on
-- write, but doing it here means the tree exists before you start typing.
map("<leader>nn", function()
	vim.ui.input({ prompt = "New note (path under " .. notes_dir() .. "): " }, function(name)
		if not name or name == "" then
			return
		end
		if not name:match("%.md$") then
			name = name .. ".md"
		end
		local path = notes_dir() .. "/" .. name
		vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
		vim.cmd("edit " .. vim.fn.fnameescape(path))
	end)
end, "New note")
