-- ltex-ls-plus, the maintained fork. The original valentjn/ltex-ls has had no
-- release since 2023 and does not run on a current JDK.
--
-- It checks grammar in prose and understands both markdown and LaTeX well
-- enough to skip the markup: it does not report \alpha or a table pipe as a
-- spelling mistake.
--
-- Its own default filetype list names eighteen filetypes including gitcommit.
-- A 257MB Java server starting on every commit message is a cost with no
-- return, so this is narrowed to the two that hold prose here.
local dir = vim.fn.stdpath("config") .. "/ltex"
vim.fn.mkdir(dir, "p")

local function words(name)
	local path = dir .. "/" .. name .. ".txt"
	return vim.fn.filereadable(path) == 1 and vim.fn.readfile(path) or {}
end

-- ltex reports an added word back to the client rather than writing it itself.
-- The write goes through a set: ltex sends this every time you accept the code
-- action, including on a word the file already holds, so appending without a
-- duplicate check grew the file by one line each time the same word came up.
local function append(name)
	return function(_, params)
		local seen, out = {}, {}
		local function add(word)
			if not seen[word] then
				seen[word] = true
				out[#out + 1] = word
			end
		end
		for _, w in ipairs(words(name)) do
			add(w)
		end
		for _, list in pairs(params.words or {}) do
			for _, w in ipairs(list) do
				add(w)
			end
		end
		table.sort(out)
		vim.fn.writefile(out, dir .. "/" .. name .. ".txt")
	end
end

return {
	cmd = { "ltex-ls-plus" },
	filetypes = { "markdown", "tex" },
	root_markers = { ".git" },
	settings = {
		ltex = {
			language = "en-US",
			enabled = { "markdown", "latex", "tex" },
			dictionary = { ["en-US"] = words("dictionary") },
			disabledRules = { ["en-US"] = words("disabled-rules") },
			hiddenFalsePositives = { ["en-US"] = words("false-positives") },
			-- LanguageTool checks the whole document on every keystroke by
			-- default, which stalls a long note.
			checkFrequency = "edit",
			additionalRules = { enablePickyRules = true },
		},
	},
	handlers = {
		["ltex/workspaceSpecificConfiguration"] = function() end,
		["$/ltex/addToDictionary"] = append("dictionary"),
		["$/ltex/disableRules"] = append("disabled-rules"),
		["$/ltex/hideFalsePositives"] = append("false-positives"),
	},
}
