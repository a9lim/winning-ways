-- Nim arithmetic on the ranks 0–15, which form the field F₁₆ (C = 12, Q = 13, K = 14, Ace = 15).
--
-- Nim-addition is XOR. Nim-multiplication follows Conway's rules: for distinct Fermat 2-powers (2, 4, 16, …)
-- the nim-product is the ordinary product, and a Fermat 2-power F squares to 3F/2. 15 generates the
-- multiplicative group, so every nonzero rank is a power of 15 and has a discrete log.
--
-- Loading: `loadfile(path)(E)` registers the module as E.nim, and returns it.

local E = ...
local M = {}
E.nim = M

local bit = require("bit")
local bxor, band, rshift, lshift = bit.bxor, bit.band, bit.rshift, bit.lshift

M.add = bxor

function M.sum(list)
  local s = 0
  for _, v in ipairs(list) do s = bxor(s, v) end
  return s
end

-- Nim-product of a, b < 2^(2^k) with half = 2^(k-1) bits: split into halves on the Fermat 2-power D.
local function mul(a, b, bits)
  if a < 2 or b < 2 then return a * b end
  local half = bits / 2
  local mask = lshift(1, half) - 1
  local a1, a0 = rshift(a, half), band(a, mask)
  local b1, b0 = rshift(b, half), band(b, mask)
  local hi = mul(a1, b1, half)
  local mid = bxor(mul(a1, b0, half), mul(a0, b1, half))
  local lo = mul(a0, b0, half)
  -- D² = D ⊕ D/2 (as nimbers, D·D = 3D/2), so (a1·D + a0)(b1·D + b0)
  --    = (hi ⊕ mid)·D ⊕ hi·(D/2) ⊕ lo.
  local d_half = lshift(1, half - 1)
  return bxor(lshift(bxor(hi, mid), half), bxor(mul(hi, d_half, half), lo))
end

local table16 = {}
for a = 0, 15 do
  table16[a] = {}
  for b = 0, 15 do table16[a][b] = mul(a, b, 4) end
end

function M.mul(a, b)
  assert(a >= 0 and a < 16 and b >= 0 and b < 16, "nim.mul works on ranks 0–15")
  return table16[a][b]
end

function M.pow(a, n)
  local r = 1
  for _ = 1, n do r = M.mul(r, a) end
  return r
end

function M.square(a) return M.mul(a, a) end

-- Powers of 15: log15[15^i] = i for i = 1..15 (15^15 = 1).
local log15 = {}
do
  local x = 1
  for i = 1, 15 do
    x = M.mul(x, 15)
    log15[x] = i
  end
end

--- The discrete log of a nonzero rank to base 15 (the Ace), in 1..15 (Ace → 1, 1 → 15).
function M.log15(a)
  return assert(log15[a], "no discrete log for 0")
end

--- One step along 15's cycle: a ⊗ 15 (0 stays 0).
function M.step(a) return M.mul(a, 15) end

--- The smallest non-negative integer missing from a list.
function M.mex(list)
  local seen = {}
  for _, v in ipairs(list) do seen[v] = true end
  local m = 0
  while seen[m] do m = m + 1 end
  return m
end

return M
