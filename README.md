# nvim-config

A Neovim configuration for C, C++, Python, Lua, LaTeX and markdown notes.

No framework. Two plugin suites divide the work: mini owns editing and
appearance, snacks owns workflow. Every layer ships with a headless test.

Leader is `Space`. Localleader is `\`.

## Requirements

Neovim 0.12.4 or later. Several features used here do not exist earlier,
including `vim.o.autocomplete`, `vim.lsp.config` and `vim.lsp.enable`.

Install the tools for the languages you use. Everything else still works when a
tool is absent. Neovim reports the missing tool and continues.

| Tool | Used for |
| --- | --- |
| `git` | Cloning this repository and lazy.nvim |
| A Nerd Font | Icons in the statusline, the explorer and the picker |
| `ripgrep` | The picker's grep, and find-and-replace |
| `clangd` | C and C++ language server |
| `pyright`, `ruff` | Python language servers |
| `lua-language-server` | Lua language server |
| `ltex-ls-plus` | Grammar checking in markdown and LaTeX. Needs a JDK |
| `stylua`, `clang-format`, `prettier`, `jq`, `shfmt` | Formatters, run through conform |
| `lazygit` | The `<leader>gg` git interface |
| MacTeX and Skim | LaTeX compiling and previewing, through vimtex |
| `lldb-dap` | Debugging C and C++. Ships with the Xcode command line tools |
| `debugpy` | Debugging Python |
| `pytest` | Running Python tests |
| `magick`, `dvipng` | Inline images and rendered maths in notes |

Nothing in this configuration installs tools. Install them with your own
package manager.

## Install

1. Back up any existing configuration. Run `mv ~/.config/nvim ~/.config/bak-nvim`.
2. Remove the old plugin state. Run `rm -rf ~/.local/share/nvim ~/.local/state/nvim ~/.cache/nvim`.
3. Clone this repository into `~/.config/nvim`.
4. Start Neovim. Run `nvim`.
5. Wait for lazy.nvim to install the plugins. The first start takes about a minute.
6. Quit and start Neovim again.
7. Make sure that `:checkhealth` reports no errors you care about.
8. Run `tests/run.sh`. Make sure that it prints `exit=0`.

## Layout

```
init.lua                     Leader keys, bootstrap, hand off to lazy. Three things.
lua/options.lua              Editor options. Reads no plugin.
lua/autocmds.lua             Autocommands, each in a named group.
lua/keymaps.lua              Keys that belong to no plugin.
lua/lsp.lua                  Diagnostics, the LSP keymap table, server enable.
lua/notes.lua                Find, grep and create notes.
lua/statusline.lua           Statusline and inactive-window content.
lua/keygroups.lua            What each key prefix is called.
lua/cheatsheet.lua           The <leader>? cheatsheet.
lua/testkit.lua              Assertion helpers for the headless tests.
lua/util/tex.lua             Reads the parse tree to test for maths and for code.
lsp/<server>.lua             One file per language server. vim.lsp.config reads these.
lua/plugins/<area>.lua       One lazy spec per capability.
after/ftplugin/tex.lua       LaTeX buffer settings. Runs after vimtex's own ftplugin.
after/ftplugin/markdown.lua  Markdown buffer settings. Spell, indent, checkbox toggle.
snippets/tex.lua             LuaSnip snippets, shared by tex and markdown.
art/                         Start-screen sprites, as 24-bit ANSI half-blocks.
ltex/                        Words you added to the grammar checker.
tests/                       One test file per layer. See "Tests" below.
```

## Plugins

| Plugin | Purpose |
| --- | --- |
| `folke/lazy.nvim` | Plugin manager |
| `echasnovski/mini.nvim` | Editing verbs, colours, statusline, tabline, icons, git signs |
| `folke/snacks.nvim` | Picker, explorer, terminal, images, notifications |
| `folke/which-key.nvim` | Shows what follows a prefix, at the bottom of the screen |
| `nvim-treesitter/nvim-treesitter` | Parsers and highlighting |
| `nvim-treesitter/nvim-treesitter-textobjects` | Textobject queries |
| `lervag/vimtex` | LaTeX compiling, viewing and motions |
| `L3MON4D3/LuaSnip` | Snippets, with autosnippets on for maths |
| `stevearc/conform.nvim` | Formatting, on save and on demand |
| `MeanderingProgrammer/render-markdown.nvim` | Renders markdown inside the buffer |
| `MagicDuck/grug-far.nvim` | Find and replace across a project |
| `mfussenegger/nvim-dap` | Debugging, with dap-ui and virtual text |
| `nvim-neotest/neotest` | Running tests, with the Python adapter |

`nvim-lspconfig` is not here. Neovim reads `lsp/<name>.lua` off the
runtimepath, so five servers cost sixty lines to own outright.

## The suite split

Nine capabilities exist in both mini and snacks. Picking per module rather than
per suite is how a configuration ends up with two notifiers and two indent
guides fighting each other.

The division is fixed. Do not cross it.

| Suite | Owns |
| --- | --- |
| mini | Editing verbs, statusline, tabline, icons, colours, git signs |
| snacks | Picker, explorer, terminal, images, input, notifications |

## Keymaps

Press `Space` and pause. which-key lists what follows, in a popup at the bottom
of the screen.

Press `<leader>?` for a cheatsheet of every mapping, grouped. The start screen
has a button for it too.

`lua/keygroups.lua` names each prefix. which-key and the cheatsheet both read
it, so a new group is declared once. It lives in its own module because
which-key empties the spec table it is given during setup, which makes that
table useless to read back.

### Groups

| Key | Group |
| --- | --- |
| `<leader>c` | compile, in a `.tex` buffer only |
| `<leader>d` | diagnostics and debug |
| `<leader>f` | find |
| `<leader>g` | git |
| `<leader>l` | lsp |
| `<leader>n` | notes |
| `<leader>t` | terminal |
| `<leader>T` | test |
| `<leader>u` | ui toggles |
| `<leader>?` | cheatsheet |
| `gs` | surround |

### Moving and editing

| Key | Action |
| --- | --- |
| `<C-h/j/k/l>` | Move between windows, including out of a terminal |
| `<C-Up/Down/Left/Right>` | Resize the window |
| `<S-h>`, `<S-l>` | Previous buffer, next buffer |
| `<C-d>`, `<C-u>` | Half page down or up, cursor centred |
| `j`, `k` | Move by display line when no count is given |
| `J`, `K` in visual | Move the selection, and reindent |
| `<`, `>` in visual | Indent, and stay in visual mode |
| `<leader>p` in visual | Paste over the selection without losing the register |
| `<Esc>` | Clear the search highlight |
| `q` | Close a help, quickfix or man window |

### Editing verbs

| Key | Action |
| --- | --- |
| `af`, `if` | A function, or its body |
| `ac`, `ic` | A class, or its body |
| `gsa`, `gsd`, `gsr` | Add, delete or replace a surround |
| `gR` | Replace a textobject with the register |
| `gX` | Exchange two regions. Press twice |
| `gM` | Multiply a textobject |
| `g=` | Evaluate a textobject |
| `ga`, `gA` | Align |
| `gS` | Split or join an argument list |
| `<A-h/j/k/l>` in visual | Move the selection |
| `[b`, `]b`, `[q`, `]q` | Previous or next buffer, quickfix entry |

### LSP

Neovim binds most of this itself. These work in any buffer where a server
attached, with no configuration.

| Key | Action |
| --- | --- |
| `grn`, `gra`, `grr` | Rename, code action, references |
| `gri`, `grt`, `grx` | Implementation, type definition, run codelens |
| `gO` | Document symbols |
| `K` | Hover |
| `<C-]>` | Go to definition, through `tagfunc` |
| `<C-s>` in insert | Signature help |
| `gq` | Format a motion, through `formatexpr` |
| `<C-x><C-o>` | Completion, through `omnifunc` |

This configuration adds one prefix on top.

| Key | Action |
| --- | --- |
| `<leader>lr`, `<leader>la` | Rename, code action |
| `<leader>ld`, `<leader>lD` | Definition, declaration |
| `<leader>li`, `<leader>lt` | Implementation, type definition |
| `<leader>lR`, `<leader>lo` | References, document symbols |
| `<leader>lf`, `<leader>ls` | Format, signature help |
| `<leader>lh` | Toggle inlay hints |
| `<leader>d` | Diagnostic float |
| `]d`, `[d` | Next diagnostic, previous diagnostic |

### Find

| Key | Action |
| --- | --- |
| `<leader>ff`, `<leader>fg` | Find files, grep the project |
| `<leader>fb`, `<leader>fr` | Buffers, recent files |
| `<leader>fh`, `<leader>fk` | Help pages, keymaps |
| `<leader>fd` | Diagnostics |
| `<leader>fs`, `<leader>fS` | Find and replace, in the project or this file |
| `<leader>e` | File explorer |

### Terminals

Each key answers three states. It opens the terminal when it is off screen,
moves focus to it when it is on screen but not focused, and hides it when you
are already in it.

| Key | Action |
| --- | --- |
| `<leader>tt`, `<leader>tv`, `<leader>th` | Floating, right split, bottom split |
| `<A-t>`, `<A-v>`, `<A-h>` | Hide that terminal from inside it |
| `<C-h/j/k/l>` in a terminal | Leave the terminal and move to that window |
| `<Esc><Esc>` in a terminal | Leave terminal mode, keeping it visible |
| `q` in normal mode | Hide the terminal |

Terminal toggles are bound in normal mode only. Leader is `Space`, and a
terminal forwards every keystroke to the program inside it. A terminal-mode
`<leader>th` would fire while you typed "the" or "with this".

Hiding is not closing. The shell keeps running and its scrollback survives, so
the same key brings it back. To close it, type `exit` in the shell.

`<C-d>` is deliberately not mapped in terminal mode. It is EOF in every shell
and is how a terminal is normally closed. Mapping it to leave terminal mode
steals the key and leaves `exit` as the only way out.

Terminals are per directory. snacks keys a terminal by its command, its working
directory and a count. Run `:lcd` into another repository and these keys open
that repository's terminal.

### Git

| Key | Action |
| --- | --- |
| `]h`, `[h` | Next hunk, previous hunk |
| `gh`, `gH` | Apply or reset a hunk, as an operator |
| `<leader>gs`, `<leader>gr` | Stage or reset the hunk under the cursor |
| `<leader>go` | Toggle the diff overlay |
| `<leader>gl` | History for this file |
| `<leader>gg` | Lazygit |
| `<leader>gb` | Open this file in the browser |

### Debug

| Key | Action |
| --- | --- |
| `<leader>b`, `<leader>B` | Breakpoint, conditional breakpoint |
| `<F5>` | Continue. Starts the session on the first press |
| `<F10>`, `<F11>`, `<F12>` | Step over, step into, step out |
| `<leader>du`, `<leader>dr` | Toggle the UI, toggle the REPL |
| `<leader>dt` | Terminate |

The UI opens with the session and closes when it ends. There is nothing to
toggle by hand.

### Test

| Key | Action |
| --- | --- |
| `<leader>Tt`, `<leader>Tf` | Run the nearest test, or the file |
| `<leader>Ts`, `<leader>To` | Summary, output |
| `<leader>Td` | Debug the nearest test |
| `<leader>TS` | Stop the run |

`<leader>T` is capitalised because `<leader>t` is the terminal prefix. A
lowercase collision would make both prefixes wait out `timeoutlen`.

### Notes

A notes tree is a directory of markdown files. Set `vim.g.notes_dir` to point
somewhere other than `~/SCHOOL`.

| Key | Action |
| --- | --- |
| `<leader>nf`, `<leader>ng` | Find a note, grep the notes tree |
| `<leader>nn` | New note. Creates any missing directory in the path |
| `<localleader>x` | Toggle the checkbox on this line |
| `<leader>um` | Toggle markdown rendering |
| `gf` | Open the link under the cursor. `.md` is added if the path has no suffix |

### LaTeX

vimtex owns `<localleader>l`. Press `\l` in a `.tex` buffer to list the whole
set. The keys below are the handful used constantly, bound under `Space` as
well, and they exist only in a `.tex` buffer.

| Key | Action |
| --- | --- |
| `<leader>cc` | Compile. Toggles the continuous build |
| `<leader>cv` | View the PDF in Skim |
| `<leader>ck` | Stop compiling |
| `<leader>ce` | Errors |
| `<leader>ct` | Table of contents |
| `<leader>cl` | Clean the build directory |

Build files go to a `build/` directory beside the source.

`<leader>c` rather than making `maplocalleader` `Space`. That would put vimtex
and the LSP table under one `<leader>l` prefix. They collide on five letters:
`la`, `li`, `lt`, `lo` and `ls` mean something to both.

### Toggles

| Key | Action |
| --- | --- |
| `<leader>uf` | Format on save |
| `<leader>um` | Markdown rendering |

## Statusline

Left to right: mode, git branch and working-tree changes, diagnostic counts,
the file name, then on the right the attached language servers, the filetype,
and the cursor position.

The file name, not its path. mini.statusline's own section shows a path
relative to the working directory, which is still most of a line inside a
nested source tree. The default also showed the file encoding and the byte
size, which are the same on every file opened here.

Servers are named rather than shown as "LSP". On Python two attach at once, and
knowing it is `clangd` and not `ltex_plus` is the thing being asked.

An inactive window shows only the file name.

## LSP

Server definitions live one per file under `lsp/`, which `vim.lsp.config` reads
off the runtimepath. Five servers are enabled: `clangd`, `lua_ls`, `pyright`,
`ruff` and `ltex_plus`.

`ruff` answers no hover requests, so `pyright` owns `K` alone. With both
answering, one press opens two stacked windows.

Completion is native. `vim.o.autocomplete` is the whole engine, and
`vim.lsp.completion` attaches per buffer when a server that offers completion
arrives. There is no completion plugin.

## LaTeX and markdown notes

vimtex compiles with `latexmk` and previews in Skim. Forward and inverse search
both work.

`snippets/tex.lua` holds autosnippets, which expand as you type with no confirm
key. Every maths snippet in that file works in a markdown buffer too.
`markdown_inline` wraps `$x$` in a `latex_block` with the latex parser injected
into it, so the same `inline_formula` node appears in a note as in a `.tex`
file. `lua/util/tex.lua` reads that parse tree.

No autosnippet fires inside code. `util/tex.lua` exposes `in_code`, and `mk` and
`dm` expand in text rather than in maths. Without that test, typing a variable
named `mk` in a fenced block rewrote it as `$$`. The test covers a tagged
fence, an untagged fence, an indented block, an inline code span and a LaTeX
`verbatim` environment.

A fence tagged with a language needs a different question from the other four.
It injects that language's parser, so the node chain from the cursor ends at
that tree's own root and never reaches markdown's `fenced_code_block`.
`in_code` asks which language owns the cursor for that case.

The snippets that write LaTeX markup are gated to `.tex` and never offer
themselves in a note. Those are `h1`, `h2`, `h3`, `beg`, `itm`, `enum`, `fig`,
`ali`, `eqn`, `cit`, `rf` and `lbl`. `dm` differs by filetype. It writes
`\[ ... \]` in a `.tex` file and `$$ ... $$` in a note, because markdown
renderers agree on the dollars and disagree about the brackets.

`snacks.image` draws images and rendered maths inline, over the Kitty graphics
protocol. Ghostty supports it. A `$$` block appears typeset rather than as
source. In a terminal with no graphics protocol it shows the source instead.

## Grammar checking

`ltex-ls-plus` checks grammar in markdown and LaTeX. It reads the markup, so
`\alpha` and a table pipe are not reported as spelling mistakes.

It attaches only to `markdown` and `tex`. Its own default list names eighteen
filetypes, including `gitcommit`. This is a 257MB Java server, so starting it on
every commit message is a cost with no return.

A word you add through the code action is written under `ltex/` and read back on
the next start. Three files live there: `dictionary.txt`, `disabled-rules.txt`
and `false-positives.txt`.

## Formatting

conform formats on save. `<leader>uf` turns that off for the session, and
`<leader>lf` formats on demand.

| Filetype | Formatter |
| --- | --- |
| C, C++ | `clang_format` |
| Python | `ruff_fix`, `ruff_format` |
| Lua | `stylua` |
| Markdown | `prettier` |
| JSON | `jq` |
| Shell | `shfmt` |
| Anything else | Trailing whitespace removed |

`ruff_fix` runs with `--ignore F401`, so a save never deletes an import you have
not used yet. The ruff language server still reports the unused import as a
diagnostic.

prettier runs with `--prose-wrap preserve`. Soft wrap does the wrapping on
screen, so one paragraph stays on one line and a one-word edit stays a one-word
diff.

Markdown saves get a 3000ms timeout. Every other filetype gets 1000ms. prettier
is a Node program and its cold interpreter start exceeds 1000ms, and conform
answers a timeout by writing the file unformatted with only a line in
`:messages`.

## Tests

The tests start Neovim headless, load the configuration and assert against the
result. There is one file per layer.

Run every test:

```
tests/run.sh
```

Run one test:

```
tests/nvim-test tests/lsp.lua -c 'Lazy! load all'
```

Each run has a 35 second limit. A test that hangs fails rather than blocking the
run. `lua/testkit.lua` adds its own 30 second watchdog inside that, so any
`vim.wait` in a test must finish well inside 30 seconds.

A change is not done until `tests/run.sh` prints `exit=0`.

## Start screen

A sprite from `art/`, drawn as 24-bit ANSI half-blocks: each cell is one glyph
carrying a foreground colour for the top pixel and a background colour for the
bottom. nvdash could not do this. It renders its header as one virt_text chunk
per line with a single highlight group, so it cannot show more than one colour.

Sprites are weighted, in the `WEIGHTS` table in `lua/pokedash.lua`. A file not
named there gets a weight of 1. Charizard carries 12 against six others at one
apiece, so two openings in three are his and the rest turn up one time in
eighteen each.

The sprites are [pokemon-colorscripts](https://gitlab.com/phoneybadger/pokemon-colorscripts)
art, used as published. To add one, take a file from that project's
`colorscripts/` and drop it in `art/`.

Pick the size tier per creature rather than using one throughout. The project
renders at true relative scale, so at its small tier ditto is 8x16 while ho-oh
is 26x46, and at its large tier ho-oh is 50x92. Aim for roughly charizard's
21x44 so no sprite is a speck or overflows the screen.

## Gotchas

`lazy-lock.json` is not tracked. Plugin versions are not pinned, so a fresh
clone installs the current release of every plugin.

Call `Snacks.terminal.focus`, never `Snacks.terminal.toggle`. `toggle` asks only
whether the terminal buffer sits in a window and not whether that window is
focused. Clicking off a floating terminal and pressing the key then closes the
terminal you were trying to return to.

`mini.operators` is remapped off its defaults, and must stay that way. Its
default `replace` prefix is `gr`, which takes the whole native LSP namespace and
removes `grn`, `gra`, `grr`, `gri`, `grt` and `grx`. Its default `sort` prefix
is `gs`, which is where surround lives. Its default `exchange` prefix is `gx`,
which opens the URL under the cursor. `tests/editing.lua` asserts all seven
native maps survive.

`<D-l>` was tried as an LSP prefix and removed. Ghostty does not forward Command
to the application, so `Cmd+L` arrives as a bare `l`. The sub-key then lands as
a normal-mode command. `Cmd+L r` replaces a character and `Cmd+L D` deletes to
the end of the line. Do not reintroduce it without first checking that Super
reaches Neovim.

clangd is only as good as `compile_commands.json`. Without one it guesses
include paths and every third header resolves to nothing, which reads as a
broken language server rather than a missing build database. For CMake,
configure with `-DCMAKE_EXPORT_COMPILE_COMMANDS=ON`. For plain make, run the
build once under `bear`.

A breakpoint may never bind when the source lives under `/tmp`. lldb matches
breakpoints by comparing the path Neovim sends against the path in the binary's
debug info. Neovim resolves symlinks, and macOS makes `/tmp` a symlink to
`/private/tmp`. A binary compiled as `/tmp/x/main.c` records `/tmp` while Neovim
sends `/private/tmp`. The program runs to completion and exits 0. Real projects
do not live under `/tmp`.

`vim.pack` is not used. Neovim 0.12 ships it, and it has no lazy loading, no
dependency ordering and no build hooks. This configuration uses all three.

The previous configuration is kept at `~/.config/bak-nvim` with its own history.
Run it with `NVIM_APPNAME=bak-nvim nvim`. That also moves its plugin data to
`~/.local/share/bak-nvim`, so the two never share state.
