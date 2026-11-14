-- Surreal numbers of the form k·ω + x, where k and x are dyadic rationals.
--
-- This is every number the mod can build: the finite dyadics, ω with its multiples and halves, and finite
-- shifts of those. Lua numbers are IEEE doubles, which are exactly the dyadics that fit in 53 bits, so
-- k and x are stored as plain numbers; operations check that they stay exact.
--
-- Order is lexicographic, k first. Sign expansions are run lists {s = ±1, m = .., n = ..}, where a run's
-- length is the ordinal ω·m + n. A number's expansion is k's signs, each repeated ω times, followed by x's
-- signs (Gonshor). Simplest-number arithmetic works on these expansions.
--
-- Loading: `loadfile(path)(E)` registers the module as E.num, and returns it.

local E = ...
local M = {}
E.num = M

local floor, abs = math.floor, math.abs

local Num = {}
Num.__index = Num

local function exact(v)
  assert(v == v and v ~= math.huge and v ~= -math.huge, "number left the dyadics")
  assert(abs(v) < 2 ^ 52, "number out of exact range")
  return v
end

--- k·ω + x. `k` defaults to 0.
function M.new(x, k)
  return setmetatable({ kind = "n", x = exact(x), k = exact(k or 0) }, Num)
end
local new = M.new

M.zero = new(0)
M.one = new(1)
M.omega = new(0, 1)

function M.is(v) return type(v) == "table" and v.kind == "n" end

-- order -------------------------------------------------------------------------------------------------

function M.cmp(a, b)
  if a.k ~= b.k then return a.k < b.k and -1 or 1 end
  if a.x ~= b.x then return a.x < b.x and -1 or 1 end
  return 0
end
local cmp = M.cmp

function M.eq(a, b) return a.k == b.k and a.x == b.x end
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

function M.add(a, b) return new(add_exact(a.x, b.x), add_exact(a.k, b.k)) end
function M.neg(a) return new(-a.x, -a.k) end
function M.sub(a, b) return M.add(a, M.neg(b)) end
function M.half(a) return new(a.x / 2, a.k / 2) end
function M.from_int(n) return new(n) end

function M.is_finite(a) return a.k == 0 end
function M.is_integer(a) return a.k == 0 and a.x == floor(a.x) end
--- The finite part, which is what a card scores in chips.
function M.finite(a) return a.x end

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

-- ordinals ω·m + n and run lists ------------------------------------------------------------------------

local function ord_add(m1, n1, m2, n2)
  if m2 > 0 then return m1 + m2, n2 end
  return m1, n1 + n2
end

