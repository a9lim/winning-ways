-- Test runner. Works under plain LuaJIT (`luajit tests/main.lua`) and under LÖVE
-- (`love tests`), both from the repo root; scripts/test picks one.
--
-- Each file returns a function that takes `test(name, body)`; `body` gets `eq`.

local files = { "tests/known_test.lua", "tests/ogdoad_test.lua" }

local passed, failed, checks = 0, 0, 0
for _, file in ipairs(files) do
  local suite = dofile(file)
  suite(function(name, body)
    local problems = {}
    local function eq(got, want, label)
      checks = checks + 1
      if got ~= want then
        problems[#problems + 1] = ("%s: got %s, want %s"):format(label or "value", tostring(got), tostring(want))
      end
    end
    local ok, err = pcall(body, eq)
    if not ok then problems[#problems + 1] = tostring(err) end
    if #problems == 0 then
      passed = passed + 1
    else
      failed = failed + 1
      print(("FAIL %s: %s"):format(file, name))
      for i = 1, math.min(#problems, 5) do print("  " .. problems[i]) end
      if #problems > 5 then print(("  ... and %d more"):format(#problems - 5)) end
    end
  end)
end

print(("%d passed, %d failed (%d checks)"):format(passed, failed, checks))
io.stdout:flush()
os.exit(failed == 0 and 0 or 1)
