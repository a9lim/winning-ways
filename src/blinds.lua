-- The Heap, a Boss Blind (DESIGN.md § 5): a hand whose scoring cards nim-sum to 0 scores nothing. Because a ⊕ a = 0,
-- Pairs, Two Pairs and Four of a Kinds never score under it, and no straight ever nim-sums to 0. The scoring cards
-- are Steamodded's final ones (Splash, Stone and ω cards included), counted as the ranks they play as; cards with no
-- rank are invisible to the sum.

local WW = WinningWays

-- Until Fable's chip is in, The Heap wears the Small Blind's.
local ART = NFS.getInfo(WW.path .. "assets/1x/blinds.png") ~= nil
if ART then
  SMODS.Atlas { key = "blinds", path = "blinds.png", px = 34, py = 34, atlas_table = "ANIMATION_ATLAS", frames = 21 }
end

SMODS.Blind {
  key = "heap",
  atlas = ART and "blinds" or nil,
  pos = { x = 0, y = 0 },
  boss = { min = 2 },
  boss_colour = HEX("4d9f7c"),
  mult = 2,
  dollars = 5,
  calculate = function(self, blind, context)
    if context.debuff_hand and not blind.disabled and WW.nim_sum(context.scoring_hand) == 0 then
      return { debuff = true }
    end
  end,
}
