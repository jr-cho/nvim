# nvim config

Neovim 0.12 with native LSP, completion, treesitter and `vim.pack`. Two
plugins: Snacks (folke/snacks.nvim) for the picker, terminal, lazygit, bigfile
and the JERICHO dashboard, and which-key (folke/which-key.nvim), which pops up
after `<leader>` and waits for the next key. Colors come from the local `chadone` theme (NvChad
onedark port). Plain Vim feel: no sidebar, tabline or bufferline; files are
browsed with netrw.

## Requirements

- Neovim 0.12 (plugin installs itself on first start).
- Language tools in `~/.local/share/nvim/mason/bin` (init.lua puts it on PATH):
  clangd, lua-language-server, bash-language-server, neocmakelsp, ty, ruff,
  stylua, shfmt, clang-format, tree-sitter CLI.
- `texlab` in `~/.local/bin`.
- `pi`: `npm i -g --prefix ~/.local @mariozechner/pi-coding-agent`. System node
  18 is too old, so `~/.local/bin/pi` is a wrapper that uses node 22 from
  `~/.local/share/pi-node`.
- `rg`, `fd`, `lazygit`, `latexmk`.

## Layout

    init.lua                 leader, PATH, vim.pack (Snacks), requires, colorscheme
    lua/config/options.lua   options, netrw, native completion, statusline
    lua/config/snacks.lua    Snacks setup and dashboard
    lua/config/lsp.lua       diagnostics, vim.lsp.enable, completion, inlay hints
    lua/config/format.lua    format on save, :FormatToggle
    lua/config/autocmds.lua  yank highlight, treesitter, checktime, makeprg
    lua/config/keymaps.lua   all keymaps
    lua/config/pi.lua        pi terminal toggle and send
    lsp/<name>.lua           one full server config per file
    colors/chadone.lua       theme, palette in lua/chadone/palette.lua

## Keymaps

Leader is Space.

| Key | Action |
| --- | --- |
| `<leader><leader>` | smart picker |
| `<leader>ff` `fg` `fw` | files, grep, grep word (n, x) |
| `<leader>fr` `fp` `fG` `fs` | recent, projects, git files, git status |
| `<leader>fh` `fk` `fc` | help, keymaps, config files |
| `<leader>fl` `fL` | LSP symbols, workspace symbols |
| `<leader>b` `d` `p` | buffers, diagnostics, commands |
| `<leader>Gl` | git log |
| `gd` `grr` `gri` `grt` | definitions, references, implementations, type definitions (pickers) |
| `-` | netrw in current window (inside netrw: up a directory) |
| `<leader>e` | toggle netrw: open it, or go back to the file you came from |
| `<leader>g` | lazygit |
| `<leader>t` `<C-`>` `<C-@>` | terminal (`<C-`>` also in terminal mode) |
| `<leader>x` | close buffer |
| `<Tab>` `<S-Tab>` | next, previous buffer |
| `<leader>la` | code action (n, x) |
| `<leader>lr` | rename |
| `<leader>lf` | format (n, x) |
| `<leader>li` | LSP health |
| `<leader>ls` | switch source/header (clangd) |
| `<leader>cb` | `:make` |
| `<leader>cr` | run: python3 (uv run with pyproject.toml), else prompt, remembered |
| `<leader>uf` | toggle format on save |
| `<leader>uw` `uh` `ud` | toggle wrap, inlay hints, diagnostics |
| `<leader>a` | toggle pi (right split) |
| `<leader>A` | send file reference to pi (n, x) |
| `<C-s>` | save (n, i, v) |
| `<Esc>` | clear search highlight |
| `<Esc><Esc>` | terminal normal mode (t) |
| `<` `>` | indent and keep selection (v) |
| `<C-h>` `<C-j>` `<C-k>` `<C-l>` | move between windows |
| `<A-h>` `<A-j>` `<A-k>` `<A-l>` | move between windows from terminal |

## LaTeX

texlab builds with latexmk on every save (`-pdf -interaction=nonstopmode
-synctex=1`). Errors show up as diagnostics (`<leader>d`). `:make` or
`<leader>cb` also runs latexmk. There is no viewer: the PDF is next to the
`.tex` file.

## pi

`<leader>a` toggles pi in a right split. `<leader>A` types `@file` into pi, or
`@file (lines A-B)` from a visual selection, and focuses it. Buffers reload
automatically when pi changes files (`checktime` on focus and buffer enter).

## Formatting

On save: stylua for lua (4 spaces unless a stylua.toml exists), shfmt for
sh/bash, clang-format for c/cpp (.clang-format if present, else LLVM with 4
spaces). Other filetypes use LSP formatting if a server supports it (ruff).
`:FormatToggle` disables it globally, `:FormatToggle!` for the buffer.

## Debugging

C/C++: `:packadd termdebug`, then `:Termdebug`. Python: put `breakpoint()` in
the code and run it in a terminal (`<leader>cr`).

## Add an LSP server

Create `lsp/<name>.lua` returning `cmd`, `filetypes`, `root_markers` and any
`settings`, then add `"<name>"` to the `vim.lsp.enable` list in
`lua/config/lsp.lua`.

## Add a treesitter parser

The tree-sitter CLI in `mason/bin` builds parsers into
`~/.local/share/nvim/site/parser` and queries into
`~/.local/share/nvim/site/queries`. Highlighting starts automatically per
filetype. If the filetype and parser names differ, register an alias with
`vim.treesitter.language.register` in `lua/config/autocmds.lua` (already done
for tex/plaintex to latex, sh to bash, gitrebase to git_rebase).
