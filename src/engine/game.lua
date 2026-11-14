-- Short games whose leaves are numbers (src/engine/num.lua).
--
-- A value is a number (kind "n") or a game (kind "g", with option lists L and R). Every value this module
-- returns is canonical: a game equal to a number comes back as that number, and a game is reduced
-- (dominated options removed, reversible options bypassed) and interned, so equal finite games are the same
-- table. The one gap: an option that is a number with infinitely many options of its own (ω, ω−1, ω/2) is
-- never bypassed, so a game with such an option may not be fully reduced. Its value and every comparison
-- remain exact. See DESIGN.md § 11.
--
-- Loading: `loadfile(path)(E)` after num.lua registers the module as E.game, and returns it.

local E = ...
local N = assert(E.num, "load num.lua before game.lua")
local M = {}
E.game = M

local Game = {}
Game.__index = Game

local next_id = 0
local interned = setmetatable({}, { __mode = "v" })

local function is_num(v) return v.kind == "n" end
M.is_num = is_num
M.is_game = function(v) return v.kind == "g" end

local function key_of(v) return is_num(v) and N.encode(v) or v.key end
M.encode = key_of

local function memo_key(v) return is_num(v) and N.encode(v) or ("#" .. v.id) end

-- Memo tables. Temporary forms made during reduction get ids too, so the tables grow; reset() clears them.
local memo = {}
local function reset()
  memo = { le = {}, add = {}, neg = {}, ls = {}, rs = {}, thermo = {}, cool = {}, heat = {}, bday = {}, size = 0 }
end
reset()
M.reset = reset

local function remember(tbl, key, value)
  memo.size = memo.size + 1
  if memo.size > 500000 then reset() end
  tbl[key] = value
  return value
end

-- A game table that is not interned: a temporary form during reduction.
local function form(L, R)
  next_id = next_id + 1
  return setmetatable({ kind = "g", L = L, R = R, id = next_id }, Game)
end

-- The interned canonical game with these (already canonical, already reduced) options.
local function intern(L, R)
  table.sort(L, function(a, b) return key_of(a) < key_of(b) end)
  table.sort(R, function(a, b) return key_of(a) < key_of(b) end)
  local parts = {}
  for i, o in ipairs(L) do parts[i] = key_of(o) end
  local key = "{" .. table.concat(parts, ",") .. "|"
  parts = {}
  for i, o in ipairs(R) do parts[i] = key_of(o) end
  key = key .. table.concat(parts, ",") .. "}"
  local hit = interned[key]
  if hit then return hit end
  local g = form(L, R)
  g.key = key
  interned[key] = g
  return g
end

-- order -------------------------------------------------------------------------------------------------

-- G ≤ H. Between a number x and a game, Number Translation means only the game's options matter
-- (x ≤ H iff no H^R ≤ x), which is valid because games reaching here are never equal to numbers.
local function le(G, H)
  local gn, hn = is_num(G), is_num(H)
  if gn and hn then return N.le(G, H) end
  local key = memo_key(G) .. ":" .. memo_key(H)
  local hit = memo.le[key]
  if hit ~= nil then return hit end
  local result = true
  if not gn then
    for _, gl in ipairs(G.L) do
      if le(H, gl) then result = false; break end
    end
  end
  if result and not hn then
    for _, hr in ipairs(H.R) do
      if le(hr, G) then result = false; break end
    end
  end
  return remember(memo.le, key, result)
end
M.le = le

function M.eq(G, H) return le(G, H) and le(H, G) end
function M.lt(G, H) return le(G, H) and not le(H, G) end
--- Confused with: neither ≤ nor ≥.
function M.fuzzy(G, H) return not le(G, H) and not le(H, G) end

-- stops -------------------------------------------------------------------------------------------------

