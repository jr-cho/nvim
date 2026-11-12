-- Central icon table. Every glyph is a Nerd Font codicon written as a \u{} escape
-- (never paste literal glyphs: they get lost in tooling).
return {
  diagnostics = { Error = "\u{ea87}", Warn = "\u{ea6c}", Info = "\u{ea74}", Hint = "\u{ea61}" },
  dap = {
    Breakpoint = "\u{ea71}",
    BreakpointCondition = "\u{eaa7}",
    LogPoint = "\u{eaab}",
    Stopped = "\u{eb8b}",
    BreakpointRejected = "\u{eabd}", -- cod-circle_slash (no *_unverified codicon for plain breakpoints)
  },
  git = { branch = "\u{ec6f}", added = "\u{eadc}", modified = "\u{eade}", removed = "\u{eadf}" },
  misc = {
    lsp = "\u{eba2}",
    file = "\u{ea7b}",
    new_file = "\u{ea7f}",
    text = "\u{ea6d}",
    recent = "\u{ea82}",
    project = "\u{ea62}",
    config = "\u{eb51}",
    lazy = "\u{eb29}",
    mason = "\u{eb6d}",
    quit = "\u{ea6e}",
    terminal = "\u{ea85}",
    problems = "\u{ea6c}",
    output = "\u{eb9d}",
    debug_console = "\u{eb9b}",
    close = "\u{ea76}",
    add = "\u{ea60}",
  },
}
