-- Which rank each card plays as. Under the loose rule a card can play as any rank its value equals or is
-- confused with; this module proposes the assignments worth trying. The game's own hand evaluator then
-- scores each candidate, and the best hand wins (src/cards.lua), so other mods' hands stay correct.
--
-- One candidate per rank pattern is enough, because a hand's type depends on the pattern of ranks, not on
-- which ranks: for each rank, every card that can join it does (Five, Four, Three of a Kind and Pairs);
-- the highest pair of ranks that can make a Full House, and the highest that can make Two Pair; every
-- straight a matching can fill; and a default where every flexible card plays its highest rank.
--
-- Ranks are integers 0–15 (J 11, Q 12, K 13, A 14, Knight 15). Cards whose values have no rank but are
-- equal (two 3½s) form tie groups, and play as tokens "tie1", "tie2", which only ever pair with each other.
--
-- Loading: `loadfile(path)(E)` registers the module as E.hands, and returns it. It needs no other module.

local E = ...
local M = {}
E.hands = M

local ACE, KNIGHT = 14, 15

-- Successors of a rank in a straight. The Ace plays low only at the start of a straight (A-2-3-4-5); in
-- the middle it can only be followed by the Knight. A skip (Shortcut) may not jump over the Ace.
local function successors(r, at_start, skip)
  local out = {}
  local function step(x)
    if x == ACE then return at_start and { 2, KNIGHT } or { KNIGHT } end
    if x >= KNIGHT then return {} end
    return { x + 1 }
  end
  for _, n in ipairs(step(r)) do
    out[#out + 1] = { n, false }
    if skip and n ~= ACE then
      for _, m in ipairs(step(n)) do out[#out + 1] = { m, true } end
    end
  end
  return out
end

--- Every run of ranks a straight of this length could use.
function M.straight_windows(length, skip)
  local out = {}
  local function extend(run)
    if #run == length then
      local copy = {}
      for i, r in ipairs(run) do copy[i] = r end
      out[#out + 1] = copy
      return
    end
    for _, nx in ipairs(successors(run[#run], #run == 1, skip)) do
      local r = nx[1]
      local repeated = false
      for _, x in ipairs(run) do if x == r then repeated = true end end
      if not repeated then
        run[#run + 1] = r
        extend(run)
        run[#run] = nil
      end
    end
  end
  for start = 0, KNIGHT do extend({ start }) end
  return out
end

local function has(set, r)
  for _, x in ipairs(set) do if x == r then return true end end
  return false
end

-- Match each rank of a window to a distinct card that can play it (Kuhn's augmenting paths).
local function match_window(window, cards)
  local owner = {} -- card index -> window position
  local function try(pos, seen)
    for i, c in ipairs(cards) do
      if not seen[i] and has(c.ranks, window[pos]) then
        seen[i] = true
        if owner[i] == nil or try(owner[i], seen) then
          owner[i] = pos
          return true
        end
      end
    end
    return false
  end
  for pos = 1, #window do
    if not try(pos, {}) then return nil end
  end
  return owner
end

--- Candidate assignments for a hand. `cards` is a list of {ranks = {..}, key = string}; `opts` has
--- `straight` (shortest straight, 5 or 4 with Four Fingers) and `skip` (Shortcut). Each candidate is a
--- list with, per card, its rank, a tie token, or false for no rank.
function M.candidates(cards, opts)
  opts = opts or {}
  local min_straight = opts.straight or 5

  -- Ties among rankless cards are fixed for every candidate.
  local tie_of, groups, order = {}, {}, {}
  for i, c in ipairs(cards) do
    if #c.ranks == 0 then
      if not groups[c.key] then groups[c.key] = {}; order[#order + 1] = c.key end
      table.insert(groups[c.key], i)
    end
  end
  local n_ties = 0
  for _, key in ipairs(order) do
    if #groups[key] >= 2 then
      n_ties = n_ties + 1
      for _, i in ipairs(groups[key]) do tie_of[i] = "tie" .. n_ties end
    end
  end

  local flexible, union, union_set = {}, {}, {}
  for i, c in ipairs(cards) do
    if #c.ranks >= 2 then flexible[#flexible + 1] = i end
    for _, r in ipairs(c.ranks) do
      if not union_set[r] then union_set[r] = true; union[#union + 1] = r end
    end
  end
  table.sort(union, function(a, b) return a > b end)

  local function base()
    local a = {}
    for i, c in ipairs(cards) do
      if #c.ranks == 0 then a[i] = tie_of[i] or false
      else
        local best = c.ranks[1]
        for _, r in ipairs(c.ranks) do if r > best then best = r end end
        a[i] = best
      end
    end
    return a
  end

  local out, seen = {}, {}
  local function add(a)
    local parts = {}
    for i, v in ipairs(a) do parts[i] = tostring(v) end
    local key = table.concat(parts, ",")
    if not seen[key] then seen[key] = true; out[#out + 1] = a end
  end

  add(base())
  if #flexible == 0 then return out end

  -- Of a kind: every card that can play r does.
  for _, r in ipairs(union) do
    local a = base()
    for _, i in ipairs(flexible) do
      if has(cards[i].ranks, r) then a[i] = r end
    end
    add(a)
  end

  -- Full House and Two Pair: the highest pair of ranks that makes each.
  if #flexible <= 6 then
    local fixed_count = {}
    for i, c in ipairs(cards) do
      if #c.ranks == 1 then fixed_count[c.ranks[1]] = (fixed_count[c.ranks[1]] or 0) + 1 end
    end
    local best = {}
    for _, r1 in ipairs(union) do
      if best.house and best.two then break end
      for _, r2 in ipairs(union) do
        if best.house and best.two then break end
        if r1 ~= r2 then
          -- Each flexible card goes to r1, to r2, or stays as it is (0, 1, 2).
          local choice, n = {}, #flexible
          for j = 1, n do choice[j] = 0 end
          while true do
            local ok = true
            local c1, c2 = fixed_count[r1] or 0, fixed_count[r2] or 0
            for j = 1, n do
              local i = flexible[j]
              if choice[j] == 1 then
                if has(cards[i].ranks, r1) then c1 = c1 + 1 else ok = false end
              elseif choice[j] == 2 then
                if has(cards[i].ranks, r2) then c2 = c2 + 1 else ok = false end
              end
            end
            if ok then
              for _, pattern in ipairs({ { "house", 3, 2 }, { "two", 2, 2 } }) do
                local name, need1, need2 = pattern[1], pattern[2], pattern[3]
                if c1 >= need1 and c2 >= need2 and not best[name] then
                  local a = base()
                  for j = 1, n do
                    if choice[j] == 1 then a[flexible[j]] = r1 elseif choice[j] == 2 then a[flexible[j]] = r2 end
                  end
                  best[name] = a
                end
              end
            end
            -- next choice vector
            local j = 1
            while j <= n and choice[j] == 2 do choice[j] = 0; j = j + 1 end
            if j > n then break end
            choice[j] = choice[j] + 1
          end
        end
      end
    end
    if best.house then add(best.house) end
    if best.two then add(best.two) end
  end

  -- Straights: every window a matching can fill.
  for length = math.min(5, #cards), min_straight, -1 do
    for _, window in ipairs(M.straight_windows(length, opts.skip)) do
      local owner = match_window(window, cards)
      if owner then
        local a = base()
        for i, pos in pairs(owner) do a[i] = window[pos] end
        add(a)
      end
    end
  end

  return out
end

return M
