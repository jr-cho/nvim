# Neovim Config Rebuild Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild the Neovim config on lazy + mini + snacks, with no framework, adding a debugger and a test runner that the previous config never had.

**Architecture:** One entry point that does three things and stops. Every capability is a file under `lua/plugins/` or `lua/` with one responsibility. Two plugin suites divide the work along a fixed line: mini owns editing and appearance, snacks owns workflow. Every layer ships with a headless test that asserts the layer's behaviour, not just that Neovim opened.

**Tech Stack:** Neovim 0.12.4, lazy.nvim, mini.nvim, snacks.nvim, LuaSnip, vimtex, conform.nvim, nvim-treesitter, nvim-dap, neotest.

**Spec:** https://claude.ai/code/artifact/d5269798-5ea2-42ac-8f69-b01d7255a4e7 (IDE capability research), https://claude.ai/code/artifact/305cd484-2398-496a-93e1-04b58b1ba622 (what the old framework supplied)

## Global Constraints

- Neovim floor is **0.12.4**. Native APIs used here (`vim.o.autocomplete`, `vim.lsp.config`, `vim.lsp.enable`) do not exist earlier.
- **Never add a plugin for something already native.** Verified native and therefore forbidden as plugin choices: rename/references/code-action keymaps (`grn` `gra` `grr` `gri` `grt` `gO`), signature help (`<C-s>` insert), completion engine (`vim.o.autocomplete`), inlay hints, LSP folding, snippet jumping (`<Tab>`/`<S-Tab>`).
- **Suite ownership is fixed.** mini: editing and appearance. snacks: workflow (picker, explorer, terminal, image, input, notifier). Nine capabilities exist in both suites; never enable both sides of one.
- **Leader is `<Space>`. Localleader is `\`.** Already set in `init.lua`.
- **LSP keymaps use one prefix: `<leader>l`.** `<D-l>` was tried and removed. Ghostty does not forward Command to the application, so `Cmd+L` arrives as a bare `l` and the sub-key lands as a normal-mode command: `Cmd+L r` replaces a character, `Cmd+L D` deletes to end of line. Never reintroduce it without first verifying Super actually reaches Neovim.
- Indentation in Lua files is **hard tabs**. Do not add a `.stylua.toml` that disagrees with the files, as the old config did.
- Every task ends with `tests/run.sh` exiting 0.
- `lazy-lock.json` stays untracked.

## Why This Order

Each layer is placed by what depends on it, not by how interesting it is.

1. **Editor behaviour** has zero dependencies and everything else inherits it. Wrong `expandtab` or `undofile` poisons every later layer.
2. **Treesitter** is a hard dependency of the LaTeX math detector (Task 9), `mini.ai` textobjects (Task 6), and markdown rendering. It also gives the first big visible change.
3. **LSP** depends on nothing but needs its servers on `PATH`, so the reinstall lives here.
4. **Completion** consumes LSP; meaningless before it.
5. **Workflow** (picker, explorer) is the first layer that makes the config usable for real work.
6. **Editing verbs** are independent but benefit from treesitter, so they come after it.
7. **Formatting** needs its binaries, and is easiest to verify once real files are open.
8. **Git** is independent and small.
9. **LaTeX and markdown** is the largest port and depends on treesitter plus LuaSnip.
10. **Debugger** is the first genuinely new capability, not a port.
11. **Test runner** is last because it is the least load-bearing of the three gaps.

## File Structure

| File | Responsibility |
| --- | --- |
| `init.lua` | Leader keys, bootstrap, hand off to lazy. Done. |
| `lua/options.lua` | Editor options only |
| `lua/autocmds.lua` | Autocommands only |
| `lua/keymaps.lua` | Keymaps that belong to no plugin |
| `lua/lsp.lua` | Diagnostics, LSP keymap table, inlay-hint toggle |
| `lsp/<server>.lua` | One file per language server, read by `vim.lsp.config` |
| `lua/util/tex.lua` | Cursor-in-math and cursor-in-code tests |
| `lua/plugins/*.lua` | One lazy spec file per capability |
| `after/ftplugin/*.lua` | Per-filetype buffer settings |
| `snippets/tex.lua` | LuaSnip snippets, shared by tex and markdown |
| `tests/*.lua` | One test file per layer |

---

### Task 1: Editor behaviour

No plugins. Options, autocommands and the keymaps that belong to no plugin.

**Files:**
- Create: `lua/options.lua`
- Create: `lua/autocmds.lua`
- Create: `lua/keymaps.lua`
- Modify: `init.lua` (add three `require` calls)
- Test: `tests/editor.lua`
- Modify: `tests/run.sh`

**Interfaces:**
- Consumes: `vim.g.mapleader`, `vim.g.maplocalleader` from `init.lua`.
- Produces: nothing other modules call. Later tasks assume `expandtab = false`, `undofile = true`, and that `<leader>` groups `d`, `u` and `t` are free.

- [x] **Step 1: Write the failing test**

Create `tests/editor.lua`:

```lua
local t = require("testkit")

t.run(function()
	-- Indentation. Hard tabs everywhere; LaTeX and markdown override this in
	-- their own ftplugin because both formats care.
	t.check("expandtab off", vim.o.expandtab, false)
	t.check("shiftwidth", vim.o.shiftwidth, 2)
	t.check("tabstop", vim.o.tabstop, 2)

	-- Undo survives a restart. Nothing else is written beside the file.
	t.check("undofile on", vim.o.undofile, true)
	t.check("swapfile off", vim.o.swapfile, false)
	t.check("backup off", vim.o.backup, false)

	-- Search. No highlight left over after the search finishes.
	t.check("ignorecase", vim.o.ignorecase, true)
	t.check("smartcase", vim.o.smartcase, true)
	t.check("hlsearch off", vim.o.hlsearch, false)

	-- Display.
	t.check("number", vim.o.number, true)
	t.check("relativenumber", vim.o.relativenumber, true)
	t.check("wrap on", vim.o.wrap, true)
	t.check("linebreak on", vim.o.linebreak, true)
	t.check("scrolloff", vim.o.scrolloff, 8)
	t.check("winborder", vim.o.winborder, "rounded")
	t.check("signcolumn", vim.o.signcolumn, "yes")

	-- mason is gone with the old config, so nothing injects its bin directory
	-- into PATH any more. Servers must come from the system.
	t.truthy("splitright", vim.o.splitright)
	t.truthy("splitbelow", vim.o.splitbelow)

	-- Autocommands.
	local function has(event, group)
		return #vim.api.nvim_get_autocmds({ event = event, group = group }) > 0
	end
	t.truthy("yank highlight", has("TextYankPost", "user_yank"))
	t.truthy("last position", has("BufReadPost", "user_lastpos"))
	t.truthy("mkdir on save", has("BufWritePre", "user_mkdir"))

	-- Keymaps that belong to no plugin.
	for _, k in ipairs({ "<leader>d", "]d", "[d", "<C-d>", "<C-u>", "n", "N" }) do
		t.truthy(k .. " is mapped", vim.fn.maparg(k, "n") ~= "" or vim.fn.maparg(k, "n", false, true).callback ~= nil)
	end

	-- j and k move by display line only when no count is given, so 5j still
	-- moves five real lines and macros behave as they did.
	t.truthy("j is an expr map", vim.fn.maparg("j", "n", false, true).expr == 1)
	t.truthy("k is an expr map", vim.fn.maparg("k", "n", false, true).expr == 1)
end)
```

- [x] **Step 2: Run test to verify it fails**

Run: `cd ~/.config/nvim && tests/nvim-test tests/editor.lua`
Expected: FAIL. `expandtab off` reports `got true, want false`, because Neovim's default is on and nothing has changed it.

- [x] **Step 3: Write the implementation**

Create `lua/options.lua`:

```lua
-- Editor options. No plugin reads this file and this file reads no plugin.
local o = vim.o

-- Indentation. Hard tabs. after/ftplugin overrides this for LaTeX and
-- markdown, where the format itself cares: four spaces of indent in markdown
-- is a code block, and a tab is not reliably four columns to every renderer.
o.expandtab = false
o.tabstop = 2
o.softtabstop = 2
o.shiftwidth = 2
o.smartindent = true

-- History. Undo survives a restart. Nothing else is written beside the file.
o.undofile = true
o.swapfile = false
o.backup = false

-- Search.
o.ignorecase = true
o.smartcase = true
o.incsearch = true
o.hlsearch = false

-- Display.
o.number = true
o.relativenumber = true
o.signcolumn = "yes"
o.cursorline = true
o.cursorlineopt = "both"
o.scrolloff = 8
o.sidescrolloff = 8
o.winborder = "rounded"
o.laststatus = 3
o.showmode = false
o.splitright = true
o.splitbelow = true
o.splitkeep = "screen"
o.timeoutlen = 400
o.updatetime = 250
o.confirm = true

-- Soft wrap. Display only. No newline reaches the file.
o.wrap = true
o.linebreak = true
o.breakindent = true
o.showbreak = "↪ "

-- Show the whitespace that hides bugs.
o.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- Per-project config. exrc trusts a .nvim.lua only after you confirm its hash.
o.exrc = true

-- Completion menu. "popup" shows documentation beside the menu.
o.completeopt = "menu,menuone,popup,noselect"
o.pumheight = 12

-- Disable providers this config does not use, so :checkhealth stays readable.
vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0

-- System clipboard over OSC52, which works through SSH and needs no external
-- binary. Scheduled so the provider probe stays out of startup.
vim.schedule(function()
	vim.g.clipboard = "osc52"
	o.clipboard = "unnamedplus"
end)
```

Create `lua/autocmds.lua`:

```lua
-- Autocommands. Each one gets its own named group so it can be found and
-- cleared, and so a test can assert it exists.
local function group(name)
	return vim.api.nvim_create_augroup(name, { clear = true })
end

-- Flash what was just yanked. The only feedback that a yank happened.
vim.api.nvim_create_autocmd("TextYankPost", {
	group = group("user_yank"),
	callback = function()
		vim.hl.on_yank({ timeout = 150 })
	end,
})

-- Reopen a file on the line you left it. Skips the case where the mark points
-- past the end of the file, which happens after the file shrank.
vim.api.nvim_create_autocmd("BufReadPost", {
	group = group("user_lastpos"),
	callback = function(args)
		local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
		if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(args.buf) then
			pcall(vim.api.nvim_win_set_cursor, 0, mark)
		end
	end,
})

-- Create the parent directory when saving to a path that does not exist yet.
-- Without this, :w on notes/week3/limits.md fails and you lose the buffer's
-- contents to a retry.
vim.api.nvim_create_autocmd("BufWritePre", {
	group = group("user_mkdir"),
	callback = function(args)
		if args.match:match("^%w%w+://") then
			return
		end
		vim.fn.mkdir(vim.fn.fnamemodify(args.match, ":p:h"), "p")
	end,
})

-- Close scratch windows with q. These are windows you read and dismiss, and
-- reaching for :q on them is friction with no purpose.
vim.api.nvim_create_autocmd("FileType", {
	group = group("user_quickclose"),
	pattern = { "help", "qf", "man", "checkhealth", "lspinfo" },
	callback = function(args)
		vim.bo[args.buf].buflisted = false
		vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = args.buf, silent = true })
	end,
})
```

Create `lua/keymaps.lua`:

```lua
-- Keymaps that belong to no plugin. Anything a plugin owns is declared in that
-- plugin's spec instead, so the spec is the whole story for that plugin.
local function map(mode, lhs, rhs, desc, opts)
	opts = vim.tbl_extend("force", { silent = true, desc = desc }, opts or {})
	vim.keymap.set(mode, lhs, rhs, opts)
end

-- Move by display line when no count is given. 5j still moves five real lines,
-- so counts and macros behave as they did before soft wrap was turned on.
map("n", "j", "v:count == 0 ? 'gj' : 'j'", "Down", { expr = true })
map("n", "k", "v:count == 0 ? 'gk' : 'k'", "Up", { expr = true })

-- Keep the cursor centred through half-page jumps and search hits.
map("n", "<C-d>", "<C-d>zz", "Half page down")
map("n", "<C-u>", "<C-u>zz", "Half page up")
map("n", "n", "nzzzv", "Next match")
map("n", "N", "Nzzzv", "Previous match")

-- Move the selected lines and reindent them.
map("v", "J", ":m '>+1<CR>gv=gv", "Move selection down")
map("v", "K", ":m '<-2<CR>gv=gv", "Move selection up")

-- Stay in visual mode after shifting, so > > > is three presses of one key.
map("v", "<", "<gv", "Unindent selection")
map("v", ">", ">gv", "Indent selection")

-- Paste over a selection without losing the register.
map("x", "<leader>p", [["_dP]], "Paste without yanking selection")

-- Window navigation, including out of a terminal buffer. <C-\><C-n> leaves
-- terminal mode first, otherwise the keys are typed into the shell.
for _, dir in ipairs({ "h", "j", "k", "l" }) do
	map("n", "<C-" .. dir .. ">", "<cmd>wincmd " .. dir .. "<CR>", "Window " .. dir)
	map("t", "<C-" .. dir .. ">", "<C-\\><C-n><cmd>wincmd " .. dir .. "<CR>", "Window " .. dir)
end
map("t", "<C-d>", "<C-\\><C-n>", "Leave terminal mode")

-- Window size, without a mouse.
map("n", "<C-Up>", "<cmd>resize +2<CR>", "Taller window")
map("n", "<C-Down>", "<cmd>resize -2<CR>", "Shorter window")
map("n", "<C-Left>", "<cmd>vertical resize -2<CR>", "Narrower window")
map("n", "<C-Right>", "<cmd>vertical resize +2<CR>", "Wider window")

-- Buffers.
map("n", "<S-h>", "<cmd>bprevious<CR>", "Previous buffer")
map("n", "<S-l>", "<cmd>bnext<CR>", "Next buffer")

-- Diagnostics. These are not LSP-specific: vim.diagnostic covers any source.
map("n", "<leader>d", vim.diagnostic.open_float, "Diagnostic float")
map("n", "]d", function()
	vim.diagnostic.jump({ count = 1, float = true })
end, "Next diagnostic")
map("n", "[d", function()
	vim.diagnostic.jump({ count = -1, float = true })
end, "Previous diagnostic")

-- Clear search highlight and any floating window left over.
map("n", "<Esc>", "<cmd>nohlsearch<CR>", "Clear search highlight")
```

Modify `init.lua`. Add these three lines immediately after the `require("lazy").setup({...})` call:

```lua
require("options")
require("autocmds")
require("keymaps")
```

- [x] **Step 4: Run test to verify it passes**

Run: `cd ~/.config/nvim && tests/nvim-test tests/editor.lua`
Expected: PASS, every check `ok`.

- [x] **Step 5: Add to the runner and run the full suite**

Modify `tests/run.sh`, changing the `for` line to:

```bash
for test in tests/boot.lua tests/editor.lua tests/mini.lua; do
```

Run: `cd ~/.config/nvim && tests/run.sh; echo "exit=$?"`
Expected: three `PASS` lines, `exit=0`.

- [x] **Step 6: Commit**

```bash
cd ~/.config/nvim
git add lua/options.lua lua/autocmds.lua lua/keymaps.lua init.lua tests/editor.lua tests/run.sh
git commit -m "feat: editor behaviour, no plugins

Options, autocommands and the keymaps that belong to no plugin. Everything
later inherits these, so they land before anything can depend on them."
```

---

### Task 2: Treesitter

**Files:**
- Create: `lua/plugins/treesitter.lua`
- Test: `tests/treesitter.lua`
- Modify: `tests/run.sh`

**Interfaces:**
- Consumes: nothing.
- Produces: installed parsers named `c`, `cpp`, `python`, `lua`, `bash`, `json`, `markdown`, `markdown_inline`, `latex`, `vim`, `vimdoc`, `query`, `diff`, `gitcommit`. Task 9's `lua/util/tex.lua` requires `latex`, `markdown` and `markdown_inline` and silently stops working without them.

- [x] **Step 1: Write the failing test**

Create `tests/treesitter.lua`:

```lua
local t = require("testkit")

t.run(function()
	-- latex, markdown and markdown_inline are not optional. util/tex.lua reads
	-- the parse tree to decide whether the cursor is inside maths, and every
	-- LaTeX snippet stops firing without them, silently.
	local required = {
		"c", "cpp", "python", "lua", "bash", "json",
		"markdown", "markdown_inline", "latex", "vim", "vimdoc",
	}
	for _, lang in ipairs(required) do
		t.truthy(lang .. " parser installed", vim.treesitter.language.add(lang))
	end

	-- Highlighting is on for a real buffer, not merely available.
	vim.cmd("edit /tmp/nvchad-ts-test.lua")
	vim.api.nvim_buf_set_lines(0, 0, -1, false, { "local x = 1" })
	vim.bo.filetype = "lua"
	vim.treesitter.start()
	t.truthy("highlighter is active for lua", vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()] ~= nil)

	-- markdown injects the latex parser into $...$, which is the mechanism the
	-- maths snippets rely on in Task 9.
	vim.cmd("edit /tmp/nvchad-ts-test.md")
	vim.api.nvim_buf_set_lines(0, 0, -1, false, { "Inline $x + y$ here." })
	vim.bo.filetype = "markdown"
	local parser = vim.treesitter.get_parser(0, nil, { error = false })
	t.truthy("markdown parser resolves", parser ~= nil)
	parser:parse(true)
	local node = vim.treesitter.get_node({ pos = { 0, 9 }, ignore_injections = false })
	local found = false
	while node do
		if node:type() == "inline_formula" then
			found = true
			break
		end
		node = node:parent()
	end
	t.truthy("latex is injected into markdown maths", found)

	vim.fn.delete("/tmp/nvchad-ts-test.lua")
	vim.fn.delete("/tmp/nvchad-ts-test.md")
end)
```

- [x] **Step 2: Run test to verify it fails**

Run: `cd ~/.config/nvim && tests/nvim-test tests/treesitter.lua`
Expected: FAIL. `c parser installed` reports a falsy value, because no parser is installed yet.

- [x] **Step 3: Write the implementation**

Create `lua/plugins/treesitter.lua`:

```lua
-- Treesitter parsers and highlighting.
--
-- Neovim ships the treesitter runtime itself; this plugin is the parser
-- installer and the query files. vim.treesitter.start() is what turns
-- highlighting on, and lua/autocmds.lua is not where that belongs, because the
-- parsers have to exist first.
return {
	"nvim-treesitter/nvim-treesitter",
	branch = "main",
	build = ":TSUpdate",
	lazy = false,

	config = function()
		local parsers = {
			"c",
			"cpp",
			"python",
			"lua",
			"bash",
			"json",
			"markdown",
			"markdown_inline",
			"latex",
			"vim",
			"vimdoc",
			"query",
			"diff",
			"gitcommit",
		}

		-- latex, markdown and markdown_inline are load-bearing, not cosmetic.
		-- lua/util/tex.lua answers "is the cursor inside maths" from the parse
		-- tree, and markdown_inline is what wraps $x$ in a latex_block with the
		-- latex parser injected into it. Remove any of the three and every
		-- maths snippet stops firing with no error.
		require("nvim-treesitter").install(parsers)

		-- Start highlighting for any buffer whose language has a parser. pcall
		-- because a filetype with no parser is normal, not an error.
		vim.api.nvim_create_autocmd("FileType", {
			group = vim.api.nvim_create_augroup("user_treesitter", { clear = true }),
			callback = function()
				pcall(vim.treesitter.start)
			end,
		})
	end,
}
```

- [x] **Step 4: Install the parsers, then run the test**

Run: `cd ~/.config/nvim && nvim --headless "+Lazy! sync" +qa` then wait for it to exit, then `nvim --headless -c 'lua require("nvim-treesitter").install({"c","cpp","python","lua","bash","json","markdown","markdown_inline","latex","vim","vimdoc","query","diff","gitcommit"}):wait(300000)' +qa`

Run: `cd ~/.config/nvim && tests/nvim-test tests/treesitter.lua`
Expected: PASS. If `latex is injected into markdown maths` fails, `markdown_inline` did not install; rerun the install command.

- [x] **Step 5: Add to the runner and run the full suite**

Modify `tests/run.sh`, changing the `for` line to:

```bash
for test in tests/boot.lua tests/editor.lua tests/treesitter.lua tests/mini.lua; do
```

Run: `cd ~/.config/nvim && tests/run.sh; echo "exit=$?"`
Expected: four `PASS` lines, `exit=0`.

- [x] **Step 6: Commit**

```bash
cd ~/.config/nvim
git add lua/plugins/treesitter.lua tests/treesitter.lua tests/run.sh
git commit -m "feat: treesitter parsers and highlighting

latex, markdown and markdown_inline are required rather than optional: the
maths detector in a later layer reads the parse tree, and markdown_inline is
what injects the latex parser into \$...\$."
```

---

### Task 3: LSP

Native `vim.lsp.config`. No `nvim-lspconfig`. Five hand-written server files.

**Files:**
- Create: `lsp/clangd.lua`, `lsp/lua_ls.lua`, `lsp/pyright.lua`, `lsp/ruff.lua`
- Create: `lua/lsp.lua`
- Modify: `init.lua` (add `require("lsp")`)
- Test: `tests/lsp.lua`
- Modify: `tests/run.sh`

**Interfaces:**
- Consumes: nothing from earlier tasks.
- Produces: `vim.lsp.enable` called for `clangd`, `lua_ls`, `pyright`, `ruff`. Task 4 attaches completion on `LspAttach` and needs those servers to actually start.

`ltex_plus` is deliberately absent from this task. It is a 200MB Java server for prose grammar, it was lost with the mason tree, and it belongs with the markdown layer in Task 9 where its value is visible.

- [x] **Step 1: Install the missing server**

`pyright` was removed along with the mason tree. `clangd`, `lua-language-server` and `ruff` are system installs and survived.

Run: `npm i -g pyright`
Verify: `command -v pyright-langserver` prints a path.

- [x] **Step 2: Write the failing test**

Create `tests/lsp.lua`:

```lua
local t = require("testkit")

t.run(function()
	-- Servers this config enables.
	for _, name in ipairs({ "clangd", "lua_ls", "pyright", "ruff" }) do
		t.check(name .. " enabled", vim.lsp.is_enabled(name), true)
		t.truthy(name .. " has a config", vim.lsp.config[name] ~= nil)
		t.truthy(name .. " names a command", vim.lsp.config[name].cmd ~= nil)
	end

	-- Every server's binary must resolve. A config for a server that is not
	-- installed fails at attach time with a message that reads like a broken
	-- language server rather than a missing program.
	local bins = {
		clangd = "clangd",
		lua_ls = "lua-language-server",
		pyright = "pyright-langserver",
		ruff = "ruff",
	}
	for name, bin in pairs(bins) do
		t.check(name .. " binary on PATH", vim.fn.executable(bin), 1)
	end

	-- ruff must not answer hover, so pyright owns K alone and the two servers
	-- do not stack two windows on one keypress.
	t.check("ruff hover disabled", vim.lsp.config.ruff.on_attach ~= nil, true)

	-- Diagnostics.
	local cfg = vim.diagnostic.config()
	t.check("virtual text off", cfg.virtual_text, false)
	t.truthy("virtual lines on current line", cfg.virtual_lines ~= nil and cfg.virtual_lines ~= false)
	t.truthy("severity sorted", cfg.severity_sort)

	-- The LSP keymap table, bound twice from one source. <D-l> is faster and
	-- Ghostty-only; <leader>l is the mirror that survives SSH.
	local subs = { "r", "a", "d", "D", "i", "t", "R", "o", "f", "s", "h" }
	for _, sub in ipairs(subs) do
		local super = vim.fn.maparg("<D-l>" .. sub, "n", false, true)
		local leader = vim.fn.maparg("<leader>l" .. sub, "n", false, true)
		t.truthy("<D-l>" .. sub .. " is mapped", super.callback ~= nil or super.rhs ~= nil)
		t.truthy("<leader>l" .. sub .. " is mapped", leader.callback ~= nil or leader.rhs ~= nil)
	end

	-- No digits under <D-l>. Ghostty binds super+1 to super+9 to tab switching
	-- and would eat them before Neovim saw them.
	for i = 0, 9 do
		local m = vim.fn.maparg("<D-l>" .. i, "n", false, true)
		t.check("<D-l>" .. i .. " is not mapped", m.callback == nil and m.rhs == nil, true)
	end
end)
```

- [x] **Step 3: Run test to verify it fails**

Run: `cd ~/.config/nvim && tests/nvim-test tests/lsp.lua`
Expected: FAIL. `clangd enabled` reports `got false, want true`.

- [x] **Step 4: Write the server files**

Create `lsp/clangd.lua`:

```lua
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
```

Create `lsp/lua_ls.lua`:

```lua
-- lua-language-server.
return {
	cmd = { "lua-language-server" },
	filetypes = { "lua" },
	root_markers = { ".luarc.json", ".luarc.jsonc", ".stylua.toml", ".git" },
	settings = {
		Lua = {
			runtime = { version = "LuaJIT" },
			workspace = {
				checkThirdParty = false,
				library = {
					vim.env.VIMRUNTIME .. "/lua",
					"${3rd}/luv/library",
				},
			},
			diagnostics = { globals = { "vim", "Snacks", "MiniIcons" } },
			telemetry = { enable = false },
			-- stylua does this, through conform in Task 7.
			format = { enable = false },
		},
	},
}
```

Create `lsp/pyright.lua`:

```lua
-- pyright, not basedpyright. basedpyright bundles its own Node runtime and a
-- venv and weighs 281MB against 34MB, for a type checker used on ordinary
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
```

Create `lsp/ruff.lua`:

```lua
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
```

- [x] **Step 5: Write `lua/lsp.lua`**

Create `lua/lsp.lua`:

```lua
-- LSP: diagnostics, the keymaps Neovim does not already provide, and the
-- servers to enable.
--
-- Neovim 0.12 binds a lot of this itself and none of it is repeated here:
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

-- One table, bound under two prefixes.
--
-- <D-l> is Command+l. Neovim encodes it with a real modifier bit, Ghostty
-- speaks the Kitty keyboard protocol and does not bind super+l itself, so it
-- reaches us. It is also the faster of the two: a chord plus a key rather than
-- three sequential presses.
--
-- <leader>l mirrors it because <D-l> exists only in Ghostty and GUI Neovim.
-- Over SSH, or in Terminal.app, the Command half is silently dead, and a
-- config whose LSP keys vanish with no error is worse than one that is a
-- keystroke slower.
--
-- No digits. Ghostty binds super+1 through super+9 to tab switching.
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
	vim.keymap.set("n", "<D-l>" .. sub, fn, { silent = true, desc = desc })
	vim.keymap.set("n", "<leader>l" .. sub, fn, { silent = true, desc = desc })
end

-- gd is left to Neovim's own local-declaration jump on purpose. <C-]> already
-- goes to the LSP definition through tagfunc, and <D-l>d is the explicit form.

vim.lsp.enable({ "clangd", "lua_ls", "pyright", "ruff" })
```

Modify `init.lua`, adding after the other requires:

```lua
require("lsp")
```

- [x] **Step 6: Run test to verify it passes**

Run: `cd ~/.config/nvim && tests/nvim-test tests/lsp.lua`
Expected: PASS. If `pyright binary on PATH` fails, Step 1 did not complete.

- [x] **Step 7: Verify a server actually attaches**

This is the check the unit test cannot make, because attaching needs a real file in a real project.

```bash
mkdir -p /tmp/lsp-check && cd /tmp/lsp-check && git init -q .
printf 'int main(void) { int x = "wrong"; return 0; }\n' > main.c
nvim main.c
```

Inside Neovim: wait two seconds, then `:checkhealth vim.lsp`. Expected: clangd listed as attached. Press `]d` and expect to land on the type error. Press `<D-l>a` and expect a code-action menu. Then `:q!` and `rm -rf /tmp/lsp-check`.

- [x] **Step 8: Add to the runner and run the full suite**

Modify `tests/run.sh`, changing the `for` line to:

```bash
for test in tests/boot.lua tests/editor.lua tests/treesitter.lua tests/lsp.lua tests/mini.lua; do
```

Run: `cd ~/.config/nvim && tests/run.sh; echo "exit=$?"`
Expected: five `PASS` lines, `exit=0`.

- [x] **Step 9: Commit**

```bash
cd ~/.config/nvim
git add lsp lua/lsp.lua init.lua tests/lsp.lua tests/run.sh
git commit -m "feat: native LSP, four servers, no lspconfig

vim.lsp.config reads lsp/<name>.lua off the runtimepath, so nvim-lspconfig is
a data package this config does not need. Roughly 60 lines of the old
lspconfig.lua re-created keymaps Neovim now binds itself.

LSP keys are bound twice from one table: <D-l> is faster and Ghostty-only,
<leader>l survives SSH."
```

---

### Task 4: Completion

Native. No nvim-cmp, no blink.

**Files:**
- Modify: `lua/lsp.lua` (add an `LspAttach` autocommand)
- Test: `tests/completion.lua`
- Modify: `tests/run.sh`

**Interfaces:**
- Consumes: the servers enabled in Task 3.
- Produces: nothing later tasks call.

- [x] **Step 1: Write the failing test**

Create `tests/completion.lua`:

```lua
local t = require("testkit")

t.run(function()
	-- 'autocomplete' is new in 0.12 and is the whole completion engine. It is
	-- off by default.
	t.check("autocomplete on", vim.o.autocomplete, true)

	-- "popup" is what puts documentation beside the menu rather than in a
	-- separate preview window.
	t.truthy("completeopt has popup", vim.o.completeopt:match("popup") ~= nil)
	t.truthy("completeopt has menuone", vim.o.completeopt:match("menuone") ~= nil)
	t.truthy("completeopt has noselect", vim.o.completeopt:match("noselect") ~= nil)

	-- The menu must not fill the screen on a long completion list.
	t.check("pumheight bounded", vim.o.pumheight, 12)

	-- vim.lsp.completion is attached on LspAttach rather than globally, so a
	-- buffer with no server does not advertise LSP completion.
	local found = false
	for _, au in ipairs(vim.api.nvim_get_autocmds({ event = "LspAttach" })) do
		if au.group_name == "user_lsp_attach" then
			found = true
		end
	end
	t.truthy("completion attaches on LspAttach", found)

	-- Snippet jumping is native and already bound. Adding a plugin for it
	-- would be re-implementing core.
	t.truthy("Tab jumps snippets", vim.fn.maparg("<Tab>", "i") ~= "")
	t.truthy("S-Tab jumps snippets", vim.fn.maparg("<S-Tab>", "i") ~= "")
end)
```

- [x] **Step 2: Run test to verify it fails**

Run: `cd ~/.config/nvim && tests/nvim-test tests/completion.lua`
Expected: FAIL. `autocomplete on` reports `got false, want true`.

- [x] **Step 3: Write the implementation**

Modify `lua/options.lua`, adding beside the other completion options:

```lua
-- Native autocompletion, new in 0.12 and off by default. This is the whole
-- engine: no nvim-cmp, no blink.cmp, no sources to wire up. Add blink later
-- only if the native menu proves annoying; it is one spec and changes nothing
-- else in this config.
o.autocomplete = true
```

Modify `lua/lsp.lua`, adding before the `vim.lsp.enable` call:

```lua
-- Attach LSP completion per buffer rather than globally, so a buffer with no
-- server does not advertise completion it cannot serve.
vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("user_lsp_attach", { clear = true }),
	callback = function(args)
		local client = vim.lsp.get_client_by_id(args.data.client_id)
		if client and client:supports_method("textDocument/completion") then
			vim.lsp.completion.enable(true, client.id, args.buf, { autotrigger = true })
		end
	end,
})
```

- [x] **Step 4: Run test to verify it passes**

Run: `cd ~/.config/nvim && tests/nvim-test tests/completion.lua`
Expected: PASS.

- [x] **Step 5: Verify completion actually fires**

```bash
mkdir -p /tmp/cmp-check && cd /tmp/cmp-check && git init -q .
printf '#include <stdio.h>\nint main(void) {\n  \n}\n' > main.c
nvim +3 main.c
```

Inside Neovim: press `i`, type `pri`. Expected: a completion menu appears with `printf` and a documentation popup beside it, without pressing `<C-x><C-o>`. Then `:q!` and `rm -rf /tmp/cmp-check`.

- [x] **Step 6: Add to the runner, run the suite, commit**

Modify `tests/run.sh` `for` line to include `tests/completion.lua` after `tests/lsp.lua`.

```bash
cd ~/.config/nvim && tests/run.sh; echo "exit=$?"
git add lua/options.lua lua/lsp.lua tests/completion.lua tests/run.sh
git commit -m "feat: native completion

vim.o.autocomplete is new in 0.12 and is the whole engine. Attached per
buffer on LspAttach so a buffer with no server does not advertise completion."
```

---

### Task 5: Workflow — snacks and project-wide replace

Picker, explorer, terminal, input, notifier, bigfile, lazygit, and find-and-replace across the project.

**Files:**
- Create: `lua/plugins/snacks.lua`
- Create: `lua/plugins/replace.lua`
- Test: `tests/snacks.lua`
- Modify: `tests/run.sh`

**Interfaces:**
- Consumes: `MiniIcons.mock_nvim_web_devicons()` from `lua/plugins/mini.lua`, which is how snacks gets icons without a second icon set.
- Produces: `Snacks` global. Task 9 uses `Snacks.image`.

- [x] **Step 1: Write the failing test**

Create `tests/snacks.lua`:

```lua
local t = require("testkit")

t.run(function()
	t.truthy("Snacks global exists", _G.Snacks ~= nil)

	-- Modules this config turns on.
	for _, m in ipairs({ "picker", "explorer", "terminal", "input", "notifier", "bigfile" }) do
		t.truthy("snacks." .. m .. " available", Snacks[m] ~= nil)
	end

	-- Terminals must be reached with focus(), not toggle(). toggle() asks only
	-- whether the buffer sits in a window, so clicking off a floating terminal
	-- and pressing the key again closes the terminal instead of returning to
	-- it. That was the bug in the previous config.
	t.truthy("Snacks.terminal.focus exists", type(Snacks.terminal.focus) == "function")

	local tt = vim.fn.maparg("<leader>tt", "n", false, true)
	t.truthy("<leader>tt is mapped", tt.callback ~= nil)

	-- Three positions must be three terminals. Snacks keys a terminal by cmd,
	-- cwd, env and count, and position is not part of that key, so without a
	-- distinct count all three keys share one terminal and only move it.
	local code = vim.api.nvim_get_current_win()
	local seen = {}
	for _, key in ipairs({ "<leader>tt", "<leader>tv", "<leader>th" }) do
		vim.fn.maparg(key, "n", false, true).callback()
		seen[#seen + 1] = vim.api.nvim_get_current_buf()
		vim.api.nvim_set_current_win(code)
	end
	t.truthy("float and vertical differ", seen[1] ~= seen[2])
	t.truthy("vertical and horizontal differ", seen[2] ~= seen[3])
	t.truthy("float and horizontal differ", seen[1] ~= seen[3])

	-- Picker and explorer keys.
	for _, key in ipairs({ "<leader>ff", "<leader>fg", "<leader>fb", "<leader>e" }) do
		local m = vim.fn.maparg(key, "n", false, true)
		t.truthy(key .. " is mapped", m.callback ~= nil or m.rhs ~= nil)
	end

	-- One notifier and one indent guide, not two. mini.notify and
	-- mini.indentscope must stay off while snacks owns these.
	t.check("mini.notify is off", _G.MiniNotify, nil)
	t.check("mini.indentscope is off", _G.MiniIndentscope, nil)

	-- Project-wide find and replace. The picker greps but cannot rewrite, and
	-- rewriting across a tree by hand through :cdo is the kind of thing an IDE
	-- is for.
	for _, key in ipairs({ "<leader>fs", "<leader>fS" }) do
		local m = vim.fn.maparg(key, "n", false, true)
		t.truthy(key .. " is mapped", m.callback ~= nil or m.rhs ~= nil)
	end
end)
```

- [x] **Step 2: Run test to verify it fails**

Run: `cd ~/.config/nvim && tests/nvim-test tests/snacks.lua`
Expected: FAIL. `Snacks global exists` reports a falsy value.

- [x] **Step 3: Write the implementation**

Create `lua/plugins/snacks.lua`:

```lua
-- snacks.nvim: the workflow layer.
--
-- The division with mini.nvim is fixed and should stay that way. Nine
-- capabilities exist in both suites, and choosing per module rather than per
-- suite is how a config ends up with two notifiers and two indent guides
-- fighting each other.
--   snacks owns: picker, explorer, terminal, image, input, notifier, bigfile.
--   mini owns:   editing verbs, statusline, tabline, icons, colours, diff.
return {
	"folke/snacks.nvim",
	priority = 1000,
	lazy = false,

	opts = {
		-- Listing a module with enabled = true is what turns it on. Everything
		-- not named here stays off, so this table is the full list of what
		-- snacks is doing.
		bigfile = { enabled = true },
		quickfile = { enabled = true },
		input = { enabled = true },
		notifier = { enabled = true, timeout = 3000 },
		indent = { enabled = true },
		picker = { enabled = true },
		explorer = { enabled = true },

		terminal = {
			win = {
				-- Matches winborder in options.lua and the rest of the config.
				border = "rounded",
			},
		},
	},

	keys = function()
		-- Each position carries its own count. Snacks keys a terminal by cmd,
		-- cwd, env and count; the window position is not part of that key, so
		-- without a count these three keys reach for one terminal and only
		-- move it around the screen.
		--
		-- cwd is left to snacks, which reads the window's working directory.
		-- Terminals are therefore per project: :lcd into another repository and
		-- these open that repository's terminal.
		local terms = {
			float = { count = 1, win = { position = "float", width = 0.88, height = 0.85 } },
			vertical = { count = 2, win = { position = "right", width = 0.4 } },
			horizontal = { count = 3, win = { position = "bottom", height = 0.35 } },
		}

		-- focus, never toggle. Snacks.terminal.toggle asks only whether the
		-- buffer sits in a window, so a visible-but-unfocused terminal gets
		-- closed rather than focused. focus answers all three states: open it,
		-- focus it, hide it.
		local function term(name)
			return function()
				Snacks.terminal.focus(nil, terms[name])
			end
		end

		return {
			-- Find
			{ "<leader>ff", function() Snacks.picker.files() end, desc = "Find files" },
			{ "<leader>fg", function() Snacks.picker.grep() end, desc = "Grep project" },
			{ "<leader>fb", function() Snacks.picker.buffers() end, desc = "Buffers" },
			{ "<leader>fh", function() Snacks.picker.help() end, desc = "Help pages" },
			{ "<leader>fk", function() Snacks.picker.keymaps() end, desc = "Keymaps" },
			{ "<leader>fd", function() Snacks.picker.diagnostics() end, desc = "Diagnostics" },
			{ "<leader>fr", function() Snacks.picker.recent() end, desc = "Recent files" },

			-- Explorer
			{ "<leader>e", function() Snacks.explorer() end, desc = "File explorer" },

			-- Terminals. Normal mode only: leader is Space, and a terminal
			-- forwards every keystroke to the program inside it, so a
			-- terminal-mode <leader>th would fire while you typed "the".
			{ "<leader>tt", term("float"), desc = "Toggle floating terminal" },
			{ "<leader>tv", term("vertical"), desc = "Toggle vertical terminal" },
			{ "<leader>th", term("horizontal"), desc = "Toggle horizontal terminal" },

			-- Dismissing from inside needs a chord no program expects.
			{ "<A-t>", term("float"), mode = "t", desc = "Hide floating terminal" },
			{ "<A-v>", term("vertical"), mode = "t", desc = "Hide vertical terminal" },
			{ "<A-h>", term("horizontal"), mode = "t", desc = "Hide horizontal terminal" },

			-- Git
			{ "<leader>gg", function() Snacks.lazygit() end, desc = "Lazygit" },
			{ "<leader>gb", function() Snacks.gitbrowse() end, desc = "Open in browser" },
		}
	end,
}
```

- [x] **Step 4: Write the find-and-replace spec**

Create `lua/plugins/replace.lua`:

```lua
-- Project-wide find and replace.
--
-- The picker greps but cannot rewrite. The alternative is building a quickfix
-- list and driving :cdo over it, which works and is unpleasant enough that in
-- practice nobody does it. grug-far shows the matches and the replacement side
-- by side and applies them in one step.
--
-- It shells out to ripgrep, which is already a dependency of the picker.
return {
	"MagicDuck/grug-far.nvim",
	cmd = "GrugFar",

	opts = { headerMaxWidth = 80 },

	keys = {
		{
			"<leader>fs",
			function()
				require("grug-far").open({ transient = true })
			end,
			desc = "Search and replace (project)",
		},
		{
			"<leader>fS",
			function()
				require("grug-far").open({
					transient = true,
					prefills = { paths = vim.fn.expand("%") },
				})
			end,
			desc = "Search and replace (this file)",
		},
	},
}
```

- [x] **Step 5: Install, run the test**

Run: `cd ~/.config/nvim && nvim --headless "+Lazy! sync" +qa`
Run: `cd ~/.config/nvim && tests/nvim-test tests/snacks.lua -c 'Lazy! load all'`
Expected: PASS.

- [x] **Step 6: Verify the terminal bug is actually fixed**

This is the check that matters, and a headless test cannot press a mouse button.

```bash
cd ~/.config/nvim && nvim init.lua
```

Inside Neovim: press `<leader>tt`. The floating terminal opens and takes focus. **Click on the code behind it** with the mouse. The float stays on screen and focus moves to the code. Press `<leader>tt` **once**. Expected: focus returns to the terminal. In the previous config this closed it and getting back in took a second press. Press `<leader>tt` again and it hides. Then `:q!`.

- [x] **Step 7: Add to the runner, run the suite, commit**

Modify `tests/run.sh` `for` line to include `tests/snacks.lua` after `tests/mini.lua`.

```bash
cd ~/.config/nvim && tests/run.sh; echo "exit=$?"
git add lua/plugins/snacks.lua lua/plugins/replace.lua tests/snacks.lua tests/run.sh
git commit -m "feat: workflow layer on snacks, plus project-wide replace

Picker, explorer, terminal, input, notifier. Terminals use focus() rather
than toggle(): toggle asks only whether the buffer is in a window, so
clicking off a float and pressing the key closed it instead of returning."
```

---

### Task 6: Editing verbs — mini

**Files:**
- Modify: `lua/plugins/mini.lua`
- Test: `tests/editing.lua`
- Modify: `tests/run.sh`

**Interfaces:**
- Consumes: treesitter parsers from Task 2, which `mini.ai` uses for function and class textobjects.
- Produces: nothing later tasks call.

- [x] **Step 1: Write the failing test**

Create `tests/editing.lua`:

```lua
local t = require("testkit")

t.run(function()
	for _, g in ipairs({
		"MiniAi", "MiniSurround", "MiniOperators", "MiniMove",
		"MiniSplitjoin", "MiniPairs", "MiniBracketed", "MiniClue", "MiniAlign",
	}) do
		t.truthy(g .. " is active", _G[g] ~= nil)
	end

	-- Surround lives under gs so it does not shadow s, which flash-style jumps
	-- and the built-in substitute both want.
	t.truthy("gsa adds a surround", vim.fn.maparg("gsa", "n") ~= "")
	t.truthy("gsd deletes a surround", vim.fn.maparg("gsd", "n") ~= "")
	t.truthy("gsr replaces a surround", vim.fn.maparg("gsr", "n") ~= "")

	-- mini.ai gives function and class textobjects from the parse tree.
	vim.cmd("edit /tmp/mini-ai-test.lua")
	vim.api.nvim_buf_set_lines(0, 0, -1, false, {
		"local function outer()",
		"  return 1",
		"end",
	})
	vim.bo.filetype = "lua"
	vim.treesitter.start()
	vim.api.nvim_win_set_cursor(0, { 2, 2 })

	-- pcall, and assert the shape defensively. A treesitter textobject with no
	-- installed parser does not fail cleanly: probing this before Task 2 had
	-- run hung headless Neovim until it was killed. If this reports false,
	-- the lua parser is missing and Task 2 is incomplete.
	local ok, region = pcall(MiniAi.find_textobject, "a", "f")
	t.truthy("af finds the enclosing function", ok and type(region) == "table")
	if ok and type(region) == "table" and region.from and region.to then
		t.check("function starts on line 1", region.from.line, 1)
		t.check("function ends on line 3", region.to.line, 3)
	end
	vim.fn.delete("/tmp/mini-ai-test.lua")

	-- mini.clue replaces which-key. It must know about the prefixes this
	-- config actually uses, or pressing <leader> shows bare letters.
	local cfg = MiniClue.config
	local prefixes = {}
	for _, c in ipairs(cfg.clues) do
		if c.keys then
			prefixes[c.keys] = true
		end
	end
	for _, p in ipairs({ "<Leader>f", "<Leader>l", "<Leader>t", "<Leader>g", "<Leader>u" }) do
		t.truthy(p .. " has a group label", prefixes[p] == true)
	end
end)
```

- [x] **Step 2: Run test to verify it fails**

Run: `cd ~/.config/nvim && tests/nvim-test tests/editing.lua`
Expected: FAIL. `MiniAi is active` reports a falsy value.

- [x] **Step 3: Write the implementation**

Modify `lua/plugins/mini.lua`, adding inside `config = function()` after the existing appearance modules:

```lua
		-- ---------------------------------------------------------------
		-- Editing verbs
		-- ---------------------------------------------------------------

		-- Extra a/i textobjects, including function and class from the parse
		-- tree. Task 2's parsers are what make af and ac work.
		local ai = require("mini.ai")
		ai.setup({
			n_lines = 500,
			custom_textobjects = {
				f = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }),
				c = ai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }),
			},
		})

		-- Surround under gs, not s. Plain s is wanted by the built-in
		-- substitute and by jump plugins, and taking it costs more than the
		-- two extra keystrokes save.
		require("mini.surround").setup({
			mappings = {
				add = "gsa",
				delete = "gsd",
				find = "gsf",
				find_left = "gsF",
				highlight = "gsh",
				replace = "gsr",
				update_n_lines = "gsn",
			},
		})

		-- Operators: g= evaluate, gx exchange, gm multiply, gr replace with
		-- register, gs sort. gr conflicts with nothing here because Neovim's
		-- own gr* LSP maps are three keys (grn, gra, grr) and mini.operators
		-- takes the two-key form.
		require("mini.operators").setup()

		-- Move a selection with Alt+hjkl, reindenting as it goes.
		require("mini.move").setup()

		-- Split and join argument lists with gS.
		require("mini.splitjoin").setup()

		-- Autopairs.
		require("mini.pairs").setup()

		-- [b ]b buffers, [d ]d diagnostics, [q ]q quickfix, and so on. The
		-- diagnostic pair here is the same action lua/keymaps.lua binds, so
		-- both spellings work.
		require("mini.bracketed").setup()

		-- Align with ga / gA.
		require("mini.align").setup()

		-- Key hints, replacing which-key. mini.clue does not discover group
		-- names on its own, so every prefix this config uses is listed.
		local clue = require("mini.clue")
		clue.setup({
			triggers = {
				{ mode = "n", keys = "<Leader>" },
				{ mode = "x", keys = "<Leader>" },
				{ mode = "n", keys = "<LocalLeader>" },
				{ mode = "n", keys = "g" },
				{ mode = "x", keys = "g" },
				{ mode = "n", keys = "[" },
				{ mode = "n", keys = "]" },
				{ mode = "n", keys = '"' },
				{ mode = "i", keys = "<C-r>" },
			},
			clues = {
				{ mode = "n", keys = "<Leader>f", desc = "+find" },
				{ mode = "n", keys = "<Leader>l", desc = "+lsp" },
				{ mode = "n", keys = "<Leader>t", desc = "+terminal" },
				{ mode = "n", keys = "<Leader>g", desc = "+git" },
				{ mode = "n", keys = "<Leader>u", desc = "+ui toggles" },
				{ mode = "n", keys = "<Leader>n", desc = "+notes" },
				{ mode = "n", keys = "gs", desc = "+surround" },
				clue.gen_clues.builtin_completion(),
				clue.gen_clues.g(),
				clue.gen_clues.marks(),
				clue.gen_clues.registers(),
				clue.gen_clues.windows(),
				clue.gen_clues.z(),
			},
			window = { config = { border = "rounded" }, delay = 300 },
		})
```

- [x] **Step 4: Run test to verify it passes**

Run: `cd ~/.config/nvim && tests/nvim-test tests/editing.lua`
Expected: PASS.

- [x] **Step 5: Add to the runner, run the suite, commit**

Modify `tests/run.sh` `for` line to include `tests/editing.lua` after `tests/mini.lua`.

```bash
cd ~/.config/nvim && tests/run.sh; echo "exit=$?"
git add lua/plugins/mini.lua tests/editing.lua tests/run.sh
git commit -m "feat: editing verbs on mini

ai, surround, operators, move, splitjoin, pairs, bracketed, align, clue.
Surround lives under gs so plain s stays free. mini.clue replaces which-key
and needs every prefix listed, because it discovers no group names itself."
```

---

### Task 7: Formatting

**Files:**
- Create: `lua/plugins/conform.lua`
- Test: `tests/format.lua`
- Modify: `tests/run.sh`

**Interfaces:**
- Consumes: nothing from earlier tasks.
- Produces: `<leader>uf` toggle and `vim.g.disable_autoformat`.

- [x] **Step 1: Write the failing test**

Create `tests/format.lua`:

```lua
local t = require("testkit")

t.run(function()
	local conform = require("conform")

	local expected = {
		c = "clang_format",
		cpp = "clang_format",
		lua = "stylua",
		python = "ruff_format",
		markdown = "prettier",
		json = "jq",
		sh = "shfmt",
	}
	for ft, formatter in pairs(expected) do
		local list = conform.formatters_by_ft[ft]
		t.truthy(ft .. " formats with " .. formatter, list and vim.tbl_contains(list, formatter))
	end

	-- ruff_fix must not delete an import you have not used yet. F401 is
	-- fixable by default, so every save removed imports mid-edit.
	local args = conform.formatters.ruff_fix.args
	t.truthy("ruff_fix ignores F401", vim.tbl_contains(args, "F401"))

	-- prettier must not reflow a paragraph. Soft wrap does the wrapping on
	-- screen, so one paragraph stays one line and a one-word edit stays a
	-- one-word diff.
	local pargs = conform.formatters.prettier.prepend_args
	t.truthy("prettier preserves prose wrap", vim.tbl_contains(pargs, "preserve"))

	-- prettier is a Node program and pays a cold interpreter start on the
	-- first markdown save. At the 1000ms used elsewhere that start times out
	-- and conform writes the file unformatted, with only a line in :messages.
	--
	-- format_on_save is a field of the lazy spec's opts table, not a function
	-- on the conform module. Reading it off `require("conform")` returns nil
	-- and the test errors rather than failing with a useful message.
	local opts = require("lazy.core.config").plugins["conform.nvim"].opts
	vim.cmd("edit /tmp/fmt-test.md")
	t.check("markdown save timeout", opts.format_on_save(vim.api.nvim_get_current_buf()).timeout_ms, 3000)
	vim.cmd("edit /tmp/fmt-test.lua")
	t.check("other filetypes keep 1000ms", opts.format_on_save(vim.api.nvim_get_current_buf()).timeout_ms, 1000)
	vim.fn.delete("/tmp/fmt-test.md")
	vim.fn.delete("/tmp/fmt-test.lua")

	t.truthy("<leader>uf toggles format on save", vim.fn.maparg("<leader>uf", "n", false, true).callback ~= nil)
	t.truthy("<leader>lf formats on demand", vim.fn.maparg("<leader>lf", "n", false, true).callback ~= nil)
end)
```

- [x] **Step 2: Run test to verify it fails**

Run: `cd ~/.config/nvim && tests/nvim-test tests/format.lua`
Expected: FAIL with an error requiring `conform`, which is not installed.

- [x] **Step 3: Write the implementation**

Create `lua/plugins/conform.lua`:

```lua
-- Formatting, on save and on demand.
--
-- clang-format came from the mason tree and went with it. Install it from the
-- system if C or C++ formatting matters: `brew install clang-format`.
return {
	"stevearc/conform.nvim",
	event = "BufWritePre",
	cmd = "ConformInfo",

	keys = {
		{
			"<leader>lf",
			function()
				require("conform").format({ async = true, lsp_format = "fallback" })
			end,
			mode = { "n", "v" },
			desc = "Format buffer",
		},
		{
			"<leader>uf",
			function()
				vim.g.disable_autoformat = not vim.g.disable_autoformat
				vim.notify("format on save " .. (vim.g.disable_autoformat and "off" or "on"))
			end,
			desc = "Toggle format on save",
		},
	},

	opts = {
		formatters_by_ft = {
			c = { "clang_format" },
			cpp = { "clang_format" },
			lua = { "stylua" },
			python = { "ruff_fix", "ruff_format" },
			json = { "jq" },
			sh = { "shfmt" },

			-- prettier, not mdformat. prettier aligns the pipes of a markdown
			-- table to the widest cell in each column, which is the reason a
			-- formatter is here at all, and it leaves $...$ untouched so a
			-- formatted note keeps its maths.
			markdown = { "prettier" },

			-- Trim trailing whitespace on any filetype with no formatter.
			["_"] = { "trim_whitespace" },
		},

		formatters = {
			-- conform's ruff_fix runs `ruff check --fix`, and F401 (unused
			-- import) is fixable by default, so every save deleted imports not
			-- referenced yet. That is wrong while a file is being written. The
			-- ruff server still reports the unused import as a diagnostic.
			--
			-- args is replaced wholesale rather than using prepend_args,
			-- because prepend_args would insert before the "check" subcommand
			-- and produce `ruff --ignore F401 check`, which is not valid.
			ruff_fix = {
				args = {
					"check",
					"--fix",
					"--ignore",
					"F401",
					"--force-exclude",
					"--exit-zero",
					"--no-cache",
					"--stdin-filename",
					"$FILENAME",
					"-",
				},
			},

			prettier = {
				-- Never reflow a paragraph. Soft wrap does the wrapping on
				-- screen, so one paragraph stays on one line and a one-word
				-- edit stays a one-word diff. Without this, prettier rewraps
				-- at 80 and every save rewrites lines you did not touch.
				prepend_args = { "--prose-wrap", "preserve" },
			},
		},

		default_format_opts = { lsp_format = "fallback" },

		format_on_save = function(bufnr)
			if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
				return
			end

			-- prettier is a Node program and pays for a cold interpreter start
			-- on the first markdown save of a session. That start alone takes
			-- longer than 1000ms, and conform answers a timeout by writing the
			-- file unformatted with only a message in :messages to say so.
			local timeout = vim.bo[bufnr].filetype == "markdown" and 3000 or 1000

			return { timeout_ms = timeout, lsp_format = "fallback" }
		end,
	},
}
```

- [x] **Step 4: Install, run the test**

Run: `cd ~/.config/nvim && nvim --headless "+Lazy! sync" +qa`
Run: `cd ~/.config/nvim && tests/nvim-test tests/format.lua -c 'Lazy! load conform.nvim'`
Expected: PASS.

- [x] **Step 5: Add to the runner, run the suite, commit**

Modify `tests/run.sh` to run this one with the extra load flag. Replace the loop body with:

```bash
for test in tests/boot.lua tests/editor.lua tests/treesitter.lua tests/lsp.lua \
            tests/completion.lua tests/mini.lua tests/editing.lua \
            tests/snacks.lua tests/format.lua; do
  echo "== $test"
  if tests/nvim-test "$test" -c 'Lazy! load all' 2>&1; then
```

```bash
cd ~/.config/nvim && tests/run.sh; echo "exit=$?"
git add lua/plugins/conform.lua tests/format.lua tests/run.sh
git commit -m "feat: formatting through conform

ruff_fix ignores F401 so a save never deletes an import you have not used
yet. Markdown gets a 3000ms timeout because prettier's cold Node start
exceeds the 1000ms used elsewhere, and conform answers a timeout by writing
the file unformatted."
```

---

### Task 8: Git

**Files:**
- Modify: `lua/plugins/mini.lua`
- Test: `tests/git.lua`
- Modify: `tests/run.sh`

**Interfaces:**
- Consumes: `Snacks.lazygit` and `Snacks.gitbrowse` keys already bound in Task 5.
- Produces: nothing later tasks call.

- [x] **Step 1: Write the failing test**

Create `tests/git.lua`:

```lua
local t = require("testkit")

t.run(function()
	t.truthy("MiniDiff is active", _G.MiniDiff ~= nil)
	t.truthy("MiniGit is active", _G.MiniGit ~= nil)

	-- Hunk navigation and staging.
	for _, key in ipairs({ "<leader>gs", "<leader>gr", "<leader>gp", "<leader>go" }) do
		local m = vim.fn.maparg(key, "n", false, true)
		t.truthy(key .. " is mapped", m.callback ~= nil or m.rhs ~= nil)
	end

	-- Snacks owns lazygit; mini owns the in-buffer signs. Not both.
	local gg = vim.fn.maparg("<leader>gg", "n", false, true)
	t.truthy("<leader>gg opens lazygit", gg.callback ~= nil)

	-- gitsigns must not be installed. Two sign columns for the same hunks is
	-- the exact seam this split exists to avoid.
	local plugins = require("lazy.core.config").plugins
	t.check("gitsigns absent", plugins["gitsigns.nvim"], nil)
end)
```

- [x] **Step 2: Run test to verify it fails**

Run: `cd ~/.config/nvim && tests/nvim-test tests/git.lua -c 'Lazy! load all'`
Expected: FAIL. `MiniDiff is active` reports a falsy value.

- [x] **Step 3: Write the implementation**

Modify `lua/plugins/mini.lua`, adding inside `config = function()`:

```lua
		-- ---------------------------------------------------------------
		-- Git
		-- ---------------------------------------------------------------

		-- Hunk signs, staging and the diff overlay. This replaces gitsigns.
		-- snacks has no equivalent, and lazygit covers the parts that want a
		-- full interface rather than an inline one.
		require("mini.diff").setup({
			view = { style = "sign", signs = { add = "▎", change = "▎", delete = "" } },
		})

		-- :Git commands and the blame/log buffers.
		require("mini.git").setup()

		local map = function(lhs, rhs, desc)
			vim.keymap.set("n", lhs, rhs, { silent = true, desc = desc })
		end

		map("<leader>gs", function()
			MiniDiff.do_hunks(0, "apply")
		end, "Stage hunk")
		map("<leader>gr", function()
			MiniDiff.do_hunks(0, "reset")
		end, "Reset hunk")
		map("<leader>go", MiniDiff.toggle_overlay, "Toggle diff overlay")
		map("<leader>gp", function()
			vim.cmd("Git log --oneline -20 -- " .. vim.fn.expand("%"))
		end, "File history")
```

- [x] **Step 4: Run test to verify it passes**

Run: `cd ~/.config/nvim && tests/nvim-test tests/git.lua -c 'Lazy! load all'`
Expected: PASS.

- [x] **Step 5: Add to the runner, run the suite, commit**

Modify `tests/run.sh` `for` line to include `tests/git.lua`.

```bash
cd ~/.config/nvim && tests/run.sh; echo "exit=$?"
git add lua/plugins/mini.lua tests/git.lua tests/run.sh
git commit -m "feat: git signs and staging on mini.diff

mini.diff replaces gitsigns, snacks keeps lazygit. Two sign columns for the
same hunks is the seam the suite split exists to avoid."
```

---

### Task 9: LaTeX and markdown

The largest port. Roughly 650 lines move from `bak-nvim` with the maths and code detectors intact.

**Files:**
- Create: `lua/util/tex.lua` (ported and already fixed)
- Create: `snippets/tex.lua` (ported)
- Create: `after/ftplugin/tex.lua`, `after/ftplugin/markdown.lua` (ported)
- Create: `lua/plugins/vimtex.lua`, `lua/plugins/luasnip.lua`, `lua/plugins/markdown.lua`
- Create: `lsp/ltex_plus.lua`, `lua/notes.lua`
- Modify: `init.lua`, `lua/lsp.lua`
- Test: `tests/tex.lua`, `tests/markdown.lua`
- Modify: `tests/run.sh`

**Interfaces:**
- Consumes: treesitter `latex`, `markdown`, `markdown_inline` parsers from Task 2.
- Produces: `require("util.tex").in_math()`, `.in_text()`, `.in_code()`, all returning boolean. `snippets/tex.lua` returns a list of LuaSnip snippets and is loaded for both `tex` and `markdown`.

- [x] **Step 1: Port the files that carry unchanged**

```bash
cd ~/.config/nvim
mkdir -p lua/util snippets after/ftplugin
cp ~/.config/bak-nvim/lua/util/tex.lua lua/util/tex.lua
cp ~/.config/bak-nvim/snippets/tex.lua snippets/tex.lua
cp ~/.config/bak-nvim/after/ftplugin/tex.lua after/ftplugin/tex.lua
cp ~/.config/bak-nvim/after/ftplugin/markdown.lua after/ftplugin/markdown.lua
cp ~/.config/bak-nvim/lua/plugins/vimtex.lua lua/plugins/vimtex.lua
```

These four already contain the fixes from the previous session: `in_code` covering tagged fences, untagged fences, indented blocks, code spans and LaTeX `verbatim`; `dm` differing by filetype; the twelve LaTeX-markup snippets gated to `.tex`; and ordered task lists in the checkbox toggle. Do not rewrite them.

- [x] **Step 2: Write the failing test**

Create `tests/tex.lua`:

```lua
local t = require("testkit")

t.run(function()
	t.check("tex_flavor", vim.g.tex_flavor, "latex")

	-- vimtex must load eagerly. Inverse search from Skim calls back into a
	-- global command that has to exist before Skim runs, and ft-loading
	-- vimtex breaks that.
	local spec = require("lazy.core.config").plugins.vimtex
	t.check("vimtex loads eagerly", spec.lazy, false)
	t.check("vimtex has no ft trigger", spec.ft, nil)
	t.check("vimtex syntax off", vim.g.vimtex_syntax_enabled, 0)
	t.check("vimtex view method", vim.g.vimtex_view_method, "skim")
	t.check("vimtex compiler", vim.g.vimtex_compiler_method, "latexmk")

	local tex = require("util.tex")

	-- A brand new .tex file must open as tex, not plaintex.
	vim.cmd("edit /tmp/tex-test.tex")
	t.check("filetype of a new .tex", vim.bo.filetype, "tex")

	local function at(lines, row, col)
		vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
		vim.api.nvim_win_set_cursor(0, { row, col })
	end

	at({ "Ordinary prose.", "An inline formula $x + y$ sits here." }, 1, 5)
	t.check("prose is not math", tex.in_math(), false)
	t.check("prose is text", tex.in_text(), true)
	at({ "Ordinary prose.", "An inline formula $x + y$ sits here." }, 2, 22)
	t.check("inside $...$ is math", tex.in_math(), true)

	-- verbatim is this filetype's code block. mk fires in text, and a code
	-- block is text as far as the maths test goes, so without in_code typing a
	-- variable named mk inside verbatim rewrote it as $$.
	at({ "Text.", "\\begin{verbatim}", "mk", "\\end{verbatim}" }, 3, 1)
	t.check("verbatim is code", tex.in_code(), true)
	t.check("verbatim is not text", tex.in_text(), false)

	vim.fn.delete("/tmp/tex-test.tex")
end)
```

Create `tests/markdown.lua`:

```lua
local t = require("testkit")

t.run(function()
	local tex = require("util.tex")

	vim.cmd("edit /tmp/md-test.md")
	t.check("filetype of a new .md", vim.bo.filetype, "markdown")

	local function at(lines, row, col)
		vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
		vim.api.nvim_win_set_cursor(0, { row, col })
	end

	-- markdown_inline wraps $x$ in a latex_block with the latex parser
	-- injected, so the same inline_formula node appears in a note as in a
	-- .tex file. That is what lets one snippet file serve both.
	at({ "Prose here.", "An inline formula $x + y$ sits here." }, 2, 22)
	t.check("markdown $...$ is math", tex.in_math(), true)
	at({ "Prose here.", "An inline formula $x + y$ sits here." }, 1, 5)
	t.check("markdown prose is text", tex.in_text(), true)

	-- Code must never be treated as prose. A fence tagged with a language
	-- injects that language's parser, so the node chain from the cursor never
	-- reaches markdown's fenced_code_block and the ancestor walk finds
	-- nothing. in_code asks which language owns the cursor for that case.
	at({ "```python", "x = 1", "```" }, 2, 1)
	t.check("tagged fence is code", tex.in_code(), true)
	at({ "```", "abc", "```" }, 2, 1)
	t.check("untagged fence is code", tex.in_code(), true)
	at({ "Text.", "", "    indented code", "" }, 3, 8)
	t.check("indented block is code", tex.in_code(), true)
	at({ "Use `xy` here." }, 1, 5)
	t.check("inline code span is code", tex.in_code(), true)

	-- Buffer settings.
	at({ "" }, 1, 0)
	t.check("markdown spell", vim.opt_local.spell:get(), true)
	t.check("markdown expandtab", vim.opt_local.expandtab:get(), true)
	t.truthy("gf finds .md", vim.tbl_contains(vim.opt_local.suffixesadd:get(), ".md"))

	-- Checkbox toggle, dashed and numbered.
	local toggle = vim.fn.maparg("<localleader>x", "n", false, true).callback
	t.truthy("checkbox map exists", toggle ~= nil)
	local function toggles(input, want)
		vim.api.nvim_buf_set_lines(0, 0, -1, false, { input })
		vim.api.nvim_win_set_cursor(0, { 1, 0 })
		pcall(toggle)
		return vim.api.nvim_get_current_line() == want
	end
	t.truthy("toggle - [ ]", toggles("- [ ] task", "- [x] task"))
	t.truthy("toggle 1. [ ]", toggles("1. [ ] task", "1. [x] task"))
	t.truthy("toggle leaves prose alone", toggles("Some prose.", "Some prose."))

	-- The tex snippet file must reach a markdown buffer.
	t.truthy("markdown extends tex", vim.tbl_contains(require("luasnip").get_snippet_filetypes(), "tex"))

	-- Notes keys.
	for _, k in ipairs({ "<leader>nf", "<leader>ng", "<leader>nn" }) do
		t.truthy(k .. " is mapped", vim.fn.maparg(k, "n", false, true).callback ~= nil)
	end

	vim.fn.delete("/tmp/md-test.md")
end)
```

- [x] **Step 3: Run both tests to verify they fail**

Run: `cd ~/.config/nvim && tests/nvim-test tests/tex.lua -c 'Lazy! load all'`
Expected: FAIL. `vimtex loads eagerly` errors, because vimtex is not installed.

- [x] **Step 4: Write the plugin specs**

Create `lua/plugins/luasnip.lua`:

```lua
-- LuaSnip.
--
-- Kept rather than replaced by vim.snippet or mini.snippets. Neither expands a
-- trigger as you type without a confirm key, and snippets/tex.lua is 420 lines
-- of maths triggers that depend on exactly that.
return {
	"L3MON4D3/LuaSnip",
	event = "InsertEnter",

	config = function()
		local ls = require("luasnip")

		ls.config.set_config({
			-- Without this every `mk` would need a completion menu and a
			-- confirm key. The tex snippets expand as you type.
			enable_autosnippets = true,

			-- Leaving a snippet's region ends it. Without these, moving the
			-- cursor back into a finished snippet re-enters it and the next
			-- <Tab> jumps to a placeholder already filled in.
			region_check_events = { "CursorMoved", "InsertLeave" },
			delete_check_events = "TextChanged",
			update_events = { "TextChanged", "TextChangedI" },
		})

		require("luasnip.loaders.from_lua").lazy_load({
			paths = { vim.fn.stdpath("config") .. "/snippets" },
		})

		-- A markdown buffer gets the tex snippet file too. Notes are prose
		-- with maths in them, and copying 420 lines of triggers into a second
		-- file would leave two copies to keep in step.
		--
		-- Safe because util/tex.lua answers "is the cursor in maths" from the
		-- parse tree, and markdown injects the latex parser into $...$. The
		-- LaTeX-only snippets in that file carry a filetype test of their own.
		ls.filetype_extend("markdown", { "tex" })

		vim.api.nvim_create_user_command("SnipReload", function()
			require("luasnip.loaders.from_lua").load({
				paths = { vim.fn.stdpath("config") .. "/snippets" },
			})
			vim.notify("Snippets reloaded")
		end, { desc = "Reload LuaSnip snippet files" })
	end,
}
```

Create `lua/plugins/markdown.lua`:

```lua
-- Markdown rendering, and images.
return {
	{
		-- Renders markdown inside the buffer. No browser, no node or deno
		-- build step, and the file stays editable while it renders.
		"MeanderingProgrammer/render-markdown.nvim",
		dependencies = { "nvim-treesitter/nvim-treesitter" },
		ft = { "markdown" },

		opts = {
			-- The default un-renders the whole buffer the moment you enter
			-- insert mode, repainting every line on every `i`. Rendering in
			-- insert too, with anti_conceal clearing only the cursor line,
			-- keeps the rest of the screen still.
			render_modes = { "n", "c", "t", "i" },
			anti_conceal = { enabled = true },
			heading = { sign = false },
			code = { sign = false, width = "block", min_width = 40, left_pad = 2, right_pad = 2 },
		},

		keys = {
			{ "<leader>um", "<cmd>RenderMarkdown buf_toggle<CR>", desc = "Toggle markdown rendering" },
		},
	},
}
```

Modify `lua/plugins/snacks.lua`, adding to `opts`:

```lua
		-- Inline images and rendered LaTeX maths, over the Kitty graphics
		-- protocol. Ghostty supports it, so a $$ block in a note draws as
		-- typeset maths rather than as source.
		image = { enabled = true },
```

- [x] **Step 5: Write the notes module**

Create `lua/notes.lua`:

```lua
-- Notes.
--
-- A notes tree is a directory of markdown files and nothing else. No index, no
-- database, no second tool. The picker reads a directory faster than an index
-- would, so these three keys are the whole feature.
--
-- Set vim.g.notes_dir to point somewhere other than ~/SCHOOL. options.lua
-- turns exrc on, so a per-project .nvim.lua is read after you confirm its hash.
local function notes_dir()
	return vim.fn.expand(vim.g.notes_dir or "~/SCHOOL")
end

local function map(lhs, rhs, desc)
	vim.keymap.set("n", lhs, rhs, { silent = true, desc = desc })
end

map("<leader>nf", function()
	Snacks.picker.files({ cwd = notes_dir(), title = "Notes" })
end, "Find note")

map("<leader>ng", function()
	Snacks.picker.grep({ cwd = notes_dir(), title = "Grep notes" })
end, "Grep notes")

-- Asks for a path relative to the notes root, creates any missing directory in
-- it, and opens the file. autocmds.lua also creates parent directories on
-- write, but doing it here means the tree exists before you start typing.
map("<leader>nn", function()
	vim.ui.input({ prompt = "New note (path under " .. notes_dir() .. "): " }, function(name)
		if not name or name == "" then
			return
		end
		if not name:match("%.md$") then
			name = name .. ".md"
		end
		local path = notes_dir() .. "/" .. name
		vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
		vim.cmd("edit " .. vim.fn.fnameescape(path))
	end)
end, "New note")
```

Modify `init.lua`, adding after the other requires:

```lua
require("notes")
```

- [x] **Step 6: Add the grammar server**

`ltex-ls-plus` was lost with the mason tree. Install it from its release page, or skip this step: it is a 200MB Java server and everything else in this task works without it.

Create `lsp/ltex_plus.lua`:

```lua
-- ltex-ls-plus, the maintained fork. The original valentjn/ltex-ls has had no
-- release since 2023 and does not run on a current JDK.
--
-- It checks grammar in prose and understands both markdown and LaTeX well
-- enough to skip the markup: it does not report \alpha or a table pipe as a
-- spelling mistake.
--
-- Its own default filetype list names eighteen filetypes including gitcommit.
-- A Java server starting on every commit message is a cost with no return, so
-- this is narrowed to the two that hold prose here.
local dir = vim.fn.stdpath("config") .. "/ltex"
vim.fn.mkdir(dir, "p")

local function words(name)
	local path = dir .. "/" .. name .. ".txt"
	return vim.fn.filereadable(path) == 1 and vim.fn.readfile(path) or {}
end

-- ltex reports an added word back to the client rather than writing it itself.
-- The write goes through a set: ltex sends this every time you accept the code
-- action, including on a word the file already holds, so appending without a
-- duplicate check grew the file by one line each time.
local function append(name)
	return function(_, params)
		local seen, out = {}, {}
		local function add(word)
			if not seen[word] then
				seen[word] = true
				out[#out + 1] = word
			end
		end
		for _, w in ipairs(words(name)) do
			add(w)
		end
		for _, list in pairs(params.words or {}) do
			for _, w in ipairs(list) do
				add(w)
			end
		end
		table.sort(out)
		vim.fn.writefile(out, dir .. "/" .. name .. ".txt")
	end
end

return {
	cmd = { "ltex-ls-plus" },
	filetypes = { "markdown", "tex" },
	root_markers = { ".git" },
	settings = {
		ltex = {
			language = "en-US",
			enabled = { "markdown", "latex", "tex" },
			dictionary = { ["en-US"] = words("dictionary") },
			disabledRules = { ["en-US"] = words("disabled-rules") },
			hiddenFalsePositives = { ["en-US"] = words("false-positives") },
			-- LanguageTool checks the whole document on every keystroke by
			-- default, which stalls a long note.
			checkFrequency = "edit",
			additionalRules = { enablePickyRules = true },
		},
	},
	handlers = {
		["ltex/workspaceSpecificConfiguration"] = function() end,
		["$/ltex/addToDictionary"] = append("dictionary"),
		["$/ltex/disableRules"] = append("disabled-rules"),
		["$/ltex/hideFalsePositives"] = append("false-positives"),
	},
}
```

Modify `lua/lsp.lua`, changing the enable call to:

```lua
vim.lsp.enable({ "clangd", "lua_ls", "pyright", "ruff", "ltex_plus" })
```

Add `ltex/` to `.gitignore`? No. The dictionary is worth keeping in the repository, so leave it tracked.

- [x] **Step 7: Install and run both tests**

Run: `cd ~/.config/nvim && nvim --headless "+Lazy! sync" +qa`
Run: `cd ~/.config/nvim && tests/nvim-test tests/tex.lua -c 'Lazy! load all'`
Run: `cd ~/.config/nvim && tests/nvim-test tests/markdown.lua -c 'Lazy! load all'`
Expected: PASS for both.

- [x] **Step 8: Verify snippets actually expand**

A headless test can assert the detectors; only a real keypress proves the snippets fire.

```bash
cd /tmp && nvim note.md
```

Inside Neovim: press `i`, type `mk`. Expected: `$$` with the cursor between them. Type `//`. Expected: `\frac{}{}` inside the dollars. Escape, then type `i` on a new line and type `` ```python `` and Enter, then `mk`. Expected: the literal text `mk`, not `$$`, because the cursor is in code. Then `:q!` and `rm /tmp/note.md`.

- [x] **Step 9: Add to the runner, run the suite, commit**

Modify `tests/run.sh` `for` line to include `tests/tex.lua tests/markdown.lua`.

```bash
cd ~/.config/nvim && tests/run.sh; echo "exit=$?"
git add lua/util snippets after lua/plugins/vimtex.lua lua/plugins/luasnip.lua \
        lua/plugins/markdown.lua lua/plugins/snacks.lua lua/notes.lua \
        lsp/ltex_plus.lua lua/lsp.lua init.lua tests/tex.lua tests/markdown.lua tests/run.sh
git commit -m "feat: LaTeX and markdown notes

Ported from the previous config with the maths and code detectors intact.
One snippet file serves both filetypes: markdown_inline wraps \$x\$ in a
latex_block with the latex parser injected, so the same inline_formula node
appears in a note as in a .tex file."
```

---

### Task 10: Debugger

The first genuinely new capability. The previous config had no debugger at all.

**Files:**
- Create: `lua/plugins/dap.lua`
- Test: `tests/dap.lua`
- Modify: `tests/run.sh`

**Interfaces:**
- Consumes: nothing from earlier tasks.
- Produces: `<leader>b` and `<F5>`-family keymaps.

- [x] **Step 1: Install the adapters**

C and C++ use gdb, which speaks DAP directly since gdb 14. No wrapper script and no cpptools.

Run: `command -v gdb || brew install gdb`
Run: `gdb --version | head -1` and confirm the version is 14 or later.
Run: `python3 -m pip install --user debugpy`

If gdb refuses to run on Apple silicon, use codelldb instead: download from the vscode-lldb releases and change the `cmd` in Step 3 to point at `codelldb --port ${port}` with `type = "server"`.

- [x] **Step 2: Write the failing test**

Create `tests/dap.lua`:

```lua
local t = require("testkit")

t.run(function()
	local dap = require("dap")

	-- Adapters.
	t.truthy("gdb adapter registered", dap.adapters.gdb ~= nil)
	t.truthy("python adapter registered", dap.adapters.python ~= nil)

	-- Configurations per filetype.
	for _, ft in ipairs({ "c", "cpp", "python" }) do
		t.truthy(ft .. " has a launch configuration", dap.configurations[ft] ~= nil and #dap.configurations[ft] > 0)
	end

	-- gdb must be invoked with the DAP interpreter. Without this flag it
	-- speaks the MI protocol and nvim-dap cannot talk to it at all.
	t.truthy("gdb uses the dap interpreter", vim.tbl_contains(dap.adapters.gdb.args, "--interpreter=dap"))

	-- Keymaps.
	local keys = { "<leader>b", "<leader>B", "<F5>", "<F10>", "<F11>", "<F12>" }
	for _, k in ipairs(keys) do
		local m = vim.fn.maparg(k, "n", false, true)
		t.truthy(k .. " is mapped", m.callback ~= nil or m.rhs ~= nil)
	end

	-- The UI opens and closes with the session rather than by hand.
	t.truthy("dapui is loaded", package.loaded["dapui"] ~= nil)
	t.truthy("before_event listener", dap.listeners.before.event_terminated["dapui_config"] ~= nil)
end)
```

- [x] **Step 3: Run test to verify it fails**

Run: `cd ~/.config/nvim && tests/nvim-test tests/dap.lua -c 'Lazy! load all'`
Expected: FAIL with an error requiring `dap`, which is not installed.

- [x] **Step 4: Write the implementation**

Create `lua/plugins/dap.lua`:

```lua
-- Debugging.
--
-- The previous config had none. This is the largest single gap between that
-- config and an IDE, and the one that matters most for a C and C++ project:
-- stepping through a segfault beats adding printf and rebuilding.
return {
	"mfussenegger/nvim-dap",

	dependencies = {
		{ "rcarriga/nvim-dap-ui", dependencies = { "nvim-neotest/nvim-nio" } },
		"theHamsta/nvim-dap-virtual-text",
		"mfussenegger/nvim-dap-python",
	},

	keys = {
		{ "<leader>b", function() require("dap").toggle_breakpoint() end, desc = "Toggle breakpoint" },
		{
			"<leader>B",
			function()
				require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
			end,
			desc = "Conditional breakpoint",
		},
		{ "<F5>", function() require("dap").continue() end, desc = "Debug: continue" },
		{ "<F10>", function() require("dap").step_over() end, desc = "Debug: step over" },
		{ "<F11>", function() require("dap").step_into() end, desc = "Debug: step into" },
		{ "<F12>", function() require("dap").step_out() end, desc = "Debug: step out" },
		{ "<leader>du", function() require("dapui").toggle() end, desc = "Debug: toggle UI" },
		{ "<leader>dr", function() require("dap").repl.toggle() end, desc = "Debug: REPL" },
		{ "<leader>dt", function() require("dap").terminate() end, desc = "Debug: terminate" },
	},

	config = function()
		local dap = require("dap")
		local dapui = require("dapui")

		dapui.setup()
		require("nvim-dap-virtual-text").setup({})

		-- Open the UI with the session and close it when the session ends, so
		-- there is no separate thing to remember to toggle.
		dap.listeners.after.event_initialized["dapui_config"] = function()
			dapui.open()
		end
		dap.listeners.before.event_terminated["dapui_config"] = function()
			dapui.close()
		end
		dap.listeners.before.event_exited["dapui_config"] = function()
			dapui.close()
		end

		-- gdb speaks DAP directly since gdb 14. The older setups that route
		-- through cpptools or a wrapper script are no longer necessary.
		dap.adapters.gdb = {
			type = "executable",
			command = "gdb",
			args = { "--interpreter=dap", "--eval-command", "set print pretty on" },
		}

		local c_config = {
			{
				name = "Launch",
				type = "gdb",
				request = "launch",
				-- Asks for the binary rather than guessing it. A guess is
				-- wrong often enough that the prompt is faster overall.
				program = function()
					return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
				end,
				cwd = "${workspaceFolder}",
				stopAtBeginningOfMainSubprogram = false,
			},
		}
		dap.configurations.c = c_config
		dap.configurations.cpp = c_config

		-- debugpy. Passing the interpreter explicitly stops it from picking up
		-- whichever python happens to be first on PATH inside a virtualenv.
		require("dap-python").setup(vim.fn.exepath("python3"))

		-- Breakpoint signs, in the palette mini.hues generated.
		vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DiagnosticError" })
		vim.fn.sign_define("DapBreakpointCondition", { text = "◆", texthl = "DiagnosticWarn" })
		vim.fn.sign_define("DapStopped", { text = "▶", texthl = "DiagnosticOk", linehl = "Visual" })
	end,
}
```

- [x] **Step 5: Install and run the test**

Run: `cd ~/.config/nvim && nvim --headless "+Lazy! sync" +qa`
Run: `cd ~/.config/nvim && tests/nvim-test tests/dap.lua -c 'Lazy! load all'`
Expected: PASS.

- [x] **Step 6: Verify a real debug session**

A headless test cannot step through a program.

```bash
mkdir -p /tmp/dap-check && cd /tmp/dap-check
printf '#include <stdio.h>\nint add(int a, int b) { return a + b; }\nint main(void) {\n  int r = add(2, 3);\n  printf("%%d\\n", r);\n  return 0;\n}\n' > main.c
gcc -g -O0 -o main main.c
nvim main.c
```

Inside Neovim: put the cursor on the `int r = add(2, 3);` line and press `<leader>b`. A red `●` appears in the sign column. Press `<F5>`, and at the prompt accept `/tmp/dap-check/main`. Expected: the debug UI opens, execution stops on that line with a `▶` marker, and the variables pane lists `r`. Press `<F11>` to step into `add` and confirm `a` and `b` show 2 and 3. Press `<leader>dt` to terminate; the UI closes on its own. Then `:q!` and `rm -rf /tmp/dap-check`.

- [x] **Step 7: Add to the runner, run the suite, commit**

Modify `tests/run.sh` `for` line to include `tests/dap.lua`.

```bash
cd ~/.config/nvim && tests/run.sh; echo "exit=$?"
git add lua/plugins/dap.lua tests/dap.lua tests/run.sh
git commit -m "feat: debugging for C, C++ and Python

The largest gap between the previous config and an IDE. gdb speaks DAP
directly since gdb 14, so no cpptools and no wrapper script. The UI opens
and closes with the session rather than being a separate toggle."
```

---

### Task 11: Test runner

**Files:**
- Create: `lua/plugins/neotest.lua`
- Test: `tests/neotest.lua`
- Modify: `tests/run.sh`

**Interfaces:**
- Consumes: `nvim-nio`, already installed as a dap-ui dependency in Task 10.
- Produces: `<leader>T` keymaps.

- [x] **Step 1: Write the failing test**

Create `tests/neotest.lua`:

```lua
local t = require("testkit")

t.run(function()
	local neotest = require("neotest")
	t.truthy("neotest loaded", neotest ~= nil)
	t.truthy("neotest.run exists", type(neotest.run.run) == "function")

	-- Adapters this config registers.
	local config = require("neotest.config")
	t.truthy("at least one adapter", #config.adapters > 0)

	for _, k in ipairs({ "<leader>Tt", "<leader>Tf", "<leader>Ts", "<leader>To", "<leader>Td" }) do
		local m = vim.fn.maparg(k, "n", false, true)
		t.truthy(k .. " is mapped", m.callback ~= nil or m.rhs ~= nil)
	end
end)
```

- [x] **Step 2: Run test to verify it fails**

Run: `cd ~/.config/nvim && tests/nvim-test tests/neotest.lua -c 'Lazy! load all'`
Expected: FAIL with an error requiring `neotest`.

- [x] **Step 3: Write the implementation**

Create `lua/plugins/neotest.lua`:

```lua
-- Running tests from the editor.
--
-- <leader>T, capitalised, because <leader>t is the terminal prefix and a
-- lowercase collision would make both wait for a timeout.
return {
	"nvim-neotest/neotest",

	dependencies = {
		"nvim-neotest/nvim-nio",
		"nvim-lua/plenary.nvim",
		"nvim-treesitter/nvim-treesitter",
		"nvim-neotest/neotest-python",
	},

	keys = {
		{ "<leader>Tt", function() require("neotest").run.run() end, desc = "Test nearest" },
		{ "<leader>Tf", function() require("neotest").run.run(vim.fn.expand("%")) end, desc = "Test file" },
		{ "<leader>Ts", function() require("neotest").summary.toggle() end, desc = "Test summary" },
		{ "<leader>To", function() require("neotest").output.open({ enter = true }) end, desc = "Test output" },
		{
			"<leader>Td",
			function()
				require("neotest").run.run({ strategy = "dap" })
			end,
			desc = "Debug nearest test",
		},
	},

	config = function()
		require("neotest").setup({
			adapters = {
				-- pytest and unittest. The runner is discovered from the
				-- project rather than named here.
				require("neotest-python")({ dap = { justMyCode = false } }),
			},
			-- Diagnostics from failing tests appear inline, in the same
			-- virtual_lines style lua/lsp.lua configures for the servers.
			diagnostic = { enabled = true },
			output = { open_on_run = false },
		})
	end,
}
```

For C++ with Google Test, add `"alfaix/neotest-gtest"` to `dependencies` and `require("neotest-gtest").setup({})` to the adapters list. Skip it if the capstone does not use Google Test; an adapter for a framework you do not use is a plugin that only costs startup.

- [x] **Step 4: Install, run the test**

Run: `cd ~/.config/nvim && nvim --headless "+Lazy! sync" +qa`
Run: `cd ~/.config/nvim && tests/nvim-test tests/neotest.lua -c 'Lazy! load all'`
Expected: PASS.

- [x] **Step 5: Verify against a real test file**

```bash
mkdir -p /tmp/nt-check && cd /tmp/nt-check
printf 'def add(a, b):\n    return a + b\n' > calc.py
printf 'from calc import add\n\ndef test_add():\n    assert add(2, 3) == 5\n\ndef test_broken():\n    assert add(2, 2) == 5\n' > test_calc.py
python3 -m pip install --user pytest
nvim test_calc.py
```

Inside Neovim: put the cursor inside `test_add` and press `<leader>Tt`. Expected: a pass marker appears in the sign column. Move to `test_broken`, press `<leader>Tt`, and expect a fail marker plus an inline diagnostic. Press `<leader>Ts` for the summary panel. Then `:q!` and `rm -rf /tmp/nt-check`.

- [x] **Step 6: Add to the runner, run the suite, commit**

Modify `tests/run.sh` `for` line to include `tests/neotest.lua`.

```bash
cd ~/.config/nvim && tests/run.sh; echo "exit=$?"
git add lua/plugins/neotest.lua tests/neotest.lua tests/run.sh
git commit -m "feat: run tests from the editor

Under <leader>T rather than <leader>t, which is the terminal prefix. The dap
strategy reuses the debugger from the previous task, so a failing test can be
stepped through rather than only read."
```

---

### Task 12: Documentation

**Files:**
- Create: `README.md`
- Test: manual read-through

- [x] **Step 1: Write the README**

Document, in this order: requirements with the exact tool list, install steps, the file layout table from this plan, every keymap grouped by prefix, the mini/snacks ownership split and why it must not be crossed, the LaTeX and markdown behaviour including the code-block gating, and a Gotchas section carrying forward:

- `compile_commands.json` is what makes clangd work; without it every third header resolves to nothing.
- `<D-l>` works only in Ghostty and GUI Neovim; `<leader>l` is the fallback.
- Terminals are per directory, because snacks keys them by cwd.
- Call `Snacks.terminal.focus`, never `toggle`, and why.
- `lazy-lock.json` is untracked, so a fresh clone gets current releases.
- The previous config is at `~/.config/bak-nvim`; reach it with `NVIM_APPNAME=bak-nvim`.

- [x] **Step 2: Run the full suite one last time**

Run: `cd ~/.config/nvim && tests/run.sh; echo "exit=$?"`
Expected: every test `PASS`, `exit=0`.

- [x] **Step 3: Commit**

```bash
cd ~/.config/nvim
git add README.md
git commit -m "docs: README"
```

---

## Verification Checklist

Run after every task, not only at the end:

```bash
cd ~/.config/nvim && tests/run.sh; echo "exit=$?"
```

A task is not done until that prints `exit=0`.

The manual checks in Tasks 3, 4, 5, 9, 10 and 11 cannot be automated, because they need a real key press, a real mouse click or a real debug session. Do not skip them. Every bug found in the previous session — the terminal focus bug, the snippets firing inside code blocks, prettier timing out on save — was a thing the headless tests passed and a human would have noticed in ten seconds.
