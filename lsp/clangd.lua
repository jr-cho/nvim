-- clangd overrides (cmd/filetypes/root_markers come from nvim-lspconfig).
-- Needs compile_commands.json (or compile_flags.txt) in the project root.
return {
  cmd = {
    "clangd",
    "--background-index",
    "--clang-tidy",
    "--header-insertion=never",
    "--completion-style=detailed",
    "--function-arg-placeholders",
    "--fallback-style=llvm",
  },
}
