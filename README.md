# nvim

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
| `lua/plugins/ui/` | catppuccin, lualine, noice |
| `lua/plugins/completion/` | LSP and blink.cmp, conform and nvim-lint, treesitter |
| `lua/plugins/utils/` | telescope, mini.nvim, autosave, flash, scrollEOF |
| `lua/config/binds.lua` | Every keybind, with the exceptions noted below |
| `lua/config/autocmd.lua` | Git remote check, cursorline focus, autosave messages |
| `lua/pokedash.lua` | Start screen |
| `lsp/` | One file per language server |
| `art/charizard-shiny` | The sprite |

Each file under `lua/plugins/` calls `vim.pack.add` itself and then configures
what it added. To add a plugin, add a file. The loader finds it.

## Language servers

`lsp/<name>.lua` holds a server's settings. `lua/plugins/completion/lspconfig.lua`
lists which of them start. Four are enabled: `lua_ls`, `clangd`, `pyright` and
`ruff`.

Install the server binary yourself. Neovim does not.

## Formatting

conform formats on save. stylua for Lua, clang-format for C and C++,
ruff for Python, prettier for the rest.

## Keybinds

The leader key is space. The local leader is comma. All default Vim bindings
are untouched.

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
five buttons, each on its key. The sprite is 24-bit ANSI art. `pokedash.lua`
parses the escape codes and paints one highlight group per colour pair, which
is why the start screen is a module here and not a plugin.
