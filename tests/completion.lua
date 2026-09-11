local t = require("testkit")

t.run(function()
	-- 'autocomplete' is new in 0.12 and is the whole completion engine. It is
	-- off by default, which is why insert mode showed nothing while K worked:
	-- hover is native and needs no trigger, completion needs this.
	t.check("autocomplete on", vim.o.autocomplete, true)

	-- "popup" is what puts documentation beside the menu rather than in a
	-- separate preview window.
	t.truthy("completeopt has popup", vim.o.completeopt:match("popup") ~= nil)
	t.truthy("completeopt has menuone", vim.o.completeopt:match("menuone") ~= nil)
	t.truthy("completeopt has noselect", vim.o.completeopt:match("noselect") ~= nil)

	-- The menu must not fill the screen on a long completion list.
	t.check("pumheight bounded", vim.o.pumheight, 12)

	-- vim.lsp.completion is attached per buffer on LspAttach rather than
	-- globally, so a buffer with no server does not advertise LSP completion.
	local found = false
	for _, au in ipairs(vim.api.nvim_get_autocmds({ event = "LspAttach" })) do
		if au.group_name == "user_lsp_attach" then
			found = true
		end
	end
	t.truthy("completion attaches on LspAttach", found)

	-- Snippet jumping is native and already bound. A plugin for it would be
	-- re-implementing core.
	t.truthy("Tab jumps snippets", vim.fn.maparg("<Tab>", "i") ~= "")
	t.truthy("S-Tab jumps snippets", vim.fn.maparg("<S-Tab>", "i") ~= "")
end)