-- Append a run, merging it into the last run when the signs agree.
local function push(runs, s, m, n)
  if m == 0 and n == 0 then return runs end
  local last = runs[#runs]
  if last and last.s == s then
    last.m, last.n = ord_add(last.m, last.n, m, n)
  else
    runs[#runs + 1] = { s = s, m = m, n = n }
  end
  return runs
end

local function copy_runs(runs, from)
  local out = {}
  for i = from or 1, #runs do push(out, runs[i].s, runs[i].m, runs[i].n) end
  return out
end

--- The sign expansion of a number, as runs.
function M.signs(a)
  local runs = {}
  for _, s in ipairs(dyadic_signs(a.k)) do push(runs, s, 1, 0) end
  for _, s in ipairs(dyadic_signs(a.x)) do push(runs, s, 0, 1) end
  return runs
end

--- The number with this sign expansion. It must have the shape of one: runs of whole ω-multiples first,
--- then finite runs.
function M.from_signs(runs)
  local ks, xs, finite_phase = {}, {}, false
  for _, r in ipairs(runs) do
    if r.m > 0 then
      assert(not finite_phase, "sign expansion is outside k·ω + x")
      for _ = 1, r.m do ks[#ks + 1] = r.s end
    end
    if r.n > 0 then
      finite_phase = true
      for _ = 1, r.n do xs[#xs + 1] = r.s end
    end
  end
  return new(dyadic_from(xs), dyadic_from(ks))
end

--- The birthday, the length of the sign expansion, as an ordinal {m = .., n = ..} meaning ω·m + n.
function M.birthday(a)
  local m, n = 0, 0
  for _, r in ipairs(M.signs(a)) do m, n = ord_add(m, n, r.m, r.n) end
  return { m = m, n = n }
end

-- Longest common prefix of two run lists, and what is left of each.
local function lcp(A, B)
  local P = {}
  local i = 1
  while A[i] and B[i] and A[i].s == B[i].s do
    local a, b = A[i], B[i]
    if a.m == b.m and a.n == b.n then
      push(P, a.s, a.m, a.n)
      i = i + 1
    else
      local a_longer = a.m > b.m or (a.m == b.m and a.n > b.n)
      local long, short = a_longer and a or b, a_longer and b or a
      push(P, a.s, short.m, short.n)
      -- left subtraction: short + rest = long
      local rest_m, rest_n
      if long.m > short.m then rest_m, rest_n = long.m - short.m, long.n
      else rest_m, rest_n = 0, long.n - short.n end
      local long_rest = push({}, long.s, rest_m, rest_n)
      local list = a_longer and A or B
      for j = i + 1, #list do push(long_rest, list[j].s, list[j].m, list[j].n) end
      local short_rest = copy_runs(a_longer and B or A, i + 1)
      if a_longer then return P, long_rest, short_rest end
      return P, short_rest, long_rest
    end
  end
  return P, copy_runs(A, i), copy_runs(B, i)
end

-- Drop the first sign of a run list (1 + ω·m + n = ω·m + n when m > 0).
local function drop_one(runs)
  local out = copy_runs(runs)
  local r = out[1]
  if r.m == 0 then
    r.n = r.n - 1
    if r.n == 0 then table.remove(out, 1) end
  end
  return out
end

-- The shortest sign sequence below / above the sequence c.
local function shortest_below(c)
  if #c == 0 then return { { s = -1, m = 0, n = 1 } } end
  if c[1].s == 1 then return {} end
  local r = c[1]
  if #c > 1 then return { { s = -1, m = r.m, n = r.n } } end
  return { { s = -1, m = r.m, n = r.n + 1 } }
end

local function shortest_above(c)
  if #c == 0 then return { { s = 1, m = 0, n = 1 } } end
  if c[1].s == -1 then return {} end
  local r = c[1]
  if #c > 1 then return { { s = 1, m = r.m, n = r.n } } end
  return { { s = 1, m = r.m, n = r.n + 1 } }
end

local function concat(...)
  local out = {}
  for _, runs in ipairs({ ... }) do
    for _, r in ipairs(runs) do push(out, r.s, r.m, r.n) end
  end
  return out
end

--- The simplest number strictly between a and b. Either may be nil for an open end, so
--- simplest_between(x, nil) is {x|} and simplest_between(nil, nil) is 0.
function M.simplest_between(a, b)
  if a == nil and b == nil then return M.zero end
  if a == nil then return M.from_signs(shortest_below(M.signs(b))) end
  if b == nil then return M.from_signs(shortest_above(M.signs(a))) end
  assert(M.lt(a, b), "simplest_between needs a < b")
  local P, ra, rb = lcp(M.signs(a), M.signs(b))
  if #ra > 0 and #rb > 0 then return M.from_signs(P) end
  if #ra == 0 then
    return M.from_signs(concat(P, { { s = 1, m = 0, n = 1 } }, shortest_below(drop_one(rb))))
  end
  return M.from_signs(concat(P, { { s = -1, m = 0, n = 1 } }, shortest_above(drop_one(ra))))
end

--- A number's canonical options: its longest prefix followed by + (Left) and by − (Right). Each is a
--- number, nil when there is none, or "inf" when the options form an infinite family with no best member
--- (ω's Left options are 0, 1, 2, …).
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
        if prefix[i].m == 0 and prefix[i].n == 0 then prefix[i] = nil end
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

--- ASCII notation: "3", "-7/2", "w", "-w", "2w", "w/2", "3w/4", "w+3", "w/2-1/2".
function M.encode(a)
  if a.k == 0 then return dyadic_str(a.x) end
  local q = 1
  while a.k * q ~= floor(a.k * q) do q = q * 2 end
  local p = a.k * q
  local s = (p == 1 and "") or (p == -1 and "-") or int_str(p)
  s = s .. "w" .. (q > 1 and ("/" .. int_str(q)) or "")
  if a.x > 0 then s = s .. "+" .. dyadic_str(a.x) elseif a.x < 0 then s = s .. dyadic_str(a.x) end
  return s
end

-- "p" or "p/q" with an optional sign.
local function parse_dyadic(s)
  s = s:gsub("^%+", "")
  local p, q = s:match("^(-?%d+)/(%d+)$")
  if p then return tonumber(p) / tonumber(q) end
  local v = tonumber(s)
  return assert(v, "bad number: " .. s) and v
end

function M.parse(s)
  local coef, den, rest = s:match("^([+-]?%d*)w/?(%d*)(.*)$")
  if not coef then return new(parse_dyadic(s)) end
  local k = (coef == "" or coef == "+") and 1 or (coef == "-" and -1 or tonumber(coef))
  if den ~= "" then k = k / tonumber(den) end
  local x = rest == "" and 0 or parse_dyadic(rest)
  return new(x, k)
end

Num.__tostring = M.encode

return M
