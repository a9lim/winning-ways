# Changelog

## 1.2.0 (2026-11-23)

- **The row adds up.** The played row is read as one ordinal sum, and infinities now eat each other: a card below a
  power of ω vanishes into it (ω + ω² = ω²), and two of one degree merge (ω + ω = 2ω, and (ω + 3) + (ω + 5) = 2ω + 5).
  The merged card keeps the sum and takes twice the eaten one's chips. Two ωs no longer pair by galaxy.
- **Eaten cards feed what they would score alone:** a 3½ feeds 3.5 (doubled, 7), ω + 14 a King's 10. They fed their
  rank's chips before.
- **ω scores in the higher tiers.** A card ending on a·ω² + k·ω + x scores x in chips, +k Mult and ×(1 + a) Mult: an ω
  gives +1 Mult, 2ω + 5 gives 5 chips and +2 Mult, ω² gives ×2.
- **ω².** Omega on an ω-card makes ω² (the next power of ω swallows the card); it can't go further. The corner reads
  ω², and the engine's numbers now run to a·ω² + k·ω + x.
- **ω in nim-sums.** An ω-card worth an ordinal is the heap of its own value. Two of one degree merge before they
  can cancel, so a hand with one gets past The Heap and never makes Bouton (unless a wild keeps two ωs apart).
- **Values in the wild.** A card a Standard Pack deals, or one the shop sells under Illusion, has a 1 in 5 chance of
  a modifier: +½, * or ±1.
- **Two vouchers,** Lessons in Play and On Numbers and Games: Moves appear 2X, then 4X, as often in the shop.
- **The Game Tag:** a free Mega Game Pack.
- An ω card's tooltip says what it's worth and what it pays; Fable's symbol font has a ².

## 1.1.0 (2026-11-22)

- **Cards draw their values.** A card with a modifier has its own front. The corner reads as the value in the rank's
  own letterforms and ink (3½, 7±2, ω+14), with fractions stacked, and the pips show its stops: the Right stop's
  worth solid, on up to the Left stop in outline, a fraction cutting the last pip. A 0 is an empty field. Courts and
  the Ace keep their art under the new corner. Editions, debuffs and Negative now cover the whole face.
- **Cards of 12 to 17 pips** are laid out as vanilla's are: two columns of six, with the middle column filling in.
- **A \* goes before the rank** (\*5) and turns the pips to a checkerboard. The halo is gone.
- **ω is a rank**, past the Ace, drawn as an Ace inside out: the body in the suit's ink to its edges, so an
  enhancement still shows through, and the large pip in white. Omega turns a card into an ω (n + ω = ω) instead of
  adding ω to it; ω + 14 comes from Sum. The Ordinal Deck starts with an ω of Spades. A card given +ω in 1.0 keeps
  its value and is drawn as an ω.
- **{ω | x} is split along the diagonal**, the ω card above and the x card below. {ω | 0} plays as every rank.
- **A made value sits on its mean, rounded down**, so a fraction counts up from the rank below: 3¾ is a 3 with +¾,
  where it was a 4 with −¼.
- Vanilla's Fibonacci and Hack count a 0 and a 1.
- Cards with no rank sort by the rank they sit on (a 3½ among the 3s, an ω past the Ace) instead of last.
- A * no longer stops two rankless values pairing: 3½* pairs with 3½, and ω* with ω.
- A mod icon: { ▪ | ▪ } on the Moves' slate.
- Fixed: a Wild card whose * had been cancelled still counted as having a modifier (of 0).
- `scripts/sheet` draws a sheet of fronts without the game, and `WINNINGWAYS_SHOWCASE_SET=omega` shows ω cards on
  every enhancement and edition.

## 1.0.2 (2026-11-15)

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
