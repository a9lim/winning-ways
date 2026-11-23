# Winning Ways — design sketch

*Status: everything in the Decided sections is built (§ 11).
**Decided** sections record what a9 and Claude have agreed. **Candidates** are proposals still waiting on a9's call. § 10 lists the facts the design
rests on, each one checked with ogdoad or marked standard.*

Winning Ways is a Balatro mod about Conway's numbers and games. It's named for Berlekamp, Conway and Guy's book, and it
makes one promise: the maths is exact. Every value a card can hold is a real surreal number or combinatorial game,
every rule is a theorem or a definition from the literature, and ogdoad (a9's library) checks the engine.

## 1. The idea

Conway built every number and every game from one definition: a position {L | R}, given by the options Left and Right
can move to. Balatro's ranks are already numbers (2–10, J = 11, Q = 13, K = 14, A = 15), so every card is already a
game. The mod adds ways to build new values out of old cards, plus a scoring rule that behaves exactly like vanilla
until a non-number shows up.

Each family breaks one assumption the deck makes about ranks:

- **Surreal numbers** break "every rank has a next one": 3½ has no successor.
- **Hot games** break "a card has one rank": 5±1 plays as 4, 5 or 6.
- **Transfinite numbers** break "ranks are finite": ω sits above every rank.
- **Nimbers** break ordinary arithmetic on ranks: x ⊕ x = 0.

## 2. Values and ranks — Decided

### 2.1 What a card is worth

- Every card has a **value**: a short game whose leaves are numbers. A number is either a finite dyadic or a
  transfinite ω·k + x.
- **Ranks are integers:** 2–10, J = 11, C = 12, Q = 13, K = 14, A = 15. The Ace is 1111 in binary, the top of F₁₆.
- **Born ranks** are not in the starting deck; only Moves (and Generator) make them:
  - **0** = {|}, the game with no moves.
  - **1** = {0|}.
  - **C, the Cavalier** = {J|Q} = 12, tarot's fourth court card, which the French deck dropped. It is a face card and
    scores 10, like the other court cards.
  - **ω**, the first infinite number, is a rank too: the seventeenth, past the Ace. Only the Omega Spectral makes
    one (§ 2.4). It is worth ω, not 16, which is an Ace with +1. Every infinite value a card holds sits on it: 2ω + 5
    and ω² are ω-cards.
- With the born ranks, the deck's ranks 0–15 form the field F₁₆ under nim arithmetic. ω is outside it: it plays as no
  rank. In nim-sums an ω-card is the heap of its own value (§ 2.4).
- **Straights:** the Cavalier is optional. 10-J-Q-K-A and 10-J-C-Q-K are both straights, so no deck changes and
  vanilla's straights are untouched. The born ranks extend straights downward (0-1-2-3-4). The Ace still tops a
  straight or plays low at its start (A-2-3-4-5), and still can't wrap (K-A-2 isn't a straight). These are ordinary
  next lists: the Jack is followed by the Queen or the Cavalier, so Steamodded's own straight finder handles them.

### 2.2 Loose confusion

A card **acts as any rank its value equals or is confused with**. For example:

| value | acts as |
| --- | --- |
| 7 | 7 |
| 3½ | no rank (scores 3.5 chips) |
| 5* | 5 |
| 5±1 = {6 \| 4} | 4, 5 or 6 |
| 8±6 = {K \| 2} | every rank from 2 to K |
| {ω \| 2} | every rank from 2 up: the **wild rank** |
| ω | no rank |

- **Hand type:** you choose the ranks. You are the first player in a confused position, and the first player wins
  those. Assigning ranks is a matching problem like Quintessence's suit matching, and easier, because each card's
  options form one range of ranks.
- **Equal values pair**, even when they have no rank: two 3½s are a Pair. A * changes nothing here: 3½* pairs with
  3½, as n* plays as n.
- **Two infinities of one degree never meet in a hand:** the played row merges them (§ 2.4). Until 1.2 they paired
  by galaxy (values a finite distance apart, so ω + 13 with ω + 2); merging made that rule unreachable, and it went.
- **Rank-specific jokers** see the rank a card played as. Wee sees a 2 in a Five of a Kind of 2s.

### 2.3 Scoring: the hand is a game

- The scoring cards' values add up to one game. You move first, the Blind replies, and chips come from the Left
  stop of the sum.
- **Per card**, chips follow the hotstrat. The hottest scoring card pays you its top value, the Blind takes the bottom
  value of the next-hottest, and so on, alternating. This is exact for sums of switches. For general games the
  engine searches the (small) sum exactly.
- A hand of plain numbers scores exactly as in vanilla.
- **Chips for the number a card ends on:**
  - **A finite part from 0 to 15** scores that rank's own chips. J, C, Q and K still score 10 and the Ace 11, so
    taking 15 from a wild scores an Ace's 11.
  - **Any other finite part** scores itself: 3½ scores 3.5.
  - **Infinite parts score in the next tiers up.** A card that ends on a·ω² + k·ω + x scores x in chips, +k Mult, and
    ×(1 + a) Mult. Balatro has three tiers, chips, +Mult and ×Mult, each outweighing the one below, as each power of
    ω outweighs the one below it. So ω scores no chips and +1 Mult, ω + 14 a King's 10 and +1 Mult, 2ω + 5 five
    chips and +2 Mult, and ω² ×2 Mult. The mapping is Balatro-layer, not maths (§ 5½).

### 2.3½ Values on cards: rank + modifier

- **A card's value is its rank plus a modifier.** The modifier is any game, and it is stored as canonical notation
  in `card.ability.ww_mod`:
  - 3½ is a 3 with +½;
  - 5* is a 5 with *;
  - 7±2 is a 7 with ±2.

  Cards without a modifier are worth their rank.
- **Its own slot.** The modifier sits beside enhancement, edition and seal, so a card can be Glass *and* +½. A card
  with one draws its own front (§ 2.5).
- **Rank changes keep it.** Strength, Ouija and Generator change the rank, the modifier stays, and the value shifts
  with the rank: 7±2 on an 8 is 8±2. This is coherent because heating and cooling commute with adding a number:
  ∫^t(G + x) = ∫^t G + x and (G + x)_t = G_t + x. Copies (Death, Cryptid) keep the modifier.
