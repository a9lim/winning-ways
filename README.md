# Winning Ways

[![CI](https://github.com/a9lim/winning-ways/actions/workflows/ci.yml/badge.svg)](https://github.com/a9lim/winning-ways/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

A Balatro mod about Conway's numbers and games, named for Berlekamp, Conway and Guy's *Winning Ways for your
Mathematical Plays*. Cards become surreal numbers, hot games, nimbers and ω: Cut two cards into {L | R}, Sum them,
heat and cool them, and let the Blind take its share of the hot ones. The maths is exact: every value a card can hold
is a real surreal number or combinatorial game, and every rule is a theorem or a definition from the literature.

[DESIGN.md](DESIGN.md) has every rule in full, with the facts each one rests on.

## Install

With [balala](https://github.com/a9lim/balala):

```sh
balala install a9lim/winning-ways
```

Or by hand: install [Steamodded](https://github.com/Steamodded/smods), then put this repo in your `Mods` folder.

## Values

- **Every card has a value:** its rank plus a modifier. The ranks run 2–10, J = 11, Q = 13, K = 14, A = 15, plus three
  born ranks that no starting deck holds (except the Field Deck): **0**, **1**, and the **Cavalier** (C = 12, tarot's
  fourth court card, between the Jack and the Queen, and optional in straights). Past the Ace there is one more,
  **ω**.
- **Modifiers** live in their own slot, so a card can be Glass and +½, and rank changes keep them.
- **A card with a modifier draws its own front.** The corner reads as the value (3½, 7±2, \*5, ω+14) and the pips
  show it: a 3½ has three pips and half a pip, and 7±2 = {9 | 5} is a 9 with five pips solid and four outlined, so
  you can count the ranks it plays as. A * turns the pips to a checkerboard, an ω is an Ace inside out, and the wild
  {ω | 0} is half ω and half 0.
- **A card plays as any rank its value equals or is confused with**, and you choose: 7±2 plays as 5 to 9, and the
  wild {ω | 0} plays as every rank. Equal values pair even without a rank: two 3½s are a Pair.
- **The hand is a game.** You move first, the Blind replies, and each card scores the number it ends on. A hand of
  plain numbers scores exactly as in vanilla.
- **ω eats, and the row adds up.** Played cards are read left to right as one ordinal sum: a card below a power of
  ω vanishes into it (n + ω = ω, ω + ω² = ω²), and two of one degree merge (ω + ω = 2ω). The eater gains twice the
  eaten cards' chips for good, and always scores.
- **Infinity scores in the higher tiers:** a card worth a·ω² + k·ω + x scores x chips, +k Mult and ×(1 + a) Mult.
  An ω gives +1 Mult, and ω² ×2.

## Moves

A new kind of consumable, sold in Game Packs and in the shop:

| Move | does |
| --- | --- |
| Cut | fuses two cards into {left \| right}: 3 and 7 make a 4, 3 and 4 make 3½, 9 and 5 make 7±2; one card rounds up; none makes a 0 |
| Sum | adds two cards |
| Heat, Cool | widen or narrow a hot card |
| Frobenius | squares ranks in nim arithmetic |
| Tweedledum | copies the last Move used |
| Repaint | swaps ♠ with ♥ and ♣ with ♦ |
| Nimbus | adds a *: 5* plays as a 5 but nim-sums as a 4 |
| Mex | turns a card into the smallest rank the others miss |
| Omega (Spectral) | turns a card into an ω, or an ω into ω² |

## Jokers

| Joker | rarity | effect |
| --- | --- | --- |
| Hotstrat | common | retrigger every played hot card |
| Generator | uncommon | scored cards pay chips for their place on the Ace's cycle, then step along it |
| Grundy | uncommon | gains Mult equal to each hand's mex |
| Cantor | uncommon | adds a card whose rank and suit your deck lacks |
| Cantor's Paradise | uncommon | gains ×0.1 Mult for each card ω eats |
| Birthday | uncommon | +3 Mult per day a card's value was born after its whole number |
| Bouton | rare | ×3 Mult when the played cards nim-sum to 0 |
| Thermograph | rare | hot cards score their mean and +3 Mult per degree |
| Sprouts | rare | a two-card first hand adds their Cut to the deck |
| Hilbert's Hotel | rare | takes no Joker slot and gives one more; −1 hand size |
| Conway | legendary | each played card can also play as the Cut of its neighbours |
| Berlekamp | legendary | ×1.5 Mult per scored hot card |
| Guy | legendary | ×1.5 Mult per scored card of rank 5 or lower |

## Blinds and decks

- **The Heap:** a hand whose scoring cards nim-sum to 0 scores nothing, so Pairs never do.
- **The Misère:** the last mover loses, so your final hand of the round scores nothing.
- **Vanilla's Fibonacci and Hack** count the 0 and the 1 as well.
- **Field Deck:** 64 cards, every rank from 0 to Ace with the Cavalier, in all four suits: the field F₁₆.
- **Ordinal Deck:** starts with an ω of Spades, and a Cut.

## In the shop

- **Standard Packs** sometimes deal cards with a modifier (+½, * or ±1), and so does the shop under Illusion.
- **Lessons in Play** and **On Numbers and Games** (vouchers): Moves appear 2X, then 4X, as often.
- **Game Tag:** a free Mega Game Pack.

## Other mods

With [Quintessence](https://github.com/a9lim/quintessence), a Wild card is a green Hackenbush edge, which is worth *:
a Wild 5 is 5*, and Nimbus turns it back into a plain 5. The born ranks have Wild-suit fronts, values play in its
Spectrum hands, and Repaint leaves Wild cards alone (a green edge is its own negative).

## Credits

Made by a9lim and Claude, code and art.

- **Mathematics:** Elwyn Berlekamp, John Horton Conway and Richard Guy (*Winning Ways*, *On Numbers and Games*).
  Further ideas come from Charles Bouton (Nim), Patrick Grundy, Georg Cantor and David Hilbert. The vouchers are
  named for *Lessons in Play* (Michael Albert, Richard Nowakowski and David Wolfe) and Conway's *On Numbers and
  Games*.
- **Real-valued ranks:** [UnStable](https://github.com/kirbio/UnStable) by
  kirbio first did these in Balatro, fractions drawn as part of a pip included. Winning Ways reimplements the idea;
  it uses none of UnStable's code or art.
- **Checking:** [ogdoad](https://github.com/a9lim/ogdoad) is the test oracle. It is a development tool only, and none
  of its code ships.

## License

The code and the original art are [MIT](LICENSE).

Some sprites in `assets/` are built from Balatro's own art, © LocalThunk, so that they match the game.
[assets/NOTICE.md](assets/NOTICE.md) lists which, `assets/parts.lua` among them (pip and glyph shapes, as data). Those
pixels aren't ours to license: they're included only for use with Balatro and aren't covered by the MIT license. The programs in `art/` contain no Balatro pixels; they read the
textures from your own copy of the game.

## Development

See [AGENTS.md](AGENTS.md). In short: `scripts/test` runs the unit tests on LuaJIT, `scripts/sheet` draws a sheet of card
fronts without the game, `scripts/selftest` checks the mod inside the game at the main menu, and `scripts/runtest`
plays a real run and checks every score to the chip. Launch
with `WINNINGWAYS_LAB=1` for the Laboratory Deck, a development deck with a sample of every kind of modifier.
