-- What each key prefix is called.
--
-- This lives in its own module because which-key consumes the spec table it is
-- given: after setup, the table passed as `spec` is empty. Reading the labels
-- back from it finds nothing, so the cheatsheet reads them from here instead.
--
-- which-key finds the keys under a prefix on its own. Only the name of the
-- prefix has to be declared, because that is not inferable from the keys.
return {
	{ "<leader>b", group = "buffer" },
	{ "<leader>f", group = "find" },
	{ "<leader>q", group = "quit / session" },
	{ "<leader>t", group = "terminal" },
	{ "<C-t>", group = "tab" },
	{ "s", group = "surround / flash" },
	{ "g", group = "goto" },
}