- **Which rank a made value sits on.** When a Move makes a value V, the card sits on V's mean, rounded down, and its
  modifier is V minus that rank. So 3½ sits on the 3 with +½, 3¾ on the 3 with +¾, 7±2 on the 7 with ±2, and 13¼±4
  on the Queen: a fraction always counts up from the rank below. Three cases need more:
  - When V plays as some ranks but not that one, it sits on the nearest rank it does play as (the lower on a tie).
    {7±2|3} has mean 5, plays as a 3 or a 4, and sits on the 4.
  - Past the ends it sits on the end: 28 is an Ace with +13, and −1½ a 0 with −1½.
  - A value that is infinite however it's played (its Right stop is infinite) sits on ω: ω + 14 is an ω with +14.
    Any other value with an infinite mean sits at that end of the ranks it plays as: the wild {ω|2} sits on the
    Ace, with the modifier {ω−15 | −13}, and so does {ω|16}, which plays as none.

  a9 decided this on 2026-11-22. Before, a card sat on the rank nearest its mean among those it played as, so 3¾ was
  a 4 with −¼.
- **Equal values play alike.** A 3 with +½ and a 4 with −½ are both 3½, so they pair.
- **No rank.** A value that plays as no rank (3½, ω) counts as having no rank, like a Stone card, except that equal
  values still pair.
- **A dormant modifier.** On a card with no rank of its own (Stone) or another mod's rank, the modifier lies dormant
  until the card has one of ours again.

### 2.4 Transfinites

- **ω is a rank**, the seventeenth, past the Ace (§ 2.1). a9 decided that on 2026-11-22; before, ω was a modifier,
  and the card under it kept its rank.
- **ω only enters from outside**, through the Omega Spectral, which turns a card into an ω. No chain of Moves on
  finite cards can reach it, because every value they build is born on a finite day. ω² enters the same way, from
  Omega on an ω-card: no finite sum of ω's reaches it.
- **Three degrees.** Values go up to a·ω² + k·ω + x, and stop there: Balatro scores in three tiers (§ 2.3), so the
  mod has three degrees. Omega can't lift a card past ω².
- **An ω-card** (any positive infinite number: ω, ω + 14, 2ω, ω², ω/2):
  - is above every rank, plays as none, and pairs only with an equal value. In a sorted hand it stands past the Ace,
    but it is never the High Card;
  - always scores, like a Stone card;
  - **eats**: the played row adds up (below), and the cards it swallows are destroyed;
  - **grows like Ceremonial Dagger**: twice the chips each eaten card would score alone become its permanent bonus
    chips (Dagger takes double too; `WW.EAT`, a balance number, § 5½). A 3½ feeds 3.5, ω + 3 feeds 3 and 7±2 its 9.
    The bonus is stored the way Hiker's is;
  - scores in the tiers: its finite part in chips, its ω's as +Mult, its ω²'s as ×Mult (§ 2.3).
- **The played row adds up**, read left to right as ordinal addition (a9, 2026-11-23). Two rules, both theorems
  about ordinals:
  - **Absorption.** A card below a power of ω vanishes into it from the left: α + ω^β = ω^β whenever α < ω^β. So
    n + ω = ω, and ω + ω² = ω² too.
  - **Like terms.** A card of the same degree adds its leading term to the one on its right: ω + ω = ω·2, and
    (ω + 3) + (ω + 5) = ω·2 + 5, the left card's 3 swallowed by the right card's ω.

  So each eater takes in the cards to its left back to the nearest card of a higher degree: the finite ones and
  the lower degrees vanish, and those of its own degree merge into it. Its value becomes their sum. The row's sum
  never changes, only how many cards carry it. Order matters, as it does for ordinals: [ω, ω²] leaves ω², but
  [ω², ω] keeps both. [ω², ω, ω²] comes to 2ω²: the ω vanishes, and then the two ω² are side by side.

  Ordinal addition is defined only for ordinals. For every other number the mod reads the row by degree in the same
  way, as it always has for 3½ + ω = ω: a lower degree vanishes, and the same degree adds its leading term. So
  ω − 1 merges into ω as a term of degree 1, and the pair comes to 2ω.
- **Merging is a trade.** Two ωs give +1 Mult each, and 2ω gives +2, so Mult is unchanged; the merged card takes
  twice the eaten one's chips, and the deck is a card thinner. Two ω² give ×2 · ×2 = ×4 apart and ×3 merged, so
  merging those costs Mult.
- **In nim-sums** an ω-card worth an ordinal (ω + 14, 2ω²) is the heap of its own value. Conway's nim-addition of
  ordinals works digit by digit: (ω + 3) ⊕ (ω + 5) = 6. After the row adds up, the infinite cards left in a hand
  have strictly falling degrees, so their infinite digits never cancel: a hand with one doesn't nim-sum to 0, so it
  gets past The Heap and never makes Bouton. Two exceptions: a wall (below) can keep two of one degree apart, as in
  ω {ω|2} ω, where the two ωs cancel; and an ω-card worth a number that isn't an ordinal (ω + ½, which Cut(ω, ω + 1)
  makes) has no heap at all, like 3½.
- **Two additions.** The played row uses ordinal addition, which depends on order. Sum uses Conway's sum, which
  commutes, so Sum(K, ω) = ω + 14 and Sum(ω, K) = ω + 14 too.
- **As built** (`src/omega.lua`):
  - **Who eats:** a card worth a positive infinite number, its * aside, that isn't debuffed. A debuffed one can
    still be eaten.
  - **Walls:** any other infinite value (the wild {ω|2}, a negative infinity) stops the row: nothing to its left is
    eaten past it, and it is never eaten.
  - **When:** the eater grows as the hand is played, so it scores its new chips and its new value that same hand.
    The eaten cards are left out of the hand being read, so a preview already shows the hand without them; Splash
    can't make them score; and they're destroyed once the hand has scored. An eaten eater's growth comes along,
    doubled again.
  - **Reading, then growing:** the hand is read, and the Blind judges it, with the eaters at their old values; a
    merged eater takes its new value as the cards start to score. So the preview and the play always agree.
- **The wild rank {ω|2}** (made with Cut) has infinite temperature, so it is always the hottest card in a hand. You
  take ω (no chips, +1 Mult), and the Blind gets first pick of your other hot cards.

### 2.5 Faces: the value, drawn

A plain card keeps its own front. A card with a modifier, and every ω, draws its own. a9 and Claude settled this on
2026-11-22; before it, a modifier was coloured text beside the corner index.

