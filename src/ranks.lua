-- The born ranks: 0 = {|}, 1 = {0|} and the Knight = {A|} = 15. None is in the starting deck; Moves make them.
-- The fronts are placeholders (art/placeholder_ranks.py) until the card faces are drawn.

SMODS.Atlas { key = "ranks", path = "ranks.png", px = 71, py = 95 }

local function never() return false end

SMODS.Rank {
  key = "0",
  card_key = "0",
  shorthand = "0",
  pos = { x = 0 },
  lc_atlas = "ww_ranks",
  hc_atlas = "ww_ranks",
  nominal = 0,
  face_nominal = 0,
  next = { "ww_1" },
  in_pool = never,
}

SMODS.Rank {
  key = "1",
  card_key = "1",
  shorthand = "1",
  pos = { x = 1 },
  lc_atlas = "ww_ranks",
  hc_atlas = "ww_ranks",
  nominal = 1,
  face_nominal = 0,
  next = { "2" },
  in_pool = never,
}

-- Above the Ace in straights (J-Q-K-A-Kn). Steamodded's straights only let an Ace end one, so the mod owns
-- the straight part (src/cards.lua) to let the Ace lead into the Knight.
SMODS.Rank {
  key = "Knight",
  card_key = "Kn",
  shorthand = "Kn",
  pos = { x = 2 },
  lc_atlas = "ww_ranks",
  hc_atlas = "ww_ranks",
  nominal = 15,
  face_nominal = 0.5,
  face = true,
  next = {},
  in_pool = never,
}
