-- The Laboratory: a development deck for trying values before the Moves exist. It's a standard deck with a sample of
-- every kind of modifier, plus the born ranks. Remove it before release.

local WW = WinningWays
local E = WW.engine
local N, Gm = E.num, E.game
local n = N.new
local function cut(a, b) return Gm.of(a and { a } or {}, b and { b } or {}) end
local STAR = cut(N.zero, N.zero)

-- {suit, rank, how, what}: "mod" adds to the modifier, "value" makes the card worth it.
WW.LAB = {
  { "Diamonds", "3", "mod", n(1 / 2) },                  -- 3½
  { "Clubs", "6", "mod", n(-1 / 4) },                    -- 5¾
  { "Hearts", "10", "mod", n(3 / 8) },                   -- 10⅜
  { "Hearts", "7", "mod", cut(n(2), n(-2)) },            -- 7±2: plays as 5–9
  { "Clubs", "5", "mod", cut(n(1), n(-1)) },             -- 5±1
  { "Spades", "Queen", "mod", cut(n(1), n(-1)) },        -- Q±1: plays as C, Q or K
  { "Spades", "9", "mod", STAR },                        -- 9*
  { "Hearts", "4", "mod", STAR },                        -- 4*
  { "Spades", "Ace", "value", cut(N.omega, n(2)) },      -- the wild
  { "Diamonds", "8", "value", cut(cut(n(9), n(5)), n(3)) }, -- a game: {7±2 | 3}
  { "Clubs", "King", "mod", N.omega },                   -- ω + 14 (eating isn't built yet)
}
WW.LAB_EXTRA = { "H_ww_0", "C_ww_1", "D_ww_C", "S_ww_C" }

function WW.apply_lab(cards)
  for _, row in ipairs(WW.LAB) do
    local suit, rank, how, what = row[1], row[2], row[3], row[4]
    for _, c in ipairs(cards) do
      if c.base.suit == suit and c.base.value == rank and not WW.has_mod(c) then
        if how == "mod" then WW.add_mod(c, what) else WW.set_value(c, what) end
        break
      end
    end
  end
end

SMODS.Back {
  key = "lab",
  pos = { x = 4, y = 3 },
  apply = function(self)
    G.E_MANAGER:add_event(Event({
      func = function()
        WW.apply_lab(G.playing_cards)
        for _, code in ipairs(WW.LAB_EXTRA) do
          create_playing_card({ front = G.P_CARDS[code], center = G.P_CENTERS.c_base }, G.deck, true, true)
        end
        return true
      end,
    }))
  end,
}
