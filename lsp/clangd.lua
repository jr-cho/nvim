-- clangd: C / C++ (also formats, using project's .clang-format)
-- needs compile_commands.json (or compile_flags.txt) in project root for correct flags
return {
  cmd = { "clangd", "--background-index", "--clang-tidy", "--header-insertion=never" },
  filetypes = { "c", "cpp" },
  root_markers = { ".clangd", "compile_commands.json", "compile_flags.txt", ".git" },
}
