-- clangd.
--
-- clangd is only as good as compile_commands.json. Without one it guesses
-- include paths and every third header resolves to nothing, which reads as a
-- broken language server rather than a missing build database. For CMake,
-- configure with -DCMAKE_EXPORT_COMPILE_COMMANDS=ON. For plain make, run the
-- build once under `bear`.
return {
	cmd = {
		"clangd",
		"--background-index",
		"--clang-tidy",
		"--header-insertion=iwyu",
		"--completion-style=detailed",
		"--function-arg-placeholders=1",
	},
	filetypes = { "c", "cpp", "objc", "objcpp" },
	root_markers = {
		"compile_commands.json",
		"compile_flags.txt",
		"CMakeLists.txt",
		".clangd",
		".git",
	},
}
