-- The born ranks: 0 = {|}, 1 = {0|}, and the Cavalier C = {J|Q} = 12, tarot's fourth court card, between the
-- Jack and the Queen. None is in the starting deck; Moves make them, and the Field Deck starts with them.
-- Fable drew the fronts (art/fronts.py), from vanilla's own sprites.

SMODS.Atlas { key = "ranks", path = "ranks.png", px = 71, py = 95 }
SMODS.Atlas { key = "ranks_hc", path = "ranks_hc.png", px = 71, py = 95 }

local function never() return false end

SMODS.Rank {
  key = "0",
  card_key = "0",
  shorthand = "0",
  pos = { x = 0 },
  lc_atlas = "ww_ranks",
  hc_atlas = "ww_ranks_hc",
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
  hc_atlas = "ww_ranks_hc",
  nominal = 1,
  face_nominal = 0,
  next = { "2" },
  in_pool = never,
}

SMODS.Rank {
  key = "C",
  card_key = "C",
  shorthand = "C",
  pos = { x = 2 },
  lc_atlas = "ww_ranks",
  hc_atlas = "ww_ranks_hc",
  nominal = 10,
  face_nominal = 0.15, -- between the Jack (0.1) and the Queen (0.2)
  face = true,
  next = { "Queen" },
  in_pool = never,
}

-- The Cavalier is optional in straights: J-Q still follows, and so does J-C-Q. The Queen stays first in the
-- Jack's list, so Strength still turns a Jack into a Queen.
table.insert(SMODS.Ranks.Jack.next, "ww_C")