local left_stop, right_stop
left_stop = function(G)
  if is_num(G) then return G end
  local hit = memo.ls[G.id]
  if hit then return hit end
  local best
  for _, o in ipairs(G.L) do
    local v = right_stop(o)
    if not best or N.lt(best, v) then best = v end
  end
  return remember(memo.ls, G.id, best)
end
right_stop = function(G)
  if is_num(G) then return G end
  local hit = memo.rs[G.id]
  if hit then return hit end
  local best
  for _, o in ipairs(G.R) do
    local v = left_stop(o)
    if not best or N.lt(v, best) then best = v end
  end
  return remember(memo.rs, G.id, best)
end
M.left_stop, M.right_stop = left_stop, right_stop

-- canonical form ----------------------------------------------------------------------------------------

local function ord_lt(a, b) return a.m < b.m or (a.m == b.m and a.n < b.n) end

-- If some number fits between the options (every G^L ⧏ x ⧏ every G^R), G equals the simplest one
-- (Conway's simplicity theorem); otherwise G is not a number. For a game option A, the numbers x with
-- A ⧏ x are those above A's Right stop, plus the stop itself when A is not ≥ it.
local function as_number(L, R)
  local lo, lo_closed, hi, hi_closed
  for _, A in ipairs(L) do
    local v, closed
    if is_num(A) then v, closed = A, false
    else v = right_stop(A); closed = not le(v, A) end
    if not lo or N.lt(lo, v) then lo, lo_closed = v, closed
    elseif N.eq(lo, v) then lo_closed = lo_closed and closed end
  end
  for _, B in ipairs(R) do
    local v, closed
    if is_num(B) then v, closed = B, false
    else v = left_stop(B); closed = not le(B, v) end
    if not hi or N.lt(v, hi) then hi, hi_closed = v, closed
    elseif N.eq(hi, v) then hi_closed = hi_closed and closed end
  end
  if lo and hi then
    local c = N.cmp(lo, hi)
    if c > 0 then return nil end
    if c == 0 then return (lo_closed and hi_closed) and lo or nil end
  end
  local best = N.simplest_between(lo, hi)
  for _, edge in ipairs({ lo_closed and lo or false, hi_closed and hi or false }) do
    if edge and ord_lt(N.birthday(edge), N.birthday(best)) then best = edge end
  end
  return best
end

-- Left options of a number or game, as a list. nil when a number's options are an infinite family.
local function left_options(v)
  if not is_num(v) then return v.L end
  local l = N.options(v)
  if l == "inf" then return nil end
  return l and { l } or {}
end
local function right_options(v)
  if not is_num(v) then return v.R end
  local _, r = N.options(v)
  if r == "inf" then return nil end
  return r and { r } or {}
end

local function without_dominated(opts, better)
  local out = {}
  for i, a in ipairs(opts) do
    local dominated = false
    for j, b in ipairs(opts) do
      if i ~= j and better(b, a) and (not better(a, b) or j < i) then dominated = true; break end
    end
    if not dominated then out[#out + 1] = a end
  end
  return out
end

local function canon(L, R)
  local n = as_number(L, R)
  if n then return n end
  while true do
    L = without_dominated(L, function(b, a) return le(a, b) end)
    R = without_dominated(R, function(b, a) return le(b, a) end)
    local G = form(L, R)
    local changed = false
    -- A Left option A is reversible through A^R ≤ G: replace it by A^R's Left options.
    local newL = {}
    for _, A in ipairs(L) do
      local replaced = false
      if not changed then
        for _, AR in ipairs(right_options(A) or {}) do
          if le(AR, G) then
            local repl = left_options(AR)
            if repl then
              for _, o in ipairs(repl) do newL[#newL + 1] = o end
              replaced, changed = true, true
              break
            end
          end
        end
      end
      if not replaced then newL[#newL + 1] = A end
    end
    local newR = {}
    for _, B in ipairs(R) do
      local replaced = false
      if not changed then
        for _, BL in ipairs(left_options(B) or {}) do
          if le(G, BL) then
            local repl = right_options(BL)
            if repl then
              for _, o in ipairs(repl) do newR[#newR + 1] = o end
              replaced, changed = true, true
              break
            end
          end
        end
      end
      if not replaced then newR[#newR + 1] = B end
    end
    L, R = newL, newR
    if not changed then return intern(L, R) end
  end
end

--- The canonical value {L | R}. The options may be any canonical values; they are not modified.
function M.of(L, R)
  local l, r = {}, {}
  for i, o in ipairs(L) do l[i] = o end
  for i, o in ipairs(R) do r[i] = o end
  return canon(l, r)
end

M.num = N.new
function M.int(n) return N.new(n) end

-- arithmetic --------------------------------------------------------------------------------------------

local neg
neg = function(G)
  if is_num(G) then return N.neg(G) end
  local hit = memo.neg[G.id]
  if hit then return hit end
  local L, R = {}, {}
  for i, o in ipairs(G.R) do L[i] = neg(o) end
  for i, o in ipairs(G.L) do R[i] = neg(o) end
  return remember(memo.neg, G.id, intern(L, R))
end
M.neg = neg

local add
add = function(G, H)
  if is_num(G) and is_num(H) then return N.add(G, H) end
  if is_num(G) then G, H = H, G end
  local a, b = memo_key(G), memo_key(H)
  local key = a < b and (a .. "+" .. b) or (b .. "+" .. a)
  local hit = memo.add[key]
  if hit then return hit end
  local L, R = {}, {}
  if is_num(H) then
    if N.eq(H, N.zero) then return G end
    -- Number Translation: no move in a number is ever needed.
    for _, o in ipairs(G.L) do L[#L + 1] = add(o, H) end
    for _, o in ipairs(G.R) do R[#R + 1] = add(o, H) end
  else
    for _, o in ipairs(G.L) do L[#L + 1] = add(o, H) end
    for _, o in ipairs(H.L) do L[#L + 1] = add(G, o) end
    for _, o in ipairs(G.R) do R[#R + 1] = add(o, H) end
    for _, o in ipairs(H.R) do R[#R + 1] = add(G, o) end
  end
  return remember(memo.add, key, canon(L, R))
end
M.add = add
function M.sub(G, H) return add(G, neg(H)) end

--- The sum of a list of values (0 for an empty list).
function M.sum(list)
  local s = N.zero
  for _, v in ipairs(list) do s = add(s, v) end
  return s
end

-- thermography ------------------------------------------------------------------------------------------
--
-- A wall is a piecewise-linear function of the temperature t ≥ 0: a list of segments {t, v, s}, each one
-- f(t) = v + s·(t − t₀) from its start t₀ until the next segment. Slopes are −1, 0 or 1, so every
-- breakpoint is a dyadic, or a k·ω + x for games with transfinite leaves.

local function lin(v, s, dt)
  if s == 0 then return v end
  if s == 1 then return N.add(v, dt) end
  if s == -1 then return N.sub(v, dt) end
  error("thermograph slope out of range")
end

local function eval(f, t)
  local seg = f[1]
  for i = 2, #f do
    if N.le(f[i].t, t) then seg = f[i] else break end
  end
  return lin(seg.v, seg.s, N.sub(t, seg.t))
end

local function const(v) return { { t = N.zero, v = v, s = 0 } } end

local function slope_at(f, t)
  local s = f[1].s
  for i = 2, #f do
    if N.le(f[i].t, t) then s = f[i].s else break end
  end
  return s
end

-- f(t) + ds·t.
local function tilt(f, ds)
  local out = {}
  for i, seg in ipairs(f) do
    out[i] = { t = seg.t, v = lin(seg.v, ds, seg.t), s = seg.s + ds }
  end
  return out
end

local function simplify(f)
  local out = {}
  for _, seg in ipairs(f) do
    local last = out[#out]
    if not (last and last.s == seg.s and N.eq(lin(last.v, last.s, N.sub(seg.t, last.t)), seg.v)) then
      out[#out + 1] = seg
    end
  end
  return out
end

-- Pointwise max (pick = 1) or min (pick = -1) of two walls.
local function combine(f, g, pick)
  local starts, seen = {}, {}
  for _, h in ipairs({ f, g }) do
    for _, seg in ipairs(h) do
      local k = N.encode(seg.t)
      if not seen[k] then seen[k] = true; starts[#starts + 1] = seg.t end
    end
  end
  table.sort(starts, N.lt)
  local out = {}
  local function emit(t, fv, gv, fs, gs)
    local c = N.cmp(fv, gv)
    local take_f = (c * pick > 0) or (c == 0 and fs * pick >= gs * pick)
    out[#out + 1] = take_f and { t = t, v = fv, s = fs } or { t = t, v = gv, s = gs }
  end
  for i, b in ipairs(starts) do
    local fv, gv = eval(f, b), eval(g, b)
    local fs, gs = slope_at(f, b), slope_at(g, b)
    emit(b, fv, gv, fs, gs)
    -- Do f and g cross inside this interval?
    local ds = fs - gs
    if ds ~= 0 then
      local d = N.sub(gv, fv) -- crossing where d = ds·(t − b)
      local dt
      if ds == 1 then dt = d elseif ds == -1 then dt = N.neg(d)
      elseif ds == 2 then dt = N.half(d) elseif ds == -2 then dt = N.half(N.neg(d))
      else error("thermograph slopes differ by more than 2") end
      if N.lt(N.zero, dt) then
        local t = N.add(b, dt)
        local nxt = starts[i + 1]
        if not nxt or N.lt(t, nxt) then
          emit(t, eval(f, t), eval(g, t), fs, gs)
          -- At the crossing the values agree; the side whose slope wins from here on takes over.
          local last = out[#out]
          if pick * fs >= pick * gs then last.s = fs else last.s = gs end
        end
      end
    end
  end
  return simplify(out)
end

local function combine_all(walls, pick)
  local acc = walls[1]
  for i = 2, #walls do acc = combine(acc, walls[i], pick) end
  return acc
end

local thermograph
--- The thermograph of a canonical value: {left = wall, right = wall, temperature = num, mean = num}. A
--- number has temperature −1 (ogdoad's convention) and its own value as the mean.
thermograph = function(G)
  if is_num(G) then return { left = const(G), right = const(G), temperature = N.new(-1), mean = G } end
  local hit = memo.thermo[G.id]
  if hit then return hit end
  local lefts, rights = {}, {}
  for i, o in ipairs(G.L) do lefts[i] = tilt(thermograph(o).right, -1) end
  for i, o in ipairs(G.R) do rights[i] = tilt(thermograph(o).left, 1) end
  local raw_l, raw_r = combine_all(lefts, 1), combine_all(rights, -1)
  -- The temperature is the first t where the walls meet (l − r reaches 0); above it both are the mast.
  local starts, seen = {}, {}
  for _, h in ipairs({ raw_l, raw_r }) do
    for _, seg in ipairs(h) do
      local k = N.encode(seg.t)
      if not seen[k] then seen[k] = true; starts[#starts + 1] = seg.t end
    end
  end
  table.sort(starts, N.lt)
  local tau
  for i, b in ipairs(starts) do
    local gap = N.sub(eval(raw_l, b), eval(raw_r, b))
    if N.le(gap, N.zero) then tau = b; break end
    local closing = slope_at(raw_r, b) - slope_at(raw_l, b)
    if closing > 0 then
      local dt = closing == 1 and gap or (closing == 2 and N.half(gap) or error("bad thermograph slopes"))
      local t = N.add(b, dt)
      if not starts[i + 1] or N.le(t, starts[i + 1]) then tau = t; break end
    end
  end
  assert(tau, "thermograph walls never meet")
  local mast = eval(raw_l, tau)
  local function cut(f)
    local out = {}
    for _, seg in ipairs(f) do
      if N.lt(seg.t, tau) then out[#out + 1] = seg end
    end
    out[#out + 1] = { t = tau, v = mast, s = 0 }
    return simplify(out)
  end
  local result = { left = cut(raw_l), right = cut(raw_r), temperature = tau, mean = mast }
  return remember(memo.thermo, G.id, result)
end
M.thermograph = thermograph

function M.temperature(G) return thermograph(G).temperature end
function M.mean(G) return thermograph(G).mean end

--- Cool G by t: G_t = {G^L_t − t | G^R_t + t}, until t passes G's temperature, where G freezes at its mean.
local cool
cool = function(G, t)
  if is_num(G) then return G end
  local key = G.id .. "@" .. N.encode(t)
  local hit = memo.cool[key]
  if hit then return hit end
  local th = thermograph(G)
  if N.lt(th.temperature, t) then return remember(memo.cool, key, th.mean) end
  local L, R = {}, {}
  for i, o in ipairs(G.L) do L[i] = M.sub(cool(o, t), t) end
  for i, o in ipairs(G.R) do R[i] = add(cool(o, t), t) end
  return remember(memo.cool, key, canon(L, R))
end
M.cool = cool

--- Heat G by t: ∫^t G = {t + ∫G^L | ∫G^R − t}. Numbers do not heat.
local heat
heat = function(G, t)
  if is_num(G) then return G end
  local key = G.id .. "@" .. N.encode(t)
  local hit = memo.heat[key]
  if hit then return hit end
  local L, R = {}, {}
  for i, o in ipairs(G.L) do L[i] = add(heat(o, t), t) end
  for i, o in ipairs(G.R) do R[i] = M.sub(heat(o, t), t) end
  return remember(memo.heat, key, canon(L, R))
end
M.heat = heat

-- other invariants --------------------------------------------------------------------------------------

local birthday
--- The birthday as an ordinal {m, n} (ω·m + n).
birthday = function(G)
  if is_num(G) then return N.birthday(G) end
  local hit = memo.bday[G.id]
  if hit then return hit end
  local best = { m = 0, n = 0 }
  for _, side in ipairs({ G.L, G.R }) do
    for _, o in ipairs(side) do
      local b = birthday(o)
      if ord_lt(best, b) then best = b end
    end
  end
  return remember(memo.bday, G.id, { m = best.m, n = best.n + 1 })
end
M.birthday = birthday

--- Whether G can play as rank r under the loose rule: G equals r or is confused with it.
function M.acts_as(G, r)
  if not N.is(r) then r = N.new(r) end
  return le(G, r) == le(r, G)
end

-- notation ----------------------------------------------------------------------------------------------

--- Parse the notation encode() writes: numbers as in num.lua, games as {a,b|c}.
function M.parse(s)
  local pos = 1
  local value
  local function skip() while s:sub(pos, pos) == " " do pos = pos + 1 end end
  local function list(stop)
    local out = {}
    skip()
    if s:sub(pos, pos) == stop then return out end
    while true do
      out[#out + 1] = value()
      skip()
      local c = s:sub(pos, pos)
      if c == "," then pos = pos + 1 elseif c == stop then return out
      else error("bad game notation at " .. pos .. ": " .. s) end
    end
  end
  value = function()
    skip()
    if s:sub(pos, pos) == "{" then
      pos = pos + 1
      local L = list("|")
      pos = pos + 1
      local R = list("}")
      pos = pos + 1
      return M.of(L, R)
    end
    local start = pos
    while pos <= #s and not s:sub(pos, pos):match("[,|}%s]") do pos = pos + 1 end
    return N.parse(s:sub(start, pos - 1))
  end
  local v = value()
  skip()
  assert(pos > #s, "trailing text in game notation: " .. s)
  return v
end

Game.__tostring = key_of

return M
