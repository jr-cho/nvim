-- What each key prefix is called.
--
-- This lives in its own module because which-key consumes the spec table it is
-- given: after setup, the table passed as `spec` is empty, and it is the same
-- table lazy holds as the plugin's opts. Reading the labels back from either
-- one finds nothing, so neither is a place a test can check.
--
-- which-key finds the keys under a prefix on its own. Only the name of the
-- prefix has to be declared, because that is not inferable from the keys.
return {
	{ "<leader>c", group = "compile (tex)" },
	{ "<leader>d", group = "diagnostics / debug" },
	{ "<leader>f", group = "find" },
	{ "<leader>g", group = "git" },
	{ "<leader>l", group = "lsp" },
	{ "<leader>n", group = "notes" },
	{ "<leader>t", group = "terminal" },
	{ "<leader>T", group = "test" },
	{ "<leader>u", group = "ui toggles" },
	{ "gs", group = "surround" },
	{ "g", group = "goto" },
	{ "[", group = "previous" },
	{ "]", group = "next" },
}
