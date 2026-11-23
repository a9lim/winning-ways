-- Surreal numbers of the form a·ω² + k·ω + x, where a, k and x are dyadic rationals.
--
-- This is every number the mod can build: the finite dyadics, ω and ω² with their multiples and halves, and
-- sums of those. a, k and x are stored as plain Lua doubles (fields k2, k, x), restricted to a grid that makes
-- every operation exact: multiples of 2^-32 below 2^20 in magnitude. That needs 52 bits, inside a double's 53,
-- so sums and differences of grid values are exact. Anything finer or larger (a 33rd nested Cut between
-- neighbours, say) is rejected when it is made, never rounded.
--
-- Order is lexicographic, a first. Sign expansions are run lists {s = ±1, l = .., m = .., n = ..}, where a
-- run's length is the ordinal ω²·l + ω·m + n. A number's expansion is a's signs, each repeated ω² times, then
-- k's, each repeated ω times, then x's (Gonshor: the terms of the normal form in turn, each sign of ω^d·r
-- repeated ω^d times). Simplest-number arithmetic works on these expansions.
--
-- Loading: `loadfile(path)(E)` registers the module as E.num, and returns it.

local E = ...
local M = {}
E.num = M

local floor, abs = math.floor, math.abs

local Num = {}
Num.__index = Num

local GRAIN, LIMIT = 2 ^ 32, 2 ^ 20
M.GRAIN, M.LIMIT = GRAIN, LIMIT

local function exact(v)
  assert(type(v) == "number" and v == v, "not a number")
  assert(abs(v) < LIMIT, "number out of the engine's range (|x| < 2^20)")
  assert(floor(v * GRAIN) == v * GRAIN, "number finer than the engine's grain (2^-32)")
  return v
end

--- a·ω² + k·ω + x, as new(x, k, a). `k` and `a` default to 0.
function M.new(x, k, a)
  return setmetatable({ kind = "n", x = exact(x), k = exact(k or 0), k2 = exact(a or 0) }, Num)
end
local new = M.new

M.zero = new(0)
M.one = new(1)
M.omega = new(0, 1)
M.omega2 = new(0, 0, 1)

function M.is(v) return type(v) == "table" and v.kind == "n" end

-- order -------------------------------------------------------------------------------------------------

function M.cmp(a, b)
  if a.k2 ~= b.k2 then return a.k2 < b.k2 and -1 or 1 end
  if a.k ~= b.k then return a.k < b.k and -1 or 1 end
  if a.x ~= b.x then return a.x < b.x and -1 or 1 end
  return 0
end
local cmp = M.cmp

function M.eq(a, b) return a.k2 == b.k2 and a.k == b.k and a.x == b.x end
function M.lt(a, b) return cmp(a, b) < 0 end
function M.le(a, b) return cmp(a, b) <= 0 end
function M.max(a, b) return cmp(a, b) >= 0 and a or b end
function M.min(a, b) return cmp(a, b) <= 0 and a or b end

-- arithmetic --------------------------------------------------------------------------------------------

local function add_exact(a, b)
  local s = a + b
  assert(s - a == b and s - b == a, "addition lost precision")
  return s
end

function M.add(a, b) return new(add_exact(a.x, b.x), add_exact(a.k, b.k), add_exact(a.k2, b.k2)) end
function M.neg(a) return new(-a.x, -a.k, -a.k2) end
function M.sub(a, b) return M.add(a, M.neg(b)) end
function M.half(a) return new(a.x / 2, a.k / 2, a.k2 / 2) end
function M.from_int(n) return new(n) end

function M.is_finite(a) return a.k == 0 and a.k2 == 0 end
function M.is_integer(a) return M.is_finite(a) and a.x == floor(a.x) end
--- The finite part, which is what a card scores in chips.
function M.finite(a) return a.x end

--- The degree of the leading term: 2 for a·ω² + .., 1 for k·ω + x, 0 for a finite number (0 included).
function M.degree(a)
  if a.k2 ~= 0 then return 2 end
  if a.k ~= 0 then return 1 end
  return 0
end
--- The coefficient of ω^d (d = 0, 1, 2).
function M.coef(a, d)
  if d == 2 then return a.k2 elseif d == 1 then return a.k end
  return a.x
