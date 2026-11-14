-- In-game self-test. `WINNINGWAYS_SELFTEST=<file> balala` boots the game, checks at the main menu that the
-- engine loaded and works on the game's own LuaJIT, writes PASS/FAIL lines to <file> and quits. It never
-- starts a run.
local out_path = os.getenv("WINNINGWAYS_SELFTEST")
local E = WinningWays.engine
local lines, failed = {}, 0

local function check(name, ok, detail)
  if not ok then failed = failed + 1 end
  lines[#lines + 1] = (ok and "PASS " or "FAIL ") .. name .. (detail and (" (" .. tostring(detail) .. ")") or "")
end

local function run()
  local N, G, P, nim = E.num, E.game, E.play, E.nim
  check("the engine loaded", N and G and P and nim)
  local n = N.new
  check("{3|4} = 3½", G.encode(G.of({ n(3) }, { n(4) })) == "7/2")
  check("{A|ω} = Knight", G.encode(G.of({ n(14) }, { N.omega })) == "15")
  local wild = G.of({ N.omega }, { n(2) })
  local ranks = table.concat(P.ranks(wild), ",")
  check("{ω|2} plays as every rank from 2", ranks == "2,3,4,5,6,7,8,9,10,11,12,13,14,15", ranks)
  local r = P.resolve({ G.of({ n(6) }, { n(4) }), G.of({ n(14) }, { n(2) }), n(7) })
  check("the hotstrat scores 25", N.encode(r.total) == "25", N.encode(r.total))
  check("K ⊗ A = 1 in nim arithmetic", nim.mul(13, 14) == 1)
  check("notation round-trips", G.encode(G.parse("{{6|4}|2}")) == G.encode(G.of({ G.of({ n(6) }, { n(4) }) }, { n(2) })))
end

local update = Game.update
local done, frames = false, 0
function Game:update(dt)
  update(self, dt)
  if done then return end
  if G.STATE == G.STATES.MENU and G.MAIN_MENU_UI then frames = frames + 1 end
  if frames < 30 then return end
  done = true
  local ok, err = pcall(run)
  if not ok then check("self-test ran to the end", false, err) end
  lines[#lines + 1] = ("%d checks, %d failed"):format(#lines, failed)
  local f = io.open(out_path, "w")
  if f then f:write(table.concat(lines, "\n"), "\n"); f:close() end
  print("WINNINGWAYS SELFTEST\n" .. table.concat(lines, "\n"))
  love.event.quit()
end
