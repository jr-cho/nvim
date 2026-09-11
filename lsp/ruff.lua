-- ruff runs as a second server on Python buffers, for lint codes and quick
-- fixes. Hover is turned off so pyright owns K alone; with both answering,
-- one press opens two stacked windows.
return {
	cmd = { "ruff", "server" },
	filetypes = { "python" },
	root_markers = { "pyproject.toml", "ruff.toml", ".ruff.toml", ".git" },
	on_attach = function(client)
		client.server_capabilities.hoverProvider = false
	end,
}