- **The corner reads as the value**, in the rank's own letterforms and ink: 3½, 7±2, ω+14.
  - **A fraction is stacked**, numerator over denominator, in small digits as heavy as the rank's. So 3½ takes
    two glyphs' width, and 8½±6½ fits with room to spare. a9 asked for this on 2026-11-22: written out in a line
    (3+1/2), fractions crowded the corner and long values had to be cut short.
  - After a rank written as a number, a fraction needs no sign: 3½, 10⅜. After a letter it keeps one (Q+½), and so
    does anything else: 6−¼, A+13, 9+1½.
  - A line too long for the card, which now takes a value many Cuts deep, drops numbers off its end and keeps
    their sign.
- **The field shows the value's stops in pips.** The Right stop's worth of pips are solid, and pips on up to the
  Left stop are outlined. A fraction cuts the last pip of each kind.
  - A number has no outlines: 3½ is three pips and half a pip, and 0 is an empty field.
  - 7±2 = {9|5} is a 9 with five pips solid and four outlined. For a switch, the solid count to the whole count is
    exactly the ranks it plays as. It is the scoring too: you take every pip if you move first there, and the Blind
    leaves you the solid ones.
  - Any other game shows its stops the same way. It plays inside that range, but not always at the ends: {7±2|3}
    shows 3 solid and 2 outlined and plays as a 3 or a 4, and 5±1* shows 4 to 6 and plays only as a 5. The tooltip
    says exactly.
  - Up to 11 pips use vanilla's layouts (11 is the 10 with a pip in the middle). From 12 to 17 the card goes on as
    vanilla might have: two columns of six, which is the 12, and the middle column filling in between them, so
    each holds the ones before it. 17 is as many as fit with a clear pixel between them; past that, the rank's
    own pips stay. Many-pip cards laid out like vanilla's are UnStable's idea (its 11, 12 and 13); a9 asked for
    them on 2026-11-22 in place of small pips in a block.
  - Pips never go below zero: 1±2 = {3|−1} shows three outlined pips, which are the ranks it plays as, 0 to 3.
  - This is a picture, not a rule. Nothing in the game reads it.
- **A \* goes before the rank** (\*5) and turns the pips to a checkerboard; outlined pips are dashed, since a
  one-pixel diagonal lies wholly on one colour of the board. Turning the pips instead, a9's first idea, can't work:
  vanilla's diamond is unchanged by any quarter turn.
- **Courts and the Ace keep their own art** under the new corner: Q±1 still looks like a Queen. So their fields
  don't show their values, a limit a9 accepted. A card of a suit we have no pips for (another mod's) does the same.
- **ω is the card inside out.** The body takes the suit's ink to its edges, multiplied, so an enhancement still
  shows through; the index, the corner pip and the Ace's large pip are white. It is an Ace inside out, with ω for
  its index.
- **A power is raised:** ω² reads ω with a small 2 at its shoulder, in the fractions' small digits, and is
  otherwise an ω card: 2ω², ω² + ω + 14.
- **{ω|x} is split along the diagonal** from bottom left to top right: the ω card above, with its corner, and the x
  card below, with its own. {ω|0} is half ω and half 0, and plays as every rank. The tooltip calls {ω|x} the wild
  rank when x is 2 or less, since those play as every rank a standard deck has.
- **As built:** `src/fronts.lua` decides the look and composes it as a 71×95 grid from Fable's parts
  (`assets/parts.lua`: the index alphabet, each suit's pips, vanilla's layouts in fill order, the inks).
  `src/faces.lua` draws each distinct look once onto a canvas and puts it in place of the card's front sprite, so
  editions, debuffs and Negative treat it like any front. A composed number card with no modifier is vanilla's own
  card, pixel for pixel; the self-test checks 2 to 10 in every suit.

## 3. Moves — Decided

Moves are a new consumable type, sold in Game Packs and, at half the Tarots' rate, in the shop. They're built
(`src/moves.lua`): each effect is a plain function of the selected cards, left to right, so the self-test runs
them directly. Tweedledum remembers the last Move used, as The Fool does. A Cut on no cards adds a 0 of a random
suit to the hand.

### Cut

- Select 0, 1 or 2 cards. With two, the card further left in hand is L.
- Both parents are used up and a new card is born: the old positions become the new card's options.
  - The new card takes both parents' enhancement, edition and seal.
  - When both parents have one of a kind, the left parent's wins, and so does its suit.
- With no cards selected, Cut makes a new 0. With one card it makes {A|}, which rounds up: 7 → 8, 3½ → 4, K → A,
  and A → 16, an Ace with +1, which plays as no rank.
- Cut(J, Q) = {11|13} = 12 makes a Cavalier: it's the simplest number between the Jack and the Queen.

| Cut on | value | plays as |
| --- | --- | --- |
| (nothing) | 0 | 0 |
| 3, 7 | 4 | 4 |
| 3, 4 | 3½ | no rank |
| 5, 5 | 5* | 5 |
| 9, 5 | 7±2 | 5–9 |
| J, Q | 12 | C |
| A, 2 | 8½±6½ | 2–A |
| ω, 2 | {ω \| 2} | every rank |

### Sum

A + B under Conway's sum, with the same inheritance as Cut:

- 3 + 4 = 7.
- 5±1 + 5±1 = 10, because ±1 is its own negative.
- K + ω = ω + 14.

### Heat and Cool

- **Heat** raises a game's temperature by 1 ({6|4} → {7|3}), giving a wider range and a bigger bite. Numbers don't
  heat.
- **Cool** lowers it by 1. Cooling 5±1 gives 5*, which plays as 5.

### Frobenius

Nim-squares a card's rank, keeping its modifier. The cycles are 2↔3, 4→6→5→7→4, 8→Q→10→K→8 and the court cycle
9→C→J→A→9; 0 and 1 stay where they are.

### Tweedledum

The set's Fool: it copies the last Move used. The Tweedledum-and-Tweedledee strategy is copying your opponent's move.

### Repaint

Hackenbush's negation paints every blue edge red. Up to three cards swap colour (♠↔♥, ♣↔♦): a flush fixer with a
game-theory reason.

### Nimbus

