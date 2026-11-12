# Neovim IDE config

A VS Code-style Neovim setup: persistent file explorer, bottom panel (terminals, problems, build output, debug console), documentation panel, LSP, completion, formatting, git and debugging for C/C++, Python, Lua, Bash and CMake. Built on lazy.nvim and Snacks.nvim. The colorscheme is `chadone`, a local port of NvChad's onedark.

Contents: [Install](#install) | [Plugins](#plugins) | [Structure](#structure) | [Keymaps](#keymaps) | [Adding a language](#adding-a-language) | [Customizing the UI](#customizing-the-ui) | [Persistent Explorer](#how-the-persistent-explorer-works) | [Troubleshooting](#troubleshooting) | [Known gaps](#known-gaps)

## Install

Requirements:

| Needed | Why |
|---|---|
| Neovim >= 0.12 | `vim.lsp.config`/`vim.lsp.enable`, native treesitter folds |
| A Nerd Font set as the terminal font | all icons are Nerd Font codicons |
| `git` | lazy.nvim bootstrap, gitsigns |
| `ripgrep` (`rg`), `fd` | Snacks pickers (grep, files) |
| `lazygit` | `<leader>g` |
| `gcc`, `cmake`, `make` | C/C++ builds, treesitter parser compilation |
| `gdb` >= 14 | C/C++ debugging (uses gdb's built-in DAP, `gdb --interpreter=dap`) |
| `python3` | Python tooling, debugpy |
| `node`/`npm` | some Mason packages (for example bashls) |
| `uv` (optional) | `:Build`/`:Run`/`:Test` for projects with `pyproject.toml` |
| `tree-sitter` CLI | parser compilation; Mason installs it into `~/.local/share/nvim/mason/bin`, which the config adds to `PATH` |

```sh
git clone <this repo> ~/.config/nvim
nvim
```

On first launch lazy.nvim installs the plugins, mason-lspconfig installs the language servers, a Mason registry loop installs the extra tools, treesitter compiles the parsers (async), and blink.cmp downloads its prebuilt fuzzy-matcher binary. Wait for it to finish, then restart once. `lazy-lock.json` pins plugin versions; `:Lazy restore` reinstalls exactly those.

Mason-installed packages:

| Kind | Packages |
|---|---|
| Language servers (`mason-lspconfig` `ensure_installed`) | clangd, lua_ls (lua-language-server), bashls (bash-language-server), neocmake, ty, ruff |
| Tools (`ensure_tools` loop in `lua/plugins/lsp.lua`) | clang-format, stylua, shfmt, shellcheck, debugpy |

`automatic_enable` is on, so every installed server is enabled with `vim.lsp.enable`. `stylua` is excluded because Mason's stylua package would otherwise register a duplicate stylua LSP; conform runs stylua instead.

Treesitter parsers installed: c, cpp, python, bash, lua, luadoc, cmake, make, json, yaml, toml, markdown, markdown_inline, vim, vimdoc, query, regex, diff, gitcommit, git_rebase.

## Plugins

Every entry of `lazy-lock.json`:

| Plugin | Purpose |
|---|---|
| lazy.nvim | plugin manager (bootstrapped by `lua/config/lazy.lua`) |
| snacks.nvim | dashboard, explorer, pickers, lazygit, terminal helper, notifier, input, zen, toggles, indent guides, statuscolumn, image, words, scope, bigfile, quickfile |
| nvim-web-devicons | file-type icons for bufferline, lualine, Snacks |
| bufferline.nvim | buffer tabs at the top (closing uses `Snacks.bufdelete`) |
| lualine.nvim | global statusline: mode, branch, diff, diagnostics, filename, LSP clients, formatter, encoding, line ending, filetype, progress, `Ln, Col` |
| dropbar.nvim | breadcrumb winbar for file windows (skipped in IDE windows) |
| which-key.nvim | key hint popup; groups for find, lsp, build, debug, git, toggles |
| nvim-lspconfig | default server definitions (`cmd`, `filetypes`, `root_markers`) |
| mason.nvim | installer for servers and tools |
| mason-lspconfig.nvim | `ensure_installed` for servers and `automatic_enable` |
| lazydev.nvim | Lua/Neovim API library for lua_ls and blink.cmp (`ft = lua`) |
| blink.cmp | completion (LSP, path, snippets, buffer, lazydev) plus signature help and cmdline completion |
| friendly-snippets | snippet collection for blink.cmp |
| nvim-treesitter | `main` branch; parser installation, highlight, indent, fold expressions |
| conform.nvim | formatting and format on save, LSP fallback |
| gitsigns.nvim | gutter signs, hunk actions, blame |
| nvim-dap | debug adapter client |
| nvim-dap-ui | right-hand debug sidebar (scopes, breakpoints, stacks, watches) |
| nvim-nio | async library required by nvim-dap-ui |
| nvim-dap-virtual-text | variable values shown inline while debugging |
| mason-nvim-dap.nvim | Mason integration for DAP (declared as a dependency, no extra config) |
| nvim-dap-python | Python debug configurations via debugpy |

## Structure

```
init.lua                    leaders, then config.options, config.lazy, config.autocmds, config.keymaps, ide.build
colors/chadone.lua          colorscheme; all highlight groups, reads lua/chadone/palette.lua
lua/chadone/palette.lua     base_30 / base_16 color tables (single source of colors)
lua/chadone/lualine.lua     lualine theme built from the palette
lua/config/options.lua      vim options (4-space indent, treesitter folds, mouse, clipboard, ...)
lua/config/lazy.lua         lazy.nvim bootstrap; spec = every file in lua/plugins/
lua/config/autocmds.lua     yank highlight, restore cursor, `q` closes help-like windows, relayout on resize
lua/config/keymaps.lua      all global keymaps
lua/plugins/snacks.lua      Snacks setup (dashboard, explorer, picker, ...), calls ide.layout.setup()
lua/plugins/ui.lua          bufferline, lualine, dropbar, which-key
lua/plugins/lsp.lua         mason, mason-lspconfig, diagnostics config, lazydev, extra tool installs
lua/plugins/completion.lua  blink.cmp + friendly-snippets
lua/plugins/treesitter.lua  parser list, highlight/indent autocmd
lua/plugins/format.lua      conform formatters_by_ft, format on save, :FormatToggle
lua/plugins/git.lua         gitsigns, ]h / [h
lua/plugins/dap.lua         nvim-dap, dap-ui, adapters (gdb, debugpy), <leader>D keys
lua/ide/layout.lua          workspace: startup, window-order enforcer (fix), quit handling, explorer API
lua/ide/panel.lua           bottom panel: TERMINAL | PROBLEMS | OUTPUT | DEBUG CONSOLE
lua/ide/docpanel.lua        right documentation panel (LSP hover + signature help)
lua/ide/build.lua           :Build :Run :Test :CMakeConfigure :CMakeBuild :BuildClean
lua/ide/icons.lua           all icons, as \u{XXXX} escapes
lsp/clangd.lua              clangd flags
lsp/lua_ls.lua              lua_ls settings
lsp/ruff.lua                ruff log level
lsp/ty.lua                  ty (empty, lspconfig defaults)
lazy-lock.json              pinned plugin commits
LICENSE-base46              license for the ported theme
```

## Keymaps

Leader is `<Space>`. Convention: no F-keys; everything is reached through which-key groups under the leader. Press `<Space>` and wait for which-key to list the groups. Plugin-provided maps (explorer, pickers) are listed separately below.

### Global

| Key | Mode | Action |
|---|---|---|
| `<leader><leader>` | n | Find files (smart) |
| `<leader>e` | n | Explorer, VS Code style: closed -> open and focus the list; open but unfocused -> focus the list; focused -> close |
| `<leader>b` | n | Buffer picker |
| `<leader>g` | n | Lazygit |
| `<leader>d` | n | Diagnostics picker |
| `<leader>p` | n | Commands picker |
| `<leader>z` | n | Zen mode |
| `<leader>h` | n | Toggle documentation panel |
| `<leader>t` | n | Toggle bottom panel |
| `<C-\`>`, `<C-@>` | n, t | Toggle bottom panel (terminals often send `<C-@>` for Ctrl-backtick) |
| `<leader>o` | n | Open panel on PROBLEMS |
| `<C-s>` | n, i, v | Save |
| `<Esc>` | n | Clear search highlight |
| `<Esc><Esc>` | t | Leave terminal mode |
| `<` / `>` | v | Indent and keep selection |

### Find (`<leader>f`)

| Key | Action |
|---|---|
| `<leader>ff` | Files |
| `<leader>fg` | Live grep |
| `<leader>fw` | Grep word under cursor / selection (n, x) |
| `<leader>fr` | Recent files |
| `<leader>fp` | Projects (confirming `tcd`s into it and the explorer re-roots) |
| `<leader>fG` | Git files |
| `<leader>fs` | Git status |
| `<leader>fh` | Help |
| `<leader>fk` | Keymaps |
| `<leader>fl` | Document symbols |
| `<leader>fL` | Workspace symbols |
| `<leader>fc` | Files in the Neovim config directory |

### LSP

| Key | Action |
|---|---|
| `gd` | Definitions (picker) |
| `grr` | References (picker) |
| `gri` / `gI` | Implementations (picker) |
| `grt` / `gy` | Type definitions (picker) |

There is no bare `gr` map, so the built-in `grn` (rename), `gra` (code action) and `grx` work without a delay.
| `K` | Native hover (Neovim default) |
| `<leader>la` | Code action (n, x) |
| `<leader>lr` | Rename |
| `<leader>lf` | Format (conform, LSP fallback; n, x) |
| `<leader>ls` | Switch source/header (clangd only) |
| `<leader>li` | `:checkhealth vim.lsp` |

Neovim's built-in defaults still apply (`grn`, `gra`, `grr`, `[d`, `]d`, `<C-w>d`, and so on).

### Build (`<leader>c`)

| Key | Command |
|---|---|
| `<leader>cb` | `:Build` |
| `<leader>cr` | `:Run` |
| `<leader>ct` | `:Test` |
| `<leader>cc` | `:CMakeConfigure` |

Other commands: `:CMakeConfigure [preset|build_type]`, `:CMakeBuild`, `:BuildClean`. Project type is detected from the root (`CMakeLists.txt` = cmake, `Makefile` = make, `pyproject.toml` = uv).

- Every build command saves all modified buffers first (`:wall`).
- `:CMakeConfigure` restarts clangd afterwards, so stale "file not found" diagnostics clear without reopening files.
- Make `:Run` runs the only executable in the project root, or lets you pick when there are several; with none it asks for a make target.
- Python `:Build` runs `uv sync`, or `python3 -m py_compile` on the current file when uv is not installed.

### Debug (`<leader>D`)

There are no F-keys. Debugging lives under the which-key group `<leader>D`. `<leader>DD` starts a sticky debug mode: the which-key popup stays open (`loop = true`), so the keys below become single presses (`c`, `n`, `i`, `o`, `b`, ...). `<Esc>` leaves the mode.

| Key | Action |
|---|---|
| `<leader>DD` | Sticky debug mode |
| `<leader>Dc` | Continue / start session |
| `<leader>Dn` | Step over |
| `<leader>Di` | Step into |
| `<leader>Do` | Step out |
| `<leader>Db` | Toggle breakpoint |
| `<leader>DB` | Conditional breakpoint (prompts) |
| `<leader>Dt` | Terminate |
| `<leader>Dl` | Run last |
| `<leader>Du` | Toggle debug UI sidebar |
| `<leader>Dr` | Show DEBUG CONSOLE in the panel |

These are lazy-loaded: pressing any of them loads nvim-dap.

- The C/C++ "Launch" prompt defaults to the last program you ran (else `build/` or the cwd) and refuses anything that is not an executable file, so `<leader>Dl` usually needs only `<CR>`.
- "Attach to process" needs `ptrace_scope` 0. Ubuntu defaults to 1; the config shows an error with the fix (`echo 0 | sudo tee /proc/sys/kernel/yama/ptrace_scope`) instead of hanging.
- `<leader>Dt` also closes the debug sidebar when a session never started.
- The DEBUG CONSOLE has no auto-completion, so `<CR>` always submits what you typed.
- Variable values are shown at the end of the line (nvim-dap-virtual-text).
- `.vscode/launch.json` configurations appear in the `<leader>Dc` picker.

### Git

| Key | Action |
|---|---|
| `]h` / `[h` | Next / previous hunk (buffer-local, set by gitsigns) |
| `<leader>Gb` | Blame line (full) |
| `<leader>Gp` | Preview hunk |
| `<leader>Gs` | Stage hunk |
| `<leader>Gr` | Reset hunk |
| `<leader>Gd` | Diff this |
| `<leader>Gl` | Git log picker |
| `<leader>g` | Lazygit |

### Toggles (`<leader>u`)

| Key | Toggles |
|---|---|
| `<leader>uh` | Inlay hints |
| `<leader>uf` | Format on save (global) |
| `<leader>uw` | Line wrap |
| `<leader>ud` | Diagnostics |
| `<leader>un` | Relative line numbers |
| `<leader>uP` | Bottom panel |

Commands: `:FormatToggle` (global) and `:FormatToggle!` (current buffer only).

### Buffers and windows

| Key | Mode | Action |
|---|---|---|
| `<Tab>` / `<S-Tab>` | n | Next / previous buffer |
| `<leader>x` | n | Close buffer (`Snacks.bufdelete`; the window and explorer stay; no-op in panel, doc panel, explorer and other IDE windows) |
| `<C-h>` `<C-j>` `<C-k>` `<C-l>` | n | Move to the window left / down / up / right |
| `<A-h>` `<A-j>` `<A-k>` `<A-l>` | t | Same from a terminal (leaves terminal mode first); Ctrl-L / Ctrl-K / Ctrl-H stay with the shell |
| Click or right-click a bufferline tab | | Right-click closes the buffer |

### Explorer (focus the explorer first with `<leader>e`)

Local keys are Snacks.nvim defaults plus two overrides.

| Key | Action |
|---|---|
| `<CR>` / `l` | Open file / expand directory |
| `h` | Collapse directory |
| `<BS>` | Go up one directory |
| `.` | Focus (re-root) on the directory under the cursor |
| `a` / `d` / `r` / `c` / `m` | Add / delete / rename / copy / move |
| `y` / `p` | Yank / paste |
| `o` | Open with the system application |
| `P` | Toggle preview |
| `u` | Refresh |
| `H` / `I` | Toggle hidden / ignored files |
| `Z` | Collapse all directories |
| `<C-c>` | `tcd` into the directory |
| `<C-t>` | Open a terminal there |
| `]g` `[g` `]d` `[d` `]w` `[w` `]e` `[e` | Next / previous git change, diagnostic, warning, error |
| `q`, `<Esc>` | Close the explorer (override in `lua/plugins/snacks.lua`; also stops it re-opening automatically) |

The input box at the top of the explorer filters files.

### Bottom panel and terminals

Clickable winbar: ` TERMINAL [1] 2 + | PROBLEMS (n) | OUTPUT | DEBUG CONSOLE `. Clicking a tab switches section; `+` adds a terminal; clicking a numbered tab selects that terminal.

| Key | Where | Action |
|---|---|---|
| `<A-]>` / `<A-[>` | terminal buffers (n, t) | Next / previous terminal |
| `<A-n>` | terminal buffers (n, t) | New terminal |
| `<A-x>` | terminal buffers (n, t) | Kill terminal |
| `<CR>` | PROBLEMS | Jump to the item in the last editor window |
| `q` | PROBLEMS, OUTPUT | Close the panel |
| `<Esc><Esc>` | terminal | Normal mode, then `<C-k>` etc. to leave |

Terminals stay alive while the panel is hidden; a shell that exits is removed from the tab strip. The panel is 12 lines high by default and resizable with the mouse; the last height is remembered.

### Documentation panel

| Key | Action |
|---|---|
| `<leader>h` | Toggle |
| `<A-j>` / `<A-k>` | Scroll down / up (n, i; mapped only while the panel is open) |

Shows LSP hover and signature help for the cursor position of the last editor window, refreshed on `CursorHold`/`CursorHoldI`. Width is 50.

### Dashboard (shown with plain `nvim`)

Logo plus `f` find file, `n` new file, `g` find text, `q` quit. Recent files, projects and config are still one key away: `<leader>fr`, `<leader>fp`, `<leader>fc`.

### Completion (insert mode, blink.cmp "enter" preset)

`<CR>` accept, `<Tab>`/`<S-Tab>` jump snippet or select next/previous, `<C-space>` open menu, `<C-e>` hide, `<C-n>`/`<C-p>` or `<Up>`/`<Down>` select, `<C-k>` toggle signature help. On the `:` command line the completion menu appears as you type.

### Formatting defaults

Format on save uses the project's own config when it has one (`.clang-format`, `stylua.toml`, `pyproject.toml`/`ruff.toml`, `.editorconfig`). Without one, everything indents with 4 spaces: clang-format runs with `{BasedOnStyle: LLVM, IndentWidth: 4}` and stylua with `--indent-type Spaces --indent-width 4`. This config ships its own `.stylua.toml` (2 spaces).

## Adding a language

Worked example: **Rust** (rust-analyzer + rustfmt, debugged through gdb). Java follows the same four steps.

1. **LSP server.** Add the lspconfig server name to `servers` in `lua/plugins/lsp.lua`:
   ```lua
   local servers = { "clangd", "lua_ls", "bashls", "neocmake", "ty", "ruff", "rust_analyzer" }
   ```
   mason-lspconfig installs it and enables it automatically (`automatic_enable`). nvim-lspconfig already supplies `cmd`, `filetypes` and `root_markers`. For overrides create `lsp/rust_analyzer.lua` returning only what differs:
   ```lua
   return {
     settings = { ["rust-analyzer"] = { check = { command = "clippy" } } },
   }
   ```
   For Java use `jdtls` (Mason package `jdtls`); it needs Java 21+ at runtime.
2. **Formatter.** Add to `formatters_by_ft` in `lua/plugins/format.lua`, and the Mason package to `tools` in `ensure_tools` (`lua/plugins/lsp.lua`) if it is not a language-server binary:
   ```lua
   rust = { "rustfmt" },       -- rustfmt ships with rustup
   java = { "google-java-format" },  -- add "google-java-format" to ensure_tools
   ```
   Without an entry, conform falls back to the LSP formatter.
3. **Treesitter parser.** Add `"rust"` (or `"java"`) to the `parsers` list at the top of `lua/plugins/treesitter.lua`. It is compiled on next start; highlight, indent and folds are enabled by the existing `FileType` autocmd.
4. **Debug adapter.** Rust already works: `dap.configurations.rust` reuses the C configuration (gdb). Build with debug info (`cargo build`) and enter `target/debug/<name>` at the prompt. For another gdb-compatible language, assign `dap.configurations.<ft> = dap.configurations.c` in `lua/plugins/dap.lua`. For a language with its own adapter (Java: `java-debug-adapter` via Mason), define `dap.adapters.<name>` and `dap.configurations.<ft>` in the same `config` function. `.vscode/launch.json` files are also picked up by nvim-dap.
5. **Build tasks (optional).** `ide.build` detects only CMake, Make and `pyproject.toml` projects. Add a branch to `M.detect` and the matching build/run/test commands in `lua/ide/build.lua` to support `cargo` or `mvn`.

Check the result with `:checkhealth vim.lsp`, `:ConformInfo` and `:InspectTree`.

## Customizing the UI

- **Colors.** Edit `lua/chadone/palette.lua` (`base_30` UI colors, `base_16` syntax colors). `:colorscheme chadone` reloads it. Highlight group definitions live in `colors/chadone.lua`; the lualine theme in `lua/chadone/lualine.lua` is derived from the palette.
- **Ide\* highlight groups** (all in `colors/chadone.lua`): `IdePanelNormal`, `IdePanelTab`, `IdePanelTabActive`, `IdePanelTabSep`, `IdeDocNormal`, `IdeDocTitle`, `IdeSidebarNormal`, `IdeSidebarTitle`. The sidebar, panel and floats use `darker_black`; the editor uses `black`.
- **Widths and heights.** Explorer 30 columns: `EXPLORER_WIDTH` at the top of `lua/ide/layout.lua`. The explorer also sets `width = 30, min_width = 30` in `lua/plugins/snacks.lua` (`picker.sources.explorer.layout`); keep both in sync. Doc panel width: `WIDTH` in `lua/ide/docpanel.lua` (50). Panel height: `height` in the state table at the top of `lua/ide/panel.lua` (12). Bufferline's "EXPLORER" offset (in `lua/plugins/ui.lua`) follows the explorer width automatically.
- **Icons.** All icons are in `lua/ide/icons.lua`, grouped as `diagnostics`, `dap`, `git`, `misc`. **Write icons as `\u{XXXX}` escapes, never as pasted glyphs**: many editors, tools and AI assistants silently drop Private Use Area characters, which previously produced empty breakpoint signs (so breakpoints never registered). Find codepoints on nerdfonts.com/cheat-sheet (codicons are `cod-*`). Check that none is empty with:
  ```sh
  nvim --headless "+lua local function w(t,p) for k,v in pairs(t) do if type(v)=='table' then w(v,p..k..'.') else assert(#v>0,p..k) end end end w(require('ide.icons'),'') print('icons ok')" +qa
  ```

## How the persistent Explorer works

The Snacks explorer is a picker rendered inside a layout window. Left alone it would be an ordinary window that `:only`, a split, or a new panel could push around or close. `lua/ide/layout.lua` turns it into a fixed part of the workspace.

**Window roles.** Every IDE window carries `vim.w[win].ide_role`:

| Role | Window | Placement |
|---|---|---|
| `explorer` | Snacks layout box (filetype `snacks_layout_box`; tagged by `M.explorer_win()`) | far left, width 30, full height |
| `panel` | terminal / nofile buffers, `winfixheight` | bottom, under the editors and docpanel only |
| `docpanel` | nofile markdown, `winfixbuf`, `winfixwidth` | right of the editors, above the panel, width 50 |
| (none) | everything else | editors, in the middle |

Target window tree: `row[ explorer, col[ row[ editors..., docpanel ], panel ] ]`.

**`ide.layout.fix()`** is idempotent and re-entrancy guarded. It runs after anything that opens or closes an IDE window and on `WinNew`, `WinClosed` and `VimResized`. Order of operations:

1. Docpanel: if not last in the editor area, `wincmd L`, then restore its width.
2. Panel: if not at the bottom of the editor area, `wincmd J`, then restore its height.
3. Explorer: if not the first top-level window, `wincmd H`; force width 30 and `winfixwidth`.
4. If no editor window remains, create an empty one (above the panel if there is one, otherwise right of the explorer).
5. Restore the previously current window.

Snacks re-renders the explorer's floating parts on `WinResized` by itself, so the window moves above are all that is needed. Other modules never place windows themselves; they open and then call `fix()`.

**Startup.** The explorer is not opened automatically, except for a directory argument. Plain `nvim` shows the Snacks dashboard and `nvim file` shows just the file. `nvim .` / `nvim dir` does `cd dir`, drops the dashboard and opens the explorer (without focus) next to an empty editor. Press `<leader>e` to open it at any time; once opened it stays (see below).

**Re-open after `:only`.** `<C-w>o` / `:only` closes the explorer. A flag (`wanted`, false at startup, set when the explorer is opened) records that the explorer should be visible; the next `WinClosed`/`WinNew`/`VimResized` event reopens it. The flag is cleared by an explicit close (`<leader>e` toggle off, `q` or `<Esc>` in the explorer), so a deliberate close stays closed. The project-switch re-root (`DirChanged`) only happens while the explorer is open. Closing and reopening keeps expanded directories (Snacks keeps tree state per cwd).

**Quit handling.** On `QuitPre`, if the window being quit is the last editor window of the only tab, all IDE windows are closed first and panel terminals' jobs are stopped, so `:q`, `:wq` and `ZZ` quit Neovim instead of leaving the IDE windows behind. If the quit is cancelled (for example a modified buffer with `confirm`), the explorer and layout are rebuilt.

**DirChanged re-root.** On `DirChanged` (`:cd`, `:tcd`, picking a project), if the explorer's cwd differs from the new directory, it is closed and reopened rooted there, keeping focus in the editor.

## Troubleshooting

| Problem | Check |
|---|---|
| General | `:checkhealth` (look at lazy, mason, vim.lsp, vim.treesitter, blink.cmp, snacks) |
| Plugin missing or failing to load | `:Lazy`; `:Lazy restore` to return to the lockfile versions |
| Server or tool missing | `:Mason`; press `U` to update, `g?` for help |
| Server not attaching | `:checkhealth vim.lsp` (also `<leader>li`), `:lsp` shows enabled and attached servers |
| Formatter does nothing | `:ConformInfo`; check that the binary exists (`:Mason`) |
| clangd reports unknown includes/flags | It needs `compile_commands.json` in the project root. Run `:CMakeConfigure`; it configures with `CMAKE_EXPORT_COMPILE_COMMANDS=ON` and symlinks `build/compile_commands.json` to the root. For non-CMake projects use `bear -- make` or write a `compile_flags.txt`. |
| Treesitter parser errors | `:checkhealth vim.treesitter`; compilation needs a C compiler and the `tree-sitter` CLI (`:Mason`); `:TSUpdate` |
| Lazygit opens without the OneDark theme | A snap-packaged lazygit cannot read the theme file Snacks writes to `~/.cache`, so theming is skipped for it. Install the release binary into `~/.local/bin` instead. |
| Images do not render | Snacks image needs a terminal with the kitty graphics protocol: ghostty, kitty or wezterm. Elsewhere it is silently unavailable. |
| `<C-\`>` does nothing | Terminals often send `<C-@>` (also mapped) or nothing. Use `<leader>t`. |
| Breakpoints do not stop | Check the breakpoint sign is visible (broken icons, see [icons](#customizing-the-ui)); build with `-g` (`:CMakeConfigure Debug`); `gdb --version` must be >= 14. |
| Icons show as boxes | The terminal is not using a Nerd Font. |
| Layout looks wrong | `:lua require("ide.layout").fix()` |

## Known gaps

- Image preview was not exercised (it needs ghostty/kitty/wezterm; tests ran in tmux).
- Attaching the debugger to a running process requires lowering `ptrace_scope` (see Debug).
- The explorer shows a filter input box at the top (Snacks sidebar preset). This is kept deliberately as the file filter.
- Bash and CMake language servers attach (bash verified); cmake formatting has no formatter and falls back to the LSP.
- Only C/C++, Python, Lua, Bash and CMake are configured. Build tasks (`ide.build`) cover CMake, Make and uv/pyproject projects only.
- Dropbar breadcrumbs and the bufferline "EXPLORER" offset were checked in a real layout at one window size; other sizes and layouts with several splits are less tested.
