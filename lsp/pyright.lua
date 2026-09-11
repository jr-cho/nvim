-- pyright, not basedpyright. basedpyright bundles its own Node runtime and a
-- venv and weighs 281MB against 20MB, for a type checker used on ordinary
-- scripts. Note the settings key differs between the two: pyright reads
-- python.analysis, basedpyright reads basedpyright.analysis.
return {
	cmd = { "pyright-langserver", "--stdio" },
	filetypes = { "python" },
	root_markers = { "pyproject.toml", "setup.py", "requirements.txt", ".git" },
	settings = {
		python = {
			analysis = {
				-- "standard", not "strict". strict reports every untyped
				-- function, which buries real errors in ordinary scripts.
				typeCheckingMode = "standard",
				autoImportCompletions = true,
			},
		},
	},
}