Adds * to the modifiers of up to two cards. The card shows it as a * before its rank and checkered pips (§ 2.5).
The Move is named for a halo because the vanilla Tarot already has the name "Star".
- For hands nothing changes: n* plays as n.
- **In nim-sums a \* adds 1:** n* is the heap n ⊕ 1, so 5* plays as a 5 but nim-sums as a 4. That makes Nimbus
  Bouton's tuning knob and a way past The Heap (a 5 and a 5* nim-sum to 1). Distinct ranks still count by the rank a
  card plays as, and Grundy's mex reads ranks. a9 decided this on 2026-11-15.
- **Which cards carry a \*:** exactly those whose modifier is x + * for x a number plus nothing, ↑, ↓ or a switch
  (`WW.has_star`), so 5±1* reads \*5±1. Nim-sums read the same test.
- Starred cards cancel in pairs under Sum: 5* + 5* = 10.

### Mex

The leftmost selected card becomes the mex of the other selected cards. On its own, a card becomes a 0; beside a 0 it
becomes a 1; beside a 0 and a 1 it becomes a 2. It's the easy way to make born ranks, and it feeds Grundy.

### Omega (Spectral)

Adds on the right the next power of ω above the selected card, which swallows it: α + ω^(d+1) = ω^(d+1) for any α
below that power (a9, 2026-11-23). It is the rule an ω eats by, one degree up.
- **A finite card becomes ω:** n + ω = ω, so its rank, chips and modifier go, and it starts eating. Any card will do.
  The first version turned a 2 into ω, but a Spectral pack's hand often holds no 2: 8 cards contain one only about
  52% of the time.
- **An ω-card becomes ω²:** (ω·k + x) + ω² = ω², so ω + 14 and 2ω both become ω². A game's degree is its highest
  stop's, so the wild {ω|2} becomes ω² too.
- **Past ω² it can't be used.** Balatro has three tiers (§ 2.3).
- **History.** The second version added ω to the card's modifier and kept its rank, so a King became K + ω = ω + 14.
  a9 replaced that with the ω rank on 2026-11-22, when Omega on an ω gave ω·2. Now ω·2 comes from the row (two ωs
  merging) or from Sum.
- **The ω³ = 2 nod lives here, not on the card** (the pixel font has no ³): ω is the smallest cube root of 2 in nim
  arithmetic, and no finite rank is one (the nim-cubes of 1–15 are only 1, 8, 10, Q and K).

## 4. Jokers — Decided

- **Bouton** (rare): ×3 mult if the played cards nim-sum to 0 and include at least three distinct ranks. Your
  kickers are your Nim move.
  - Of 8-card hands, 99.3% can make some Bouton play, 75.4% can make one that contains a Pair, and 0.60% can make
    one as a flush.
  - No straight ever nim-sums to 0.
  - The 0 card is invisible to nim-sums, so it is a free kicker. That also rescues Two Pair: a, a, b, b, 0 has three
    distinct ranks.
- **Generator** (uncommon): after scoring, each scored card's rank is nim-multiplied by the Ace, 15, which
  generates F₁₆'s multiplicative group. That moves the card one step along the Ace's cycle, and its modifier stays:
  A → 9 → Q → C → 3 → 10 → 7 → J → 8 → 2 → 5 → K → 6 → 4 → 1 → A.
  - **Payout:** each card pays its place on the cycle, its discrete log: the Ace 1, 9 is 2, …, 4 is 14, 1 is 15. A
    card's payout rises by one each time it scores, then wraps.
  - **Effects on the deck:** it keeps pairs, flushes and nim-zero hands (nim-multiplication distributes over
    nim-addition), scrambles straights, mints Cavaliers from Queens, and turns 4s into 1s and 1s into Aces.
  - **The numbers need tuning:** as raw +mult it averages about +8 per card, which is far too much.
- **Grundy** (uncommon): gains +mult equal to each scored hand's mex, the smallest rank counting from 0 that is
  missing from the scoring cards. It does nothing until you've made a 0, and a 0-1-2-3-4 straight adds 5.
- **Hotstrat** (common): retrigger every scored hot card once, the way Hack retriggers 2–5 and Sock and Buskin
  retriggers face cards. It does nothing in a deck with no hot cards.
- **Thermograph** (rare): hot cards score their mean, with no bite, and give +3 mult per degree of temperature
  (raised from +1 in the balance pass, § 5½).
- **Sprouts** (rare): if the first hand of a round is exactly two cards, add their Cut to the deck; the parents stay.
  Conway and Paterson's Sprouts adds a new spot on every line drawn. The shape is like DNA's.
- **Cantor** (uncommon): when a Blind is selected, add a card whose rank and suit pair isn't in your deck (the
  diagonal argument). When every pair is present, it adds a born rank.
- **Cantor's Paradise** (uncommon): gains ×0.1 mult each time an ω card eats a card; Canio for the eating engine. The
  name is from Hilbert: "No one shall expel us from the paradise that Cantor has created."
- **Conway** (legendary): each played card can also act as {its left neighbour | its right neighbour}. This is the
  positional Cut card from the first sketch, applied to every card, and only while it's played: no values change.
  - [4, x, 6] lets x play as 5; [K, x, K] lets it play as K; [A, x, 2] lets it play as any rank.
  - Rising neighbours that are adjacent, like [Q, x, K], give 13½ and no rank. Bigger cards go on the left.
  - It turns three Kings and two junk cards into Five of a Kind ([K, x, K, y, K]), so it's probably the strongest
    card in the mod. That suits a legendary, but it needs watching in play.
- **Birthday** (uncommon): each scored card gives +3 mult per day its value was born after its whole number. In
  Conway's construction 3 is born on day 3, 3½ (sign expansion ++++−, after 4) on day 5 and 3¼ on day 6, so a 3½
  pays 2 days. A game's whole number is its mean's, rounded toward 0, and n is born on day |n|: 5* is 1 day after 5,
  7±2 = {9|5} (day 10) 3 days after 7. Values born on an infinite day (ω + 14, the wild) pay nothing.