end
--- The leading term alone: 3ω² + ω − 1 leads with 3ω².
function M.lead(a)
  local d = M.degree(a)
  if d == 2 then return new(0, 0, a.k2) elseif d == 1 then return new(0, a.k) end
  return new(a.x)
end
--- ω^d for d = 0, 1, 2.
function M.power(d)
  if d == 2 then return M.omega2 elseif d == 1 then return M.omega end
  return M.one
end
--- 1 for a positive infinite number, −1 for a negative one, 0 for a finite one.
function M.infinite_sign(a)
  local d = M.degree(a)
  if d == 0 then return 0 end
  return M.coef(a, d) > 0 and 1 or -1
end
--- Is this number an ordinal: every coefficient a whole number, none negative (ω + 14, 2ω², 7)?
function M.is_ordinal(a)
  for _, c in ipairs({ a.k2, a.k, a.x }) do
    if c < 0 or c ~= floor(c) then return false end
  end
  return true
end

-- dyadic sign expansions (finite) -----------------------------------------------------------------------

-- The signs of a finite dyadic, as an array of ±1.
local function dyadic_signs(v)
  local out = {}
  if v == 0 then return out end
  local s = v > 0 and 1 or -1
  local a = abs(v)
  local whole = floor(a)
  if a == whole then
    for i = 1, whole do out[i] = s end
    return out
  end
  for i = 1, whole + 1 do out[i] = s end
  local cur, step = whole + 1, 0.5
  while cur ~= a do
    if a < cur then out[#out + 1] = -s; cur = cur - step
    else out[#out + 1] = s; cur = cur + step end
    step = step / 2
  end
  return out
end

-- The dyadic with these signs.
local function dyadic_from(signs)
  local n = #signs
  if n == 0 then return 0 end
  local v, i, first = 0, 1, signs[1]
  while i <= n and signs[i] == first do v = v + first; i = i + 1 end
  local step = 0.5
  while i <= n do v = v + signs[i] * step; step = step / 2; i = i + 1 end
  return v
end

-- ordinals ω²·l + ω·m + n and run lists ------------------------------------------------------------------

-- Ordinal addition, which absorbs: (ω + 3) + ω = ω·2, and ω + ω² = ω².
local function ord_add(l1, m1, n1, l2, m2, n2)
  if l2 > 0 then return l1 + l2, m2, n2 end
  if m2 > 0 then return l1, m1 + m2, n2 end
  return l1, m1, n1 + n2
end

--- Is the ordinal a (a table {l, m, n}, ω²·l + ω·m + n) less than b?
function M.ord_lt(a, b)
  if a.l ~= b.l then return a.l < b.l end
  if a.m ~= b.m then return a.m < b.m end
  return a.n < b.n
end
--- The ordinal after a.
function M.ord_succ(a) return { l = a.l, m = a.m, n = a.n + 1 } end

-- Append a run, merging it into the last run when the signs agree.
local function push(runs, s, l, m, n)
  if l == 0 and m == 0 and n == 0 then return runs end
  local last = runs[#runs]
  if last and last.s == s then
    last.l, last.m, last.n = ord_add(last.l, last.m, last.n, l, m, n)
  else
    runs[#runs + 1] = { s = s, l = l, m = m, n = n }
  end
  return runs
end

local function copy_runs(runs, from)
  local out = {}
  for i = from or 1, #runs do push(out, runs[i].s, runs[i].l, runs[i].m, runs[i].n) end
  return out
end

--- The sign expansion of a number, as runs.
function M.signs(a)
  local runs = {}
  for _, s in ipairs(dyadic_signs(a.k2)) do push(runs, s, 1, 0, 0) end
  for _, s in ipairs(dyadic_signs(a.k)) do push(runs, s, 0, 1, 0) end
  for _, s in ipairs(dyadic_signs(a.x)) do push(runs, s, 0, 0, 1) end
  return runs
end

--- The number with this sign expansion. It must have the shape of one: runs of whole ω²-multiples first, then
--- of whole ω-multiples, then finite runs.
function M.from_signs(runs)
  local as, ks, xs = {}, {}, {}
  local low = 2 -- the highest degree still allowed
  for _, r in ipairs(runs) do
    if r.l > 0 then
      assert(low == 2, "sign expansion is outside a·ω² + k·ω + x")
      for _ = 1, r.l do as[#as + 1] = r.s end
    end
    if r.m > 0 then
      assert(low >= 1, "sign expansion is outside a·ω² + k·ω + x")
      for _ = 1, r.m do ks[#ks + 1] = r.s end
      low = 1
    end
    if r.n > 0 then
      for _ = 1, r.n do xs[#xs + 1] = r.s end
      low = 0
    end
  end
  return new(dyadic_from(xs), dyadic_from(ks), dyadic_from(as))
end

--- The birthday, the length of the sign expansion, as an ordinal {l = .., m = .., n = ..}: ω²·l + ω·m + n.
function M.birthday(a)
  local l, m, n = 0, 0, 0
  for _, r in ipairs(M.signs(a)) do l, m, n = ord_add(l, m, n, r.l, r.m, r.n) end
  return { l = l, m = m, n = n }
end

-- Longest common prefix of two run lists, and what is left of each.
local function lcp(A, B)
  local P = {}
  local i = 1
  while A[i] and B[i] and A[i].s == B[i].s do
    local a, b = A[i], B[i]
    if a.l == b.l and a.m == b.m and a.n == b.n then
      push(P, a.s, a.l, a.m, a.n)
      i = i + 1
    else
      local a_longer = M.ord_lt(b, a)
      local long, short = a_longer and a or b, a_longer and b or a
      push(P, a.s, short.l, short.m, short.n)
      -- left subtraction: short + rest = long
      local rl, rm, rn
      if long.l > short.l then rl, rm, rn = long.l - short.l, long.m, long.n
      elseif long.m > short.m then rl, rm, rn = 0, long.m - short.m, long.n
      else rl, rm, rn = 0, 0, long.n - short.n end
      local long_rest = push({}, long.s, rl, rm, rn)
      local list = a_longer and A or B
      for j = i + 1, #list do push(long_rest, list[j].s, list[j].l, list[j].m, list[j].n) end
      local short_rest = copy_runs(a_longer and B or A, i + 1)
      if a_longer then return P, long_rest, short_rest end
      return P, short_rest, long_rest
    end
  end
  return P, copy_runs(A, i), copy_runs(B, i)
end

-- Drop the first sign of a run list (1 + α = α for an infinite α).
local function drop_one(runs)
  local out = copy_runs(runs)
  local r = out[1]
  if r.l == 0 and r.m == 0 then
    r.n = r.n - 1
    if r.n == 0 then table.remove(out, 1) end
  end
  return out
end

-- The shortest sign sequence below / above the sequence c.
local function shortest_below(c)
  if #c == 0 then return { { s = -1, l = 0, m = 0, n = 1 } } end
  if c[1].s == 1 then return {} end
  local r = c[1]
  if #c > 1 then return { { s = -1, l = r.l, m = r.m, n = r.n } } end
  return { { s = -1, l = r.l, m = r.m, n = r.n + 1 } }
end

local function shortest_above(c)
  if #c == 0 then return { { s = 1, l = 0, m = 0, n = 1 } } end
  if c[1].s == -1 then return {} end
  local r = c[1]
  if #c > 1 then return { { s = 1, l = r.l, m = r.m, n = r.n } } end
  return { { s = 1, l = r.l, m = r.m, n = r.n + 1 } }
end

local function concat(...)
  local out = {}
  for _, runs in ipairs({ ... }) do
    for _, r in ipairs(runs) do push(out, r.s, r.l, r.m, r.n) end
  end
  return out
end

--- The simplest number strictly between a and b. Either may be nil for an open end, so
--- simplest_between(x, nil) is {x|} and simplest_between(nil, nil) is 0.
function M.simplest_between(a, b)
  if a == nil and b == nil then return M.zero end
  local r
  if a == nil then r = M.from_signs(shortest_below(M.signs(b)))
  elseif b == nil then r = M.from_signs(shortest_above(M.signs(a)))
  else
    assert(M.lt(a, b), "simplest_between needs a < b")
    local P, ra, rb = lcp(M.signs(a), M.signs(b))
    if #ra > 0 and #rb > 0 then r = M.from_signs(P)
    elseif #ra == 0 then r = M.from_signs(concat(P, { { s = 1, l = 0, m = 0, n = 1 } }, shortest_below(drop_one(rb))))
    else r = M.from_signs(concat(P, { { s = -1, l = 0, m = 0, n = 1 } }, shortest_above(drop_one(ra)))) end
  end
  -- The grid check in new() already refuses a result too fine to store; this guards the cut itself.
  assert((a == nil or M.lt(a, r)) and (b == nil or M.lt(r, b)), "simplest_between left its interval")
  return r
end

--- A number's canonical options: its longest prefix followed by + (Left) and by − (Right). Each is a
--- number, nil when there is none, or "inf" when the options form an infinite family with no best member
--- (ω's Left options are 0, 1, 2, …; ω²'s are ω·m + n).
function M.options(a)
  local runs = M.signs(a)
  local function side(sign)
    -- The last run with this sign, and everything before it.
    for i = #runs, 1, -1 do
      local r = runs[i]
      if r.s == sign then
        if r.n == 0 then return "inf" end
        local prefix = copy_runs(runs)
        for _ = #prefix, i + 1, -1 do prefix[#prefix] = nil end
        prefix[i].n = prefix[i].n - 1
        if prefix[i].l == 0 and prefix[i].m == 0 and prefix[i].n == 0 then prefix[i] = nil end
        return M.from_signs(prefix)
      end
    end
    return nil
  end
  return side(1), side(-1)
end

-- notation ----------------------------------------------------------------------------------------------

local function int_str(v) return ("%.0f"):format(v) end

-- "p/q" for a dyadic, or "p" when it is an integer.
local function dyadic_str(v)
  local q = 1
  while v * q ~= floor(v * q) do q = q * 2 end
  if q == 1 then return int_str(v) end
  return int_str(v * q) .. "/" .. int_str(q)
end
M.dyadic_str = dyadic_str

-- One term of the notation: "w^2", "-3w/4", "+w", "5/8"; `first` leaves a positive term unsigned.
local function term(c, sym, first)
  if sym == "" then return (c > 0 and not first and "+" or "") .. dyadic_str(c) end
  local q = 1
  while c * q ~= floor(c * q) do q = q * 2 end
  local p = c * q
  local s = (p == 1 and "") or (p == -1 and "-") or int_str(p)
  if p > 0 and not first then s = "+" .. s end
  return s .. sym .. (q > 1 and ("/" .. int_str(q)) or "")
end

--- ASCII notation: "3", "-7/2", "w", "-w", "2w", "w/2", "3w/4", "w+3", "w/2-1/2", "w^2", "2w^2+w-3", "w^2/2".
function M.encode(a)
  local out = {}
  for _, t in ipairs({ { a.k2, "w^2" }, { a.k, "w" }, { a.x, "" } }) do
    if t[1] ~= 0 then out[#out + 1] = term(t[1], t[2], #out == 0) end
  end
  if #out == 0 then return "0" end
  return table.concat(out)
end

local function power_of_two(q)
  if q < 1 then return false end
  while q > 1 do
    if q % 2 ~= 0 then return false end
    q = q / 2
  end
  return true
end

--- Read the notation encode() writes. Each term is a sign, a whole coefficient, w or w^2, and a denominator that
--- must be a power of two, so "1/3" and "w/3" are rejected, not approximated.
function M.parse(s)
  local c = { 0, 0, 0 }
  local pos, first = 1, true
  assert(#s > 0, "bad number: empty")
  while pos <= #s do
    local sign = 1
    local ch = s:sub(pos, pos)
    if ch == "+" or ch == "-" then
      sign = ch == "-" and -1 or 1
      pos = pos + 1
    else
      assert(first, "bad number: " .. s)
    end
    local digits = s:match("^%d+", pos)
    if digits then pos = pos + #digits end
    local d = 0
    if s:sub(pos, pos) == "w" then
      pos, d = pos + 1, 1
      if s:sub(pos, pos + 1) == "^2" then pos, d = pos + 2, 2 end
    end
    assert(digits or d > 0, "bad number: " .. s)
    local v = digits and tonumber(digits) or 1
    if s:sub(pos, pos) == "/" then
      local den = s:match("^%d+", pos + 1)
      assert(den and power_of_two(tonumber(den)), "not a dyadic: " .. s)
      pos = pos + 1 + #den
      v = v / tonumber(den)
    end
    c[d + 1] = c[d + 1] + sign * v
    first = false
  end
  return new(c[1], c[2], c[3])
end

Num.__tostring = M.encode

return M
