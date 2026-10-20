-- ty: Python type checker + language server (Astral)
return {
  cmd = { "ty", "server" },
  filetypes = { "python" },
  root_markers = { "ty.toml", "pyproject.toml", "setup.py", "requirements.txt", ".git" },
}