- **Hilbert's Hotel** (rare): takes no Joker slot, because there's always room for one more, and gives +1 Joker
  slot, for −1 hand size (Ectoplasm's price). Worth two slots.
- **Berlekamp** (legendary): each scored hot card gives ×1.5 mult. He wrote the book on thermography (and on Dots and
  Boxes).
- **Guy** (legendary): the Strong Law of Small Numbers. Each scored card of rank 5 or lower, 0 and 1 included, gives
  ×1.5 mult: a Triboulet for small numbers.

### 4.1 As built (`src/jokers.lua`)

Claude's calls where the sketch left room, waiting on a9's say-so:

- **"Rank" means the rank a card plays as** in the hand being scored: a wild in a Pair of Kings is a King. Cards with
  no rank (Stone, 3½) are invisible to nim-sums and the mex, as a 0 is; an ω-card is its own heap in nim-sums
  (§ 2.4) and invisible to the mex. Cards infinity ate don't count.
- **Bouton:** a flexible kicker (one that doesn't score) may play as any of its ranks, Conway's included, because
  you choose in a confused position. So a wild kicker completes a Bouton whenever the other cards nim-sum to a rank it can play as
  (K, Q and a wild: K ⊕ Q = 3). Scoring cards keep the rank the hand gave them.
- **Generator** pays **+2 chips per place** on the Ace's cycle (A 2, 9 4, …, 1 30; 16 on average), from the card's own
  rank, then steps that rank. It acts on the rank under any modifier (7±2 becomes J±2), never on Stone cards or an
  ω, and the 0 neither pays nor moves. Blueprint copies the chips but not the step.
- **Grundy** grows before the hand scores, so the mex counts the same hand. Only the scoring cards count, so a High
  Card's kickers don't.
- **Hotstrat** retriggers cards whose value has temperature above 0: 7±2 and the wild, not *, ↑ or ↓.
- **Thermograph** leaves the wild alone: its temperature is infinite (ω/2 − 1), and an infinite +mult has no
  meaning. Every other hot card plays as its mean in the hand's play-out, so nobody moves in it, and gives 3 mult
  per degree (degrees can be fractional). With Hotstrat both happen twice.
- **Sprouts** makes the new card as Cut does: a copy of the left card, worth {left | right}, taking what it lacks
  (enhancement, edition, seal) from the right one. Like DNA, the card goes into the hand.
- **Cantor** picks a missing standard pair at random, then a missing born-rank pair (0, 1, C) once all 52 are there.
  On a full Field Deck there is nothing to add, and it does nothing. A Stone card, or a 3 worth 3½, doesn't hold its
  pair.
- **Cantor's Paradise** hears about eating through a custom context (`context.ww_eaten`, sent by `src/omega.lua`
  before the hand scores), so the new ×mult applies to that same hand.
- **Conway's end cards** have one side empty: {|R} is 0 and {L|} is L rounded up. So [2, 3, 4, 5, x] is a straight
  for any x, as x plays as {5|} = 6. Stone cards get no ranks and act as no neighbour. The extra ranks only widen
  what cards play as, and never take a reading away: two 3½s still pair as equal values, and 3 3½ 3 is Three of a
  Kind (the 3½ is {3|3} = 3*). Every card still scores its own value (K 5 K scores the 5's 5 chips).
- **Birthday** reads the card's value, not the number it ends on, so a hot card pays its full age.
- **Hilbert's Hotel** declares Steamodded's `card_limit = 2` (its own slot plus one; a Negative edition is 1) and
  vanilla's `h_size = −1`, so the slots and hand size come and go the way Negative and Juggler's do.
- **Guy** reads the rank a card plays as, so a wild playing as a 3 counts.
- **Vanilla's Fibonacci and Hack count the 0 and the 1** (a9, 2026-11-22; UnStable does the same for its own). 0
  and 1 open the Fibonacci numbers, and Hack's 2 to 5 becomes every rank up to 5. Both read the rank a card plays
  as. Their text says so; their own rules are untouched.
- **Costs:** Bouton $8, Generator $7, Grundy $6, Hotstrat $5, Thermograph $8, Sprouts $8, Cantor $6, Cantor's
  Paradise $7, Birthday $6, Hilbert's Hotel $8, Conway, Berlekamp and Guy $20.

## 5. Blinds and decks — Decided

- **The Heap** (Boss): a hand whose scoring cards nim-sum to 0 scores nothing. Because a ⊕ a = 0, Pairs, Two Pairs
  and Four of a Kinds never score under it.
  - **As built** (`src/blinds.lua`): it reads Steamodded's final scoring cards (Splash, Stone and ω cards
    included) as the ranks they play as. An ω is a heap of its own that nothing finite cancels (§ 2.4), so a
    hand with one gets past. It appears from Ante 2, pays $5 and has the usual ×2 target.
- **The Misère** (Boss): the last mover loses, so your final hand of the round scores nothing.
  - **As built:** the hand that leaves you no hands is debuffed. The preview warns while one hand is left, so you
    know before you play it. From Ante 2.
- **Field Deck:** 64 cards, ranks 0 through A with the Cavalier (the field F₁₆) in every suit.
  - **As built** (`src/decks.lua`): the born ranks join the deck through vanilla's `extra_cards` when it is built,
    so they count toward the starting deck size (Erosion sees 64).
- **Ordinal Deck:** the standard 52 plus an ω of Spades, and a Cut in the consumable slot.

## 5½. Balance

Numbers that are Balatro-layer rather than maths, and why they are what they are. The first pass, by reasoning
against vanilla siblings rather than play:

- **ω eats double** (`WW.EAT = 2`, a9's call): an eater gains twice the eaten cards' chips, as Ceremonial Dagger takes
  double a joker's sell value. Feeding four 7s grows it by 56 chips a hand, at the cost of four cards from the deck.
- **Thermograph +3 mult per degree** (was +1): one hot card alone is worse off under Thermograph, because you'd have
  taken its top value and now get its mean (7±2: 9 chips becomes 7). At +1 per degree a rare paid +2 mult for that.
  At +3, 7±2 gives +6, and Heat adds 3 a step.
- **The tiers of ω** (§ 2.3): the ω coefficient is +Mult as it stands, and the ω² coefficient counts up from ×1, the
  way Hologram's and Cantor's Paradise's ×Mult do, so ω² is ×2 and 2ω² ×3. Read literally, ω² would be ×1, which
  does nothing. ×2^a would make merging ω² cards break even, but "2ω² gives ×4" reads strangely. +1 Mult for an ω
  is less than a Mult card's +4, but the ω also eats and always scores; ω² costs two Spectrals for an unbreakable
  ×2 that eats ω-cards too, strong beside Glass but fair.
- **Modifiers from vanilla's sources** (§ 5⅞): 1 in 5, the Standard Pack's seal rate.
- **The vouchers** take Tarot Merchant's and Tarot Tycoon's multipliers as they are (2.4 and 8 on the base rate).
- **Kept, with reasons:**
  - **Bouton ×3** is nearly always available (75% of 8-card hands make one with a Pair), but it costs the hand
    shape: kickers have to zero the nim-sum, and no straight ever does. Against The Duo (×2 on any Pair) it's fair
    for a rare.
  - **Generator** averages 16 chips a card, Arrowhead territory, plus rank changes that cut both ways.
  - **Cantor's Paradise** at ×0.1 per card: a hand that feeds four cards gains ×0.4, Hologram's pace, and the deck
    pays for it.
  - **Birthday** at +3 per day: a 3½ pays +6, and every Cut that refines a value adds a day.
  - **Conway's end cards** make any four-card run plus one card a straight. That's strong, but it's a legendary,
    and it's the same maths as the middle cards.
  - **The Heap** shuts out pair-based hands entirely for one blind, as The Psychic shuts out short ones.

## 5¾. With Quintessence

Quintessence makes Wild a fifth suit that counts as every suit. In Hackenbush that is a green edge, which either
player may cut, and a lone green edge is the nimber * (green Hackenbush is Nim). Quintessence's Wild pip is already a
`*`. So:

- **A Wild card's value carries a *:** a Wild 5 is 5*. It plays as a 5, shows its star and checkered pips, nim-sums as
  a 4, and is a day younger than 5 for Birthday. a9 decided this on 2026-11-15.
- **The * is the suit's.** It isn't stored in `ww_mod`. `WW.mod_of` adds it on read, and writes take it off first.
  So it comes and goes with the suit (The Star takes it away, The Lovers gives it), and every Move acts on the whole
  value:
  - Nimbus on a Wild 5 gives a plain 5 (* + * = 0).
  - Heat gives 5±1.
  - Cut gives exactly {L|R}, storing a * where it must cancel the suit's.
- An ω with a * still eats: ω + * reads \*ω. Omega itself makes exactly ω on a Wild card, storing the * that cancels
  the suit's.
- The born ranks have Wild fronts, values play in Spectrum hands, and Repaint leaves Wild cards alone, because a green
  edge is its own negative.

## 5⅞. In the shop and packs — Decided

a9 agreed these on 2026-11-23, so that a run meets the mod without first buying a Move (`src/shop.lua`).

- **Modifiers from vanilla's own sources.** A random playing card a pack deals (the Standard Packs), or one the shop
  sells once Illusion is redeemed, has a 1 in 5 chance of a modifier: +½, *, or ±1, equally likely. It is rolled
  after vanilla's enhancement, edition and seal, in the modifier's own slot. A Stone card, another mod's rank or a
  card that already has a modifier is left alone. Without Illusion the shop's playing cards stay plain, as they
  carry no enhancement, edition or seal either.
- **Two vouchers,** Tarot Merchant and Tarot Tycoon for Moves: **Lessons in Play** makes Moves appear 2X as often in
  the shop (the rate goes from 2 to 4.8), and **On Numbers and Games**, which needs it, 4X (16). They're named for
  two books: Albert, Nowakowski and Wolfe's textbook, which starts you on combinatorial games, and Conway's own,
  where the surreal numbers start.
- **The Game Tag:** Charm Tag's twin, a free Mega Game Pack when the next Blind is to be chosen.
- **No unlocks.** Everything stays unlocked from the start: locking content annoys players who installed the mod to
  play it (a9, 2026-11-23).

## 6. Left out

- **Clifford algebras:** off-theme. They are about suits, not ranks, and {L|R} doesn't build them.
- **Loopy games.**
- **A Cube Move:** too situational.
- **A positional Cut card:** replaced by the Cut Move.
- **A joker that pays the nim-product:** exact, but too hard for players to plan around.
- **An UnStable dependency:** the mod is standalone. If UnStable is installed, its decimal ranks could be read as
  numbers (not yet discussed).
- **Split**, the inverse of Cut: too situational. Its uses were undoing a Cut, destroying a 0 and lowering a rank by
  one, and none of them comes up often.
- **Sente:** only useful in a very hot deck.
- **Dedekind** (mass Cut of the whole hand): too close to Immolate. Its positional reading of {L|R} moved to Conway
  (§ 7).
- **Conway** as "gains ×0.5 mult per Move used": not legendary, and too close to Constellation.
- **Unlock conditions** (§ 5⅞).
- **ω³ and beyond:** Balatro has no fourth tier (§ 2.4).

## 7. Candidates — Jokers

a9 thought most of these were great. They wait on tuning and a final call.

**Hot games.**

- **Coupons** (uncommon, economy): Berlekamp priced temperature with coupon stacks. Earn $1 per point of temperature
  on each hot card the Blind takes.

**Numbers and surreals.**

- **Magic Square** (uncommon): ×3 mult if three scored ranks from A to 9 (Ace as 1) sum to 15. Pick Fifteen is
  tic-tac-toe in disguise, played on the 3×3 magic square.
- **Wythoff** (uncommon): ×2 mult if the hand contains a Wythoff pair: 1·2, 3·5, 4·7, 6·10, 8·Q or 9·A. These are the
  losing positions of Wythoff's game, ⌊nφ⌋ and ⌊nφ²⌋: golden-ratio cousins of vanilla's Fibonacci.

**Nimbers.**

- **Nothing** (uncommon): each 0 held in hand gives ×1.5 mult; Baron for the game with no moves.
- **Moore** (rare, for experts): ×mult if, in every binary place, the played ranks' bits sum to a multiple of 3.
  These are the losing positions of Moore's Nim₂, Bouton's big brother. It's opaque, so cut it if the roster is full.

**Rows.** The hand is ordered.

- **Toads and Frogs** (common): +12 mult if the played cards alternate colour from left to right.
- **Tweedledee** (uncommon): ×2 mult if the hand mirrors itself: read backwards, the ranks are the same and the colours
  are swapped, as in 7♠ K♥ 3♣ K♠ 7♥. This is G + (−G) = 0, the mirror strategy.
- **Glider** (rare): copies the Joker to its right, like Blueprint, but moves one slot right after every round,
  wrapping around. It's the glider from Conway's Life, which the last chapter of Winning Ways covers.

**Hackenbush.** Black suits are blue edges (yours), red suits red edges (the Blind's), Wild cards green (either
side's), and the leftmost card is the ground. Cutting an edge removes everything above it, and you may cut only your
own colour. Cutting is the mechanic, not reading a stalk's value: you can reorder a hand freely, so a stalk read from
it only reflects which card you put first.

- **Hackenbush** (rare): discarding a black card also discards every card to its right, and red cards can't be
  discarded, so they leave only by falling. One discard can clear most of a hand, which makes it strong beside
  Castle, Yorick and Mail-In Rebate. Test it in a real run before deciding.
- **Hackenbush** (Move): fuses up to 3 selected cards into {black | red}, with Wild cards on both sides. Colour picks
  the side, so order doesn't matter, and it makes games with several options, which Cut never can: ♠9 ♣3 | ♥5 is
  {9, 3 | 5} = 7±2.
- **A stalk across hands** (uncommon): each all-black hand adds a blue edge and each all-red hand a red one, and the
  joker pays the stalk's value. After the first red hand every gain is a fraction (sign expansion). It's the weakest
  of the three, but it pairs with Birthday.

**Legendaries: the authors.** Conway, Berlekamp and Guy are all decided (§ 4).

## 8. Candidates — Blinds and decks

- **Zugzwang** (Boss): the Blind moves first, so you score the Right stop. It only hurts hot cards, the way The Plant
  only hurts face cards.
- **The Axe** (Boss): the Blind's side of Hackenbush (§ 7). After each hand it cuts your leftmost red card and every
  card to its right. Sorting reds to the right limits the damage, but that fights the other uses of card order (ω
  eats leftward, Conway reads neighbours). a9 likes it and parked it on 2026-11-15.
- **Later:** challenges, one per family (Nim on the Field Deck under The Heap; a deck of switches; building the
  numbers from the born ranks), and a Hackenbush challenge that could hold The Axe.

## 9. Open questions

- None right now.

## 10. Facts this rests on

Checked with ogdoad's Python bindings unless marked standard.

- **Cut values:** {3|7} = 4, {3|4} = 3½, {3|} = 4, {|2} = 0, {|} = 0, {5|5} = 5*, {9|5} = 7±2 and {6|4} = 5±1.
  {6|4} is confused with exactly 4, 5 and 6, and 5* is confused with 5.
- **The hotstrat** matched the exact Left stop on 200 random sums of switches.
- **Heat and Cool:** heating leaves 5 unchanged and turns {6|4} into {7|3}. Cooling {6|4} by 1 gives stops (5, 5).
- **Nimbers:**
  - The standard deck's ranks (2–J and Q–A, which are 2–11 and 13–15) contain 22 distinct-rank triples, 55
    quadruples and 72 quintuples that nim-sum to 0.
  - A random 5-card hand nim-sums to 0 6.25% of the time.
  - An 8-card hand holds a zero-sum triple 91.6% of the time.
  - No straight nim-sums to 0, counting all 16 five-rank runs, including those through the Cavalier and the born
    ranks.
  - Any 5 ranks contain a group that nim-sums to 0 (standard: linear dependence in F₂⁴).
- **Squares** (nim-multiplication) permute ranks in the Frobenius cycles above. **15, the Ace, generates F₁₆'s
  multiplicative group**: its powers visit every nonzero rank once.
- **Cut(J, Q) = {11|13} = 12**, the Cavalier.
- **Sitting ranks:** {7±2|3} has mean 5 and stops 5 and 3, and is confused with exactly 3 and 4. 13¼±4 = {17¼|9¼} is
  confused with 10 through A.
- **Heat can pass zero:** {2|0} heated by 1 is {3|−1}, which is confused with 0, 1, 2 and 3.
- **The wilds** (the engine; ogdoad has no transfinite games): {ω|0} is confused with every rank from 0 to A, and
  {ω|2} with 2 to A.
- **ω:**
  - ω³ = 2 in nim arithmetic, and the three cube roots of 2 are ω, ω·2 and ω·3. They nim-sum to 0 and nim-multiply
    to 2 (Vieta).
  - Ordinal addition: ω + 1 ≠ 1 + ω = ω, and ω ⊕ ω = 0.
- **ω²** (the engine checks itself; ogdoad has no transfinite numbers):
  - **Standard:** α + ω^β = ω^β exactly when α < ω^β (the powers of ω are the additively indecomposable ordinals),
    so (ω·k + x) + ω² = ω²; and like terms add, ω + ω = ω·2.
  - **Standard:** Conway's nim-addition of ordinals is XOR of their binary expansions, ω^k = 2^(ω·k), so it goes
    digit by digit in Cantor normal form: (ω + 3) ⊕ (ω + 5) = 6.
  - **Standard (Gonshor):** the sign expansion of a·ω² + k·ω + x is a's signs each repeated ω² times, then k's each
    ω times, then x's. `tests/known_test.lua` checks the simplest-number code built on it: 600 random cuts with
    ω² terms, each result between its bounds and none of its prefixes there.
  - **Standard:** in a positive interval that holds an ordinal, the least ordinal there is the simplest number. So
    {ω | ω²} = ω + 1, {ω² + 5ω | 2ω²} = ω² + 5ω + 1, and {0 | ω²} = 1. Where the
    interval holds no ordinal the expansion decides: {ω² − ω | ω²} = ω² − 1.
- **Standard results:**
  - A switch {a|b} with a > b is confused with every number in [b, a].
  - ±x is its own negative.
  - Wythoff's losing positions are (⌊nφ⌋, ⌊nφ²⌋).
  - Moore's Nim_k loses exactly when every binary place sums to 0 mod k + 1.

## 10½. Questions a9 asked along the way

- **Doesn't K + ω reduce to ω?** Not for surreal numbers, whose (Conway's) sum commutes, so K + ω = ω + 14, a
  different number from ω. Only ordinal addition, which depends on order, absorbs: 14 + ω = ω, but ω + 14 ≠ ω even
  there. That ordinal rule is what the played row uses for eating (§ 2.4); values use Conway's sum. The Omega
  Spectral uses the ordinal rule too: it adds the next power of ω on the right of the card, so the card becomes ω
  (or ω²). Sum(K, ω) is still ω + 14.

## 11. Engine

Built and tested (`src/engine/`, `tests/`).

- **Numbers** (`num.lua`) have the form a·ω² + k·ω + x, with a, k and x dyadic, stored as doubles on a grid:
  multiples of 2^-32 below 2^20 in magnitude. That takes 52 of a double's 53 bits, so sums are exact. A value off the grid, such
  as a 33rd nested Cut between neighbours, is refused when it's made rather than rounded. Notation that isn't
  dyadic, like "1/3", is refused too.
  - Order is lexicographic.
  - A number's sign expansion is a's signs, each repeated ω² times, then k's, each repeated ω times, then x's
    (Gonshor). Runs are ordinals ω²·l + ω·m + n. The simplest number between two numbers is computed on these
    expansions, so {15|ω} = 16, {ω/2|ω} = ω − 1 and {ω|ω²} = ω + 1 come out of the same code as {3|4} = 3½.
  - Canonical options come from the expansions too. ω's Left options (0, 1, 2, …) are an infinite family with no
    best member, and so are ω²'s (ω·m + n).
  - Notation: `w^2`, `2w^2+w-3`, `w^2/2`.
- **Games** (`game.lua`) are short games with number leaves, kept canonical and interned.
  - **Number test:** a game equals a number exactly when some number fits between its options (the simplicity
    theorem), and the fitting interval is read off the options' stops. This test runs before any other reduction,
    so later comparisons never meet a form that secretly equals a number.
  - **Reduction:** dominated options are removed and reversible options bypassed, including reversal through a
    number's canonical options.
  - **Operations:** comparison (by Number Translation against numbers), sum, negation, stops, thermographs
    (temperature and mean), heating, cooling, birthday, and the loose "acts as rank r" test.
  - **The one known gap:** an option that is a number with infinitely many options (ω, ω − 1, ω/2) is never
    bypassed, so a game with one may not be fully reduced. Values and comparisons stay exact.
- **Nim arithmetic** (`nim.lua`) covers F₁₆: nim-multiplication by Conway's Fermat 2-power rules, 15's cycle and
  discrete logs, and mex.
- **Hand scoring** (`play.lua`) plays a hand out as one sum: you move first, nobody moves in a number, and play ends
  when every card is a number. It returns the total (the Left stop), the number each card ends on, and who moved
  where. Equal moves go to the hotter card, then the leftmost.
- **Numbers' temperature** is reported as −1, following ogdoad.
- **Tests:** `tools/fixtures.py` writes `tests/fixtures/ogdoad.lua`, and `scripts/test` checks the engine against all
  of it:
  - 240 random games: canonical forms, stops, temperatures, means, birthdays, heating by 1, cooling by 1 and by ½,
    and the ranks each one plays as;
  - 240 sums and comparisons;
  - 180 whole hands;
  - the F₁₆ table;
  - 200 finite simplest numbers;
  - 200 orderings of transfinite numbers.

  ogdoad has no simplest-number oracle for transfinite numbers, so `tests/known_test.lua` checks those itself: each
  result lies between its bounds, and none of its prefixes does. ogdoad is AGPL and stays a development tool;
  nothing from it ships.
- **Rank assignment** (`hands.lua`) proposes the assignments worth trying for a hand, one per rank pattern:
  - every rank that flexible cards can join, which covers Five, Four and Three of a Kind and Pairs;
  - the highest two ranks that can make a Full House, and the highest that can make Two Pair;
  - every straight window a matching can fill;
  - a default.

  Tie groups of equal rankless values pair only with each other.
- **In the game** (`src/cards.lua`, `src/ranks.lua`):
  - **Ranks:** the born ranks and ω are registered, with fronts Fable drew from vanilla's sprites
    (`art/fronts.py`).
  - **Reading a hand:** `evaluate_poker_hand` runs the game's own evaluator once per candidate assignment, so other
    mods' hands count too, and keeps the best hand by the hand list's order, then the most scoring cards.
  - **Faces:** a card with a modifier draws its own front (§ 2.5; `src/fronts.lua`, `src/faces.lua`). Fable's symbol
    font is a fallback for Balatro's pixel font, so text can say ω, ½ and ↑ (`src/font.lua`).
  - **Hooks:** while a hand is assigned, `get_id`, `get_nominal` and `is_face` report the rank a card plays as.
    Outside a hand being read, `get_nominal` sorts a card by the rank it sits on (a 3½ among the 3s).
    `get_X_same` handles tie groups. Straights are Steamodded's own: the optional Cavalier is just another entry in
    the Jack's next list.
  - **Values:** a card's value is computed as rank + modifier and cached by both. `WW.set_value` puts a made value
    on its rank, and `WW.add_mod` adds to a modifier (for Nimbus).
  - **Scoring:** `SMODS.calculate_main_scoring` resolves the scoring cards' values, and `get_chip_bonus`,
    `get_chip_mult` and `get_chip_x_mult` pay each card the tiers of the number it ends on.
  - **Speed:** reading a hand with two wilds and a hot card takes about 3 ms in the game.
- **Exercised end to end:** `scripts/runtest` starts a real run on the Field Deck with saving switched off and plays
  scripted hands through the game's own code:
  - the deck: 64 cards, 12 of them born ranks;
  - a hot card's bite: 7 7 7±2 scores exactly 159;
  - infinity eating: 7 7 ω+14 9 9 is a Pair worth 198 (the ω's +1 Mult included), the 7s are destroyed, and the ω
    keeps +28;
  - Cut used through the game's own button;
  - each joker in turn: Bouton on 1 2 3 (24), Generator on an Ace (18, and it becomes a 9), Grundy on 0 1 2 3 4
    (+5 mult), Hotstrat and Thermograph on a lone 7±2 (23 and 36), Sprouts on 3 7 (a new 4), Cantor at a Blind
    (a missing pair), Cantor's Paradise on 7 7 ω+14 9 9 (×1.2: 237), Conway on K 5 K (Three of a Kind, 165);
  - The Heap: a Pair scores 0, three 9s score 171;
  - the powers of ω: (ω + 3)(ω + 5) 9 9 merges into 2ω + 5, which takes the eaten 3 as 6 bonus chips, and scores
    156; Omega through the game's button lifts an
    ω to ω², which can't go further; ω² 9 9 9 scores 342 (×2);
  - the vouchers set the Move rate to 4.8, then 16; pack cards roll modifiers, and shop cards only under Illusion;
  - the Game Tag opens a free Mega Game Pack of five Moves;
  - the Ordinal Deck: 53 cards, one of them the ω of Spades, and a Cut.
