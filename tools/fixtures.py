#!/usr/bin/env python3
"""Generate the engine's test fixtures from ogdoad.

The Lua engine (src/engine/) must agree with ogdoad on every case written here: random short games with their
canonical forms, stops, temperatures, means, birthdays, heating, cooling and the ranks they can act as; sums
and comparisons of pairs; Left stops of whole hands; the F16 nim-multiplication table; finite simplest
numbers; and the order of transfinite numbers k·ω + x.

ogdoad is a development tool only (it is AGPL; nothing from it ships). Run from the repo root:

    python3 tools/fixtures.py            # writes tests/fixtures/ogdoad.lua

It needs ogdoad's Python bindings (`pip install ogdoad`, or a9's ~/.venv). The output is deterministic.
"""

import random
import sys
from pathlib import Path

import ogdoad as og

G = og.Game
S = og.Surreal
RNG = random.Random(20261114)


def num(p, q=1):
    return G.from_surreal(S.from_rational(p, q))


def rat(s):
    return str(s.as_rational())


def enc(g):
    """The engine's notation: numbers as p or p/q, games as {a,b|c} with options sorted as strings."""
    if g.is_number():
        return rat(g.number_value())
    left = sorted(enc(o) for o in g.left())
    right = sorted(enc(o) for o in g.right())
    return "{" + ",".join(left) + "|" + ",".join(right) + "}"


def lua(v):
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, (int, float)):
        return repr(v)
    if isinstance(v, str):
        return '"' + v.replace("\\", "\\\\").replace('"', '\\"') + '"'
    if isinstance(v, (list, tuple)):
        return "{" + ", ".join(lua(x) for x in v) + "}"
    if isinstance(v, dict):
        return "{" + ", ".join(f"{k} = {lua(x)}" for k, x in v.items()) + "}"
    raise TypeError(type(v))


def random_games(count):
    pool = [num(n) for n in range(-2, 7)]
    pool += [num(1, 2), num(3, 2), num(-1, 2), num(5, 4), num(7, 2), num(9, 4)]
    pool += [G.star(), G.up(), G.star_n(2)]
    games = []
    while len(games) < count:
        nl, nr = RNG.choice([(1, 1), (1, 1), (2, 1), (1, 2), (2, 2), (0, 1), (1, 0), (2, 0)])
        left = [RNG.choice(pool) for _ in range(nl)]
        right = [RNG.choice(pool) for _ in range(nr)]
        raw = "{" + ",".join(enc(o) for o in left) + "|" + ",".join(enc(o) for o in right) + "}"
        g = G.of(left, right).canonical()
        e = enc(g)
        if len(e) > 160 or g.birthday() > 7:
            continue
        games.append((raw, g))
        if not g.is_number():
            pool.append(g)
    return games


def game_record(raw, g):
    ls1, rs1 = g.cooled_stops(1, 1)
    lsh, rsh = g.cooled_stops(1, 2)
    acts = [r for r in range(16) if g.le(num(r)) == num(r).le(g)]
    return {
        "raw": raw,
        "canon": enc(g),
        "ls": rat(g.left_stop()),
        "rs": rat(g.right_stop()),
        "temp": rat(g.temperature()),
        "mean": rat(g.mean_value()),
        "bday": g.birthday(),
        "heat": enc(g.heat(1, 1).canonical()),
        "cool1": [rat(ls1), rat(rs1)],
        "coolh": [rat(lsh), rat(rsh)],
        "acts": acts,
    }


def main():
    games = random_games(240)
    records = [game_record(raw, g) for raw, g in games]
    hot = [(raw, g) for raw, g in games if not g.is_number()]

    pairs = []
    for _ in range(240):
        (ra, a), (rb, b) = RNG.choice(games), RNG.choice(games)
        pairs.append({"a": enc(a), "b": enc(b), "sum": enc((a + b).canonical()), "le": a.le(b), "ge": b.le(a)})

    hands = []
    for _ in range(120):
        picks = [RNG.choice(hot)[1] for _ in range(RNG.randint(2, 4))]
        if RNG.random() < 0.5:
            picks.append(num(RNG.randint(0, 6)))
        total = num(0)
        for p in picks:
            total = (total + p).canonical()
        hands.append({"cards": [enc(p) for p in picks], "ls": rat(total.left_stop()), "rs": rat(total.right_stop())})
    # Hands of switches with card-sized values, the common case in play.
    for _ in range(60):
        picks = []
        for _ in range(RNG.randint(1, 4)):
            b = RNG.randint(0, 14)
            a = RNG.randint(b, 15)
            picks.append(G.of([num(a)], [num(b)]).canonical())
        picks.append(num(RNG.randint(0, 14)))
        total = num(0)
        for p in picks:
            total = (total + p).canonical()
        hands.append({"cards": [enc(p) for p in picks], "ls": rat(total.left_stop()), "rs": rat(total.right_stop())})

    nim = [[og.nim_mul(a, b) for b in range(16)] for a in range(16)]

    dyadics = [(p, q) for q in (1, 2, 4, 8) for p in range(-12 * q, 12 * q + 1, max(1, q // 2))]
    simplest = []
    for _ in range(200):
        a, b = sorted(RNG.sample(dyadics, 2), key=lambda pq: pq[0] / pq[1])
        sa, sb = S.from_rational(*a), S.from_rational(*b)
        if not sa < sb:
            continue
        simplest.append({"a": rat(sa), "b": rat(sb), "s": rat(S.simplest_between(sa, sb))})

    omega = S.from_ordinal(og.Ordinal.omega())

    def tnum():
        k = RNG.choice([(0, 1), (1, 1), (-1, 1), (2, 1), (1, 2), (3, 4), (-1, 2), (3, 2)])
        x = RNG.choice(dyadics)
        return k, x

    def tenc(k, x):
        kp, kq = k
        xs = rat(S.from_rational(*x))
        if kp == 0:
            return xs
        coef = {1: "", -1: "-"}.get(kp, str(kp))
        s = coef + "w" + (f"/{kq}" if kq > 1 else "")
        if x[0] > 0:
            s += "+" + xs
        elif x[0] < 0:
            s += xs
        return s

    order = []
    for _ in range(200):
        (ka, xa), (kb, xb) = tnum(), tnum()
        va = omega * S.from_rational(*ka) + S.from_rational(*xa)
        vb = omega * S.from_rational(*kb) + S.from_rational(*xb)
        order.append({"a": tenc(ka, xa), "b": tenc(kb, xb), "lt": va < vb, "eq": va == vb})

    out = Path(__file__).resolve().parent.parent / "tests" / "fixtures" / "ogdoad.lua"
    out.parent.mkdir(parents=True, exist_ok=True)
    with out.open("w") as f:
        f.write("-- Generated by tools/fixtures.py from ogdoad. Do not edit.\n")
        f.write("return {\n")
        for name, value in [("games", records), ("pairs", pairs), ("hands", hands), ("nim", nim),
                            ("simplest", simplest), ("order", order)]:
            f.write(f"  {name} = {{\n")
            for item in value:
                f.write("    " + lua(item) + ",\n")
            f.write("  },\n")
        f.write("}\n")
    print(f"wrote {out} ({len(records)} games, {len(pairs)} pairs, {len(hands)} hands)", file=sys.stderr)


if __name__ == "__main__":
    main()
