-- LSP: diagnostics, the keymaps Neovim does not already provide, and the
-- servers to enable. Server definitions live one-per-file under lsp/, which
-- vim.lsp.config reads off the runtimepath. That is why nvim-lspconfig is not
-- here: on 0.11+ it is a data package, and four servers are 60 lines to own.
--
-- Neovim 0.12 binds a lot of this itself and none of it is repeated below:
--   grn  rename          gra  code action     grr  references
--   gri  implementation  grt  type definition grx  run codelens
--   gO   document symbol K    hover           <C-s> signature help (insert)
-- It also sets three buffer options on every attach: tagfunc, so <C-]> goes to
-- the definition; omnifunc, so <C-x><C-o> is LSP completion; and formatexpr,
-- so gq formats through the server.

vim.diagnostic.config({
	-- Virtual text truncates a long clangd error and pushes code off screen.
	-- virtual_lines shows the whole message on its own line underneath, and
	-- current_line limits that to the line the cursor is on, so a file full of
	-- warnings stays readable.
	virtual_text = false,
	virtual_lines = { current_line = true },
	underline = true,
	update_in_insert = false,
	severity_sort = true,
	float = { border = "rounded", source = true },
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = " ",
			[vim.diagnostic.severity.WARN] = " ",
			[vim.diagnostic.severity.INFO] = " ",
			[vim.diagnostic.severity.HINT] = " ",
		},
	},
})

-- One prefix: <leader>l.
--
-- An earlier version of this file also bound <D-l>, on the reasoning that
-- Neovim encodes Command with a real modifier bit and Ghostty speaks the Kitty
-- keyboard protocol. Neovim does. Ghostty, on this machine, does not forward
-- it: pressing Cmd+L delivers a bare "l".
--
-- That makes the Command half worse than merely dead. The leading "l" is a
-- cursor move, and the sub-key after it lands as a normal-mode command:
--   Cmd+L r  moves right, then replaces a character
--   Cmd+L a  moves right, then enters insert mode
--   Cmd+L D  moves right, then deletes to the end of the line
-- A keybinding that silently edits the buffer when it fails is not a
-- convenience. It was removed rather than papered over.
--
-- Getting Command through would mean a Ghostty keybind that hand-writes the
-- CSI u sequence for super+l. That is per-terminal configuration which does
-- not travel with this repository, to save one keystroke.
local actions = {
	r = { vim.lsp.buf.rename, "Rename symbol" },
	a = { vim.lsp.buf.code_action, "Code action" },
	d = { vim.lsp.buf.definition, "Go to definition" },
	D = { vim.lsp.buf.declaration, "Go to declaration" },
	i = { vim.lsp.buf.implementation, "Go to implementation" },
	t = { vim.lsp.buf.type_definition, "Go to type definition" },
	R = { vim.lsp.buf.references, "References" },
	o = { vim.lsp.buf.document_symbol, "Document symbols" },
	f = {
		function()
			vim.lsp.buf.format({ async = true })
		end,
		"Format buffer",
	},
	s = { vim.lsp.buf.signature_help, "Signature help" },
	h = {
		function()
			local on = not vim.lsp.inlay_hint.is_enabled({ bufnr = 0 })
			vim.lsp.inlay_hint.enable(on, { bufnr = 0 })
			vim.notify("inlay hints " .. (on and "on" or "off"))
		end,
		"Toggle inlay hints",
	},
}

for sub, action in pairs(actions) do
	local fn, desc = action[1], action[2]
	vim.keymap.set("n", "<leader>l" .. sub, fn, { silent = true, desc = desc })
end

-- gd is left to Neovim's own local-declaration jump on purpose. <C-]> already
-- reaches the LSP definition through tagfunc, and <leader>ld is the explicit
-- form.

-- Attach LSP completion per buffer rather than globally, so a buffer with no
-- server does not advertise completion it cannot serve.
--
-- autotrigger is what makes the menu appear as you type instead of only after
-- a trigger character such as "." or "->".
vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("user_lsp_attach", { clear = true }),
	callback = function(args)
		local client = vim.lsp.get_client_by_id(args.data.client_id)
		if client and client:supports_method("textDocument/completion") then
			vim.lsp.completion.enable(true, client.id, args.buf, { autotrigger = true })
		end
	end,
})

vim.lsp.enable({ "clangd", "lua_ls", "pyright", "ruff", "ltex_plus" })
