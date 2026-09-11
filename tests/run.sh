#!/usr/bin/env bash
# Runs every headless test. Exits non-zero if any of them fails.
set -u
cd "$(dirname "$0")/.."

failed=0
for test in tests/boot.lua tests/editor.lua tests/treesitter.lua tests/lsp.lua \
            tests/completion.lua tests/mini.lua tests/editing.lua \
            tests/snacks.lua tests/format.lua tests/git.lua \
            tests/tex.lua tests/markdown.lua tests/dap.lua tests/neotest.lua \
            tests/dash.lua tests/cheatsheet.lua tests/statusline.lua; do
  echo "== $test"
  if tests/nvim-test "$test" -c 'Lazy! load all' 2>&1; then
    echo "PASS $test"
  else
    echo "FAIL $test"
    failed=1
  fi
done

exit "$failed"
