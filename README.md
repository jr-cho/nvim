# nvim

```bash
git clone https://github.com/jr-cho/nvim.git ~/.config/nvim
```

A Neovim config built on [voidarc/nvim](https://git.voidarc.co.uk/voidarc/nvim),
with a start screen that draws a shiny Charizard.

Neovim 0.12 or later. Plugins are managed by `vim.pack`, which ships with
Neovim, so there is nothing to bootstrap: start `nvim` and it clones what it
needs on the first run.

## Layout

| Path | Holds |
| --- | --- |
| `init.lua` | Leader keys, options, colourscheme, undotree, start screen |
| `lua/plugins/init.lua` | Loader. Requires every `.lua` file under `lua/plugins/` |
| `lua/plugins/ui/` | catppuccin, lualine, noice, which-key |
| `lua/plugins/completion/` | LSP and blink.cmp, LuaSnip, conform and nvim-lint, treesitter |
| `lua/plugins/utils/` | telescope, mini.nvim, vimtex, claudecode, autosave, flash, scrollEOF |
| `lua/config/binds.lua` | Every keybind, with the exceptions noted below |
| `lua/config/autocmd.lua` | Git remote check, cursorline focus, autosave messages |
| `lua/keygroups.lua` | What each key prefix is called |
| `lua/cheatsheet.lua` | The cheatsheet |
| `lua/pokedash.lua` | Start screen |
| `lsp/` | One file per language server |
| `snippets/tex.lua` | LaTeX and maths snippets |
| `lua/util/tex.lua` | Is the cursor in maths? |
| `after/ftplugin/tex.lua` | LaTeX buffer settings and compile keys |
| `art/charizard-shiny` | The sprite |

Each file under `lua/plugins/` calls `vim.pack.add` itself and then configures
what it added. To add a plugin, add a file. The loader finds it.

## Language servers

`lsp/<name>.lua` holds a server's settings. `lua/plugins/completion/lspconfig.lua`
lists which of them start. Five are enabled: `lua_ls`, `clangd`, `pyright`,
`ruff` and `ltex_plus`, which checks grammar in LaTeX and Markdown prose.

Install the server binary yourself. Neovim does not.

## Formatting

conform formats on save. stylua for Lua, clang-format for C and C++, ruff for
Python, tex-fmt for LaTeX.

tex-fmt takes its indent from the buffer, and `after/ftplugin/tex.lua` sets a
LaTeX buffer to two spaces. The global default is a hard tab, so without that
ftplugin every save would rewrite the indentation of every line touched.

## LaTeX

vimtex compiles with latexmk into `build/`, and views in Skim with forward and
inverse search. Treesitter owns highlighting, so vimtex's own syntax engine is
off.

- `<leader>cc` - Compile, toggling continuous mode
- `<leader>cv` - View the PDF in Skim
- `<leader>ck` - Stop compiling
- `<leader>ce` - Errors
- `<leader>ct` - Table of contents
- `<leader>cl` - Clean the build directory
- `<leader>cs` - Compiler status

vimtex's own `<localleader>l` set is untouched and remains the full set. The
local leader is comma.

`snippets/tex.lua` holds the maths snippets. Most expand the instant the
trigger is typed, with no menu and no confirm key, which works because each
one is gated on where the cursor is: `mk` opens maths and fires in text, `//`
builds a fraction and fires in maths. `lua/util/tex.lua` answers that from the
treesitter parse tree, so the same snippets work inside `$...$` in a Markdown
note. `:SnipReload` reloads the file without restarting.

No trigger may be a prefix of another one. Autosnippets fire on the keystroke
that completes a trigger, so `;p` and `;ph` together would expand `;p` and
leave the `h` after it.

## Claude Code

claudecode.nvim opens a WebSocket server and writes a lock file under
`~/.claude/ide/`. The `claude` CLI finds that file and connects, which is the
same protocol the VS Code extension speaks. Claude then sees the current
selection, opens files here, and shows its edits as diffs to accept or deny.

The server starts with Neovim, so a `claude` started in any terminal finds
this editor. `auto_start = false` in `lua/plugins/utils/claudecode.lua` turns
that off, and `:ClaudeCodeStart` then starts it by hand.

- `<leader>ac` - Toggle Claude
- `<leader>af` - Focus Claude
- `<leader>ar` - Resume a session
- `<leader>aC` - Continue the last session
- `<leader>am` - Select the model
- `<leader>ab` - Add this buffer
- `<leader>as` - Send the selection, in visual mode
- `<leader>aa` / `<leader>ad` - Accept or deny a proposed diff
- `<A-a>` - Hide Claude from inside its terminal

The Claude window is Neovim's own terminal in a split on the right. The
previous config used a snacks terminal, and snacks is not in this one.

## Keybinds

The leader key is space. The local leader is comma. All default Vim bindings
are untouched.

Pause for 250ms on a prefix and which-key shows what follows it. Press
`<leader>?`, or `c` on the start screen, for the cheatsheet: every mapping
that carries a description, in one screen. `q` or `<Esc>` closes it.

which-key and the cheatsheet name their prefixes from the same list, in
`lua/keygroups.lua`. A new group is added there once.

### Files

- `<leader>ff` - Find files
- `<leader>fg` - Live grep
- `<leader>fb` - Open buffers
- `<leader>fn` - File browser, rooted at the current file's directory
- `<leader>bd` - Delete the current buffer

Telescope jumps to the window already showing a file rather than opening a
second copy of it. `<C-t>` on a Telescope result opens the file in a new tab.
`<C-v>` opens it in a vertical split.

### Tabs

- `<C-t>l` - Next tab
- `<C-t>h` - Previous tab
- `<C-t>j` - New tab
- `<C-t>q` - Close tab, keeping its buffers open

### Editing

- `gd` - Go to definition
- `<leader>d` - Diagnostic float
- `<leader>u` - Toggle undotree
- `ss` - Flash jump
- `S` - Flash treesitter
- `<leader>r` - Flash remote
- `<leader>R` - Flash treesitter search

### Terminal

- `<leader>tj` - Terminal in a vertical split
- `<leader>tk` - Terminal in a new tab
- `<C-d>` - Leave terminal mode

### Sessions

- `<leader>qj` - Write the session, then `wqa`
- `<leader>qd` - Delete the session, then `wqa`
- `<leader>fs` - Pick a session
- `<leader>fd` - Delete a session

Sessions are per directory, stored in a `.session` file, and read back
automatically when you open Neovim in that directory.

## Start screen

`nvim` with no file argument opens the start screen: the Charizard sprite and
six buttons, each on its key. The sprite is 24-bit ANSI art. `pokedash.lua`
parses the escape codes and paints one highlight group per colour pair, which
is why the start screen is a module here and not a plugin.
