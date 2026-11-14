-- How a hand's cards score: the scoring cards' values are one sum of games, you move first, the Blind
-- replies, and play goes on until every card is a number. The total is the sum's Left stop; each card
-- scores the number it ends on. Numbers are never moved in (Number Avoidance), so a hand of plain numbers
-- scores exactly as vanilla.
--
-- Loading: `loadfile(path)(E)` after num.lua and game.lua registers the module as E.play, and returns it.

local E = ...
local N = assert(E.num, "load num.lua before play.lua")
local G = assert(E.game, "load game.lua before play.lua")
local M = {}
E.play = M

local function key_of(state, turn)
  local parts = { turn }
  for i, v in ipairs(state) do parts[i + 1] = G.encode(v) end
  return table.concat(parts, ";")
end

-- Tie-break between equally good moves: the hotter card first, then the leftmost.
local function hotter(a, b)
  return N.lt(G.temperature(b), G.temperature(a))
end

--- Play out a hand. `values` are the scoring cards' values, left to right.
--- Returns {total = num, finals = {num per card}, moves = {{card = i, by = "L" | "R"}, ...}}.
function M.resolve(values)
  local memo = {}
  local function solve(state, turn)
    local key = key_of(state, turn)
    local hit = memo[key]
    if hit then return hit end
    local best
    for i, v in ipairs(state) do
      if G.is_game(v) then
        for _, option in ipairs(turn == "L" and v.L or v.R) do
          local next_state = {}
          for j, w in ipairs(state) do next_state[j] = w end
          next_state[i] = option
          local sub = solve(next_state, turn == "L" and "R" or "L")
          local better
          if not best then better = true
          else
            local c = N.cmp(sub.total, best.total)
            if turn == "R" then c = -c end
            better = c > 0 or (c == 0 and hotter(v, state[best.card]) )
          end
          if better then
            best = { total = sub.total, card = i, option = option, rest = sub }
          end
        end
      end
    end
    if not best then
      local total = N.zero
      for _, v in ipairs(state) do total = N.add(total, v) end
      best = { total = total, finals = state }
    end
    memo[key] = best
    return best
  end

  local root = solve(values, "L")
  local moves, node, turn = {}, root, "L"
  while node.card do
    moves[#moves + 1] = { card = node.card, by = turn }
    node = node.rest
    turn = turn == "L" and "R" or "L"
  end
  return { total = root.total, finals = node.finals, moves = moves }
end

--- The ranks (0–15) a value can play as under the loose rule.
function M.ranks(value)
  local out = {}
  for r = 0, 15 do
    if G.acts_as(value, r) then out[#out + 1] = r end
  end
  return out
end

return M
