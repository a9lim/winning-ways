-- Run test. `WINNINGWAYS_RUNTEST=<file> balala` starts a real run (saving switched off), picks the Small Blind and
-- plays scripted hands through the game's own code: a hot card's bite, infinity eating, and a Move used for real.
-- It writes PASS/FAIL lines to <file> and quits. scripts/runtest also backs up and restores the save files.
local out_path = os.getenv("WINNINGWAYS_RUNTEST")
local WW = WinningWays
local E = WW.engine
local N, Gm = E.num, E.game
local n = N.new
local lines, failed = {}, 0

local function check(name, ok, detail)
  if not ok then failed = failed + 1 end
  lines[#lines + 1] = (ok and "PASS " or "FAIL ") .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or "")
end
local function num(x) return type(x) == "number" and x or (to_number and to_number(x)) or tonumber(tostring(x)) end
local function score() return num(G.GAME.chips) end

-- Turn hand card i into rank `rank` of `suit` with an optional modifier.
local function make(i, suit, rank, mod)
  local c = G.hand.cards[i]
  WW.set_mod(c, N.zero)
  assert(SMODS.change_base(c, suit, rank))
  if mod then WW.add_mod(c, mod) end
  return c
end
local function play(cards)
  G.hand:unhighlight_all()
  for _, c in ipairs(cards) do G.hand:add_to_highlighted(c, true) end
  G.FUNCS.play_cards_from_highlighted()
end
local function alive(card)
  for _, c in ipairs(G.playing_cards) do if c == card then return true end end
  return false
end

local steps, step, frames, before = {}, 1, 0, 0
local ate, eater, cut, left, right

steps[1] = { wait = function() return G.STATE == G.STATES.MENU and G.MAIN_MENU_UI end, run = function()
  G.F_NO_SAVING = true
  G.FUNCS.start_run(nil, { stake = 1, seed = "WWRUNTEST" })
end }
steps[2] = { wait = function() return G.STATE == G.STATES.BLIND_SELECT and G.blind_select end, run = function()
  -- The button's UI box only matters for a skip tag; a stub with no tag container will do.
  G.FUNCS.select_blind({
    config = { ref_table = G.P_BLINDS[G.GAME.round_resets.blind_choices.Small] },
    UIBox = { get_UIE_by_ID = function() return nil end },
  })
end }
steps[3] = { wait = function() return G.STATE == G.STATES.SELECTING_HAND and #G.hand.cards >= 5 end, run = function()
  -- 7 7 and a 7 with ±2: Three of a Kind. You move first and take the hot card's 9, so the cards score 7 + 7 + 9.
  before = score()
  play({ make(1, "Hearts", "7"), make(2, "Spades", "7"), make(3, "Diamonds", "7", Gm.of({ n(2) }, { n(-2) })) })
end }
steps[4] = { wait = function() return G.STATE == G.STATES.SELECTING_HAND end, run = function()
  check("the hot hand was Three of a Kind", G.GAME.last_hand_played == "Three of a Kind", G.GAME.last_hand_played)
  check("it scored (30 + 7 + 7 + 9) × 3 = 159", score() - before == 159, score() - before)
  -- 7 7 K+ω 9 9: the King eats both 7s and grows by 14; a Pair of 9s, and the King always scores.
  before = score()
  local a, b = make(1, "Hearts", "7"), make(2, "Clubs", "7")
  eater = make(3, "Spades", "King", N.omega)
  ate = { a, b }
  play({ a, b, eater, make(4, "Diamonds", "9"), make(5, "Spades", "9") })
end }
steps[5] = { wait = function() return G.STATE == G.STATES.SELECTING_HAND end, run = function()
  check("with the 7s eaten, the hand was a Pair", G.GAME.last_hand_played == "Pair", G.GAME.last_hand_played)
  check("it scored (10 + 9 + 9 + 10 + 14) × 2 = 104", score() - before == 104, score() - before)
  check("the eaten 7s are gone", not alive(ate[1]) and not alive(ate[2]))
  check("the King kept 14 bonus chips", eater.ability.perma_bonus == 14, eater.ability.perma_bonus)
  -- A Move, used through the game's own button: Cut on a 3 and a 7 makes a 4.
  left, right = make(1, "Hearts", "3"), make(2, "Spades", "7")
  cut = SMODS.add_card({ key = "c_ww_cut", area = G.consumeables })
  G.hand:unhighlight_all()
  G.hand:add_to_highlighted(left, true)
  G.hand:add_to_highlighted(right, true)
  check("Cut can be used on two cards", cut.config.center:can_use(cut))
  G.FUNCS.use_card({ config = { ref_table = cut, button = "use_card" } })
end }
steps[6] = { frames = 240, run = function()
  check("Cut 3, 7 made a 4", WW.value_of(left) and Gm.encode(WW.value_of(left)) == "4", WW.value_of(left) and Gm.encode(WW.value_of(left)))
  check("and used up the 7", not alive(right))
  check("the Cut card is spent", cut.removed or not cut.area or cut.area ~= G.consumeables)
end }

local update = Game.update
local done = false
local since = love.timer.getTime()
function Game:update(dt)
  update(self, dt)
  if done then return end
  frames = frames + 1
  local s = steps[step]
  local waited = love.timer.getTime() - since
  -- Each step waits for its state, then a moment more (1.5 s) for the game's events to settle.
  local ready = s and (s.wait and s.wait() and frames > 90 and waited > 1.5 or (s.frames and frames > s.frames))
  if s and ready then
    local ok, err = pcall(s.run)
    if not ok then check("step " .. step .. " ran", false, err); step = #steps + 1 else step = step + 1 end
    frames, since = 0, love.timer.getTime()
  elseif s and waited > (step == 1 and 120 or 60) then
    check("step " .. step .. " started in time", false, "state " .. tostring(G.STATE))
    step = #steps + 1
  end
  if step > #steps then
    done = true
    lines[#lines + 1] = ("%d checks, %d failed"):format(#lines, failed)
    local f = io.open(out_path, "w")
    if f then f:write(table.concat(lines, "\n"), "\n"); f:close() end
    print("WINNINGWAYS RUNTEST\n" .. table.concat(lines, "\n"))
    love.event.quit()
  end
end
