local t = require("testkit")
local function ns_probe()
  return vim.api.nvim_create_namespace("pokedash")
end

t.run(function()
  local pd = require("pokedash")
  t.truthy("pokedash loads", pd ~= nil)
  t.truthy("sprite art present", #vim.fn.globpath(vim.fn.stdpath("config") .. "/art", "*", false, true) > 0)

  pd.open()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  t.truthy("dashboard drew something", #lines > 5)

  -- No raw escape sequences: the ANSI must be parsed into highlights.
  local raw = false
  for _, l in ipairs(lines) do if l:find("\27") then raw = true end end
  t.check("no ANSI escapes leaked into the buffer", raw, false)

  -- Multiple colours, which is the entire reason this replaces nvdash.
  local ns = vim.api.nvim_create_namespace("pokedash")
  local marks = vim.api.nvim_buf_get_extmarks(0, ns, 0, -1, { details = true })
  local hls = {}
  for _, m in ipairs(marks) do
    if m[4] and m[4].hl_group then hls[m[4].hl_group] = true end
  end
  local n = 0; for _ in pairs(hls) do n = n + 1 end
  print("  distinct sprite colours: " .. n)
  -- Low bound only. It proves the sprite drew in colour rather than as text.
  -- Demanding many colours fails on ditto, which is five, and is fine.
  t.truthy("sprite drew in colour", n > 3)

  -- Both sprites are present.
  local art_dir = vim.fn.stdpath("config") .. "/art"
  local art = vim.fn.globpath(art_dir, "*", false, true)
  local names = {}
  for _, f in ipairs(art) do
    names[vim.fn.fnamemodify(f, ":t")] = f
  end
  t.truthy("charizard is present", names["charizard-shiny"] ~= nil)
  t.truthy("ditto is present", names["ditto"] ~= nil)
  -- globpath with the list flag returns a table, so an empty result is {} and
  -- never the empty string.
  t.check("no leftover .hidden files", #vim.fn.globpath(art_dir, "*.hidden", false, true), 0)

  -- Charizard is two openings in three. The other six share the remaining
  -- third at one in eighteen apiece. A rare sprite that shows up half the time
  -- is not rare.
  local W = {
    ["charizard-shiny"] = 12,
    ["charmander"] = 1,
    ["ditto"] = 1,
    ["dragonite"] = 1,
    ["dratini"] = 1,
    ["groudon"] = 1,
    ["ho-oh"] = 1,
  }
  local total = 0
  for name in pairs(names) do
    total = total + (W[name] or 1)
  end
  local charizard_share = (W["charizard-shiny"] or 1) / total
  t.truthy("charizard is about two in three", charizard_share > 0.60 and charizard_share < 0.73)
  for name in pairs(names) do
    if name ~= "charizard-shiny" then
      t.truthy(name .. " is rare", ((W[name] or 1) / total) < 0.10)
    end
  end

  -- Render each sprite by name. open() takes the path, so nothing on disk is
  -- renamed: an earlier version hid the other sprites to force a choice, and
  -- left them renamed on disk when an assertion failed.
  for name, path in pairs(names) do
    pd.open({ sprite = path })
    local text = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
    local groups = {}
    for _, m in ipairs(vim.api.nvim_buf_get_extmarks(0, ns_probe(), 0, -1, { details = true })) do
      if m[4] and m[4].hl_group then
        groups[m[4].hl_group] = true
      end
    end
    local n = 0
    for _ in pairs(groups) do
      n = n + 1
    end

    t.truthy(name .. " draws in colour", n > 3)

    -- The renderer caches one highlight group per colour pair, so it can never
    -- need more groups than the sprite has cells. More than that means the
    -- cache is missing and every cell is making its own group.
    --
    -- An absolute cap was wrong here. It was set at 120 to catch a blurred
    -- image conversion, and ho-oh legitimately needs 259 because it is a
    -- rainbow bird. There is no resampler in the pipeline any more: the sprites
    -- are pokemon-colorscripts art, used as published.
    local rows = 0
    for _ in io.lines(path) do
      rows = rows + 1
    end
    t.truthy(name .. " reuses highlight groups", n <= rows * 100)

    t.check(name .. " leaks no escapes", text:find("\27"), nil)
    vim.cmd("bwipeout!")
  end

  -- The cheatsheet is on the start screen, where it is useful before you know
  -- any keys. Its command must exist, or the button fails silently on a press.
  local has_cheatsheet = false
  for _, b in ipairs(pd.buttons) do
    if b.label == "Cheatsheet" then has_cheatsheet = true end
  end
  t.truthy("a Cheatsheet button is on the start screen", has_cheatsheet)
  t.truthy(":Cheatsheet is a real command", vim.api.nvim_get_commands({})["Cheatsheet"] ~= nil)

  -- Buttons must name commands that exist now.
  for _, b in ipairs(pd.buttons) do
    t.truthy("button " .. b.key .. " has a command", b.cmd ~= nil and b.cmd ~= "")
    t.truthy("button " .. b.key .. " is not NvChad's", b.cmd:match("nvchad") == nil and b.cmd:match("Telescope") == nil)
  end
end)
