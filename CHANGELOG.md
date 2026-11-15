# Changelog

## Unreleased

- A halo adds 1 in nim-sums: 5* plays as a 5 but counts as a 4 for Bouton and The Heap, so Nimbus is Bouton's
  tuning knob and a way past The Heap.
- With Quintessence, a Wild card is a green Hackenbush edge, worth *: a Wild 5 is 5*, wears the halo, and Nimbus turns
  it into a plain 5.
- A hot card with a * draws its ± under the halo, and a bare * reads "*" in tooltips, not "+0*".

## 1.0.1 (2026-11-15)

- Every tooltip rewritten in vanilla's voice: shorter lines, vanilla's own phrasings ("Played cards give … when
  scored", "Start run with …", "(Drag to rearrange)"), and The Fool's box on Tweedledum for the last Move used.
- The terms of art get their own info boxes, as vanilla's enhancements do: hot, mex, nim-sum, ω and the Ace's cycle.
- Move names in text are the Moves' bright green, readable on a tooltip.
- The self-test renders every tooltip, and `WINNINGWAYS_SHOWCASE_SET=tooltips` screenshots each one.

## 1.0.0 (2026-11-14)

First release.

- Card values are rank plus modifier: surreal numbers (3½), hot games (7±2), nimbers (5*) and transfinites (ω + 14),
  with an exact engine checked against ogdoad. A card plays as any rank its value is confused with, equal values
  pair, and a hand scores as a game the Blind plays against you.
- Three born ranks: 0, 1 and the Cavalier, with fronts in every suit (and Quintessence's Wild).
- Nine Moves (Cut, Sum, Heat, Cool, Frobenius, Tweedledum, Repaint, Nimbus, Mex), Game Packs, and the Omega Spectral.
- ω cards eat the finite cards played to their left, gain twice their chips for good, and always score.
- Thirteen jokers: Bouton, Generator, Grundy, Hotstrat, Thermograph, Sprouts, Cantor, Cantor's Paradise, Birthday,
  Hilbert's Hotel, and the three authors, Conway, Berlekamp and Guy.
- The Heap and The Misère; the Field Deck and the Ordinal Deck.
- Works with Quintessence: Wild-suit fronts for the born ranks, values in Spectrum hands.
