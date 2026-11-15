# Winning Ways — design sketch

*Status: the engine, values, Moves, ω eating, the decided jokers, The Heap and the Field Deck are built (§ 11).
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
- With the born ranks, the deck's ranks 0–15 form the field F₁₆ under nim arithmetic.
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
- **Equal values pair**, even when they have no rank: two 3½s are a Pair.
- **Infinite cards pair by galaxy**, the set of values a finite distance apart (nonstandard analysis's word):
  ω + 13 pairs with ω + 2, but not with 2ω. Seen from the finite ranks, everything in one galaxy is equally far
  away.
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
  - **Infinite parts never become chips:** ω scores 0, and ω + 14 scores a King's 10.

### 2.3½ Values on cards: rank + modifier

- **A card's value is its rank plus a modifier.** The modifier is any game, and it is stored as canonical notation
  in `card.ability.ww_mod`:
  - 3½ is a 3 with +½;
  - 5* is a 5 with *;
  - 7±2 is a 7 with ±2.

  Cards without a modifier are worth their rank.
- **Its own slot.** The modifier sits beside enhancement, edition and seal, so a card can be Glass *and* +½. It will
  be drawn as a badge over the normal rank front.
- **Rank changes keep it.** Strength, Ouija and Generator change the rank, the modifier stays, and the value shifts
  with the rank: 7±2 on an 8 is 8±2. This is coherent because heating and cooling commute with adding a number:
  ∫^t(G + x) = ∫^t G + x and (G + x)_t = G_t + x. Copies (Death, Cryptid) keep the modifier.
- **Which rank a made value sits on.** When a Move makes a value V, the card sits on the rank nearest V's mean among
  the ranks V plays as (the lower one on a tie), or on the nearest rank at all when V plays as none. Its modifier is
  V minus that rank. So 3½ sits on the 3 with +½, and 7±2 on the 7 with ±2. The wild {ω|2} has an infinite mean, so
  it sits on the Ace, with the modifier {ω−15 | −13}.
- **Equal values play alike.** A 3 with +½ and a 4 with −½ are both 3½, so they pair.
- **No rank.** A value that plays as no rank (3½, ω) counts as having no rank, like a Stone card, except that equal
  values still pair.
- **A dormant modifier.** On a card with no rank of its own (Stone) or another mod's rank, the modifier lies dormant
  until the card has one of ours again.

### 2.4 Transfinites

- **ω only enters from outside**, through the Omega Spectral, which adds ω to a card's modifier. No chain of Moves on
  finite cards can reach it, because every value they build is born on a finite day.
- **An ω card:**
  - is above every rank, and pairs with any card in its galaxy (§ 2.2);
  - always scores, like a Stone card;
  - **eats** the finite cards between it and the nearest infinite card to its left (n + ω = ω). Eaten cards don't
    count toward the hand, and are destroyed;
  - **grows like Ceremonial Dagger**: the eaten cards' chips become its permanent bonus chips. Its value doesn't
    change; the bonus is stored the way Hiker's is.
  - scores its rank's chips: a King with +ω is ω + 14, and scores a King's 10.
- **Infinities don't eat each other.** [junk, ω, junk, ω] adds up to ω + ω = ω·2, so each ω eats its own junk and
  both survive.
- **Two additions.** The played row uses ordinal addition, which depends on order. Sum uses Conway's sum, which
  commutes. So ω·k only comes from Sum (ω + ω = ω·2), and Sum(K, ω) = ω + 14.
- **As built** (`src/omega.lua`):
  - **Who eats:** a card eats when its value is a positive infinite number (ω + 14, 2ω, ω/2) and it isn't
    debuffed.
  - **Who blocks:** any infinite value stops a run of eaten cards, the wild included.
  - **When:** the eater grows as the hand is played, so it scores its new chips that same hand. The eaten cards are
    left out of the hand being read, so a preview already shows the hand without them; Splash can't make them
    score; and they're destroyed once the hand has scored.
- **The wild rank {ω|2}** (made with Cut) has infinite temperature, so it is always the hottest card in a hand. You
  take ω (0 chips), and the Blind gets first pick of your other hot cards.

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

Adds * to the modifiers of up to two cards: a nimber halo. The vanilla Tarot already has the name "Star".
- For hands nothing changes: n* plays as n.
- In nim arithmetic n* is the heap n ⊕ 1, so Nimbus is Bouton's tuning knob.
- Haloed cards cancel in pairs under Sum: 5* + 5* = 10.

### Mex

The leftmost selected card becomes the mex of the other selected cards. On its own, a card becomes a 0; beside a 0 it
becomes a 1; beside a 0 and a 1 it becomes a 2. It's the easy way to make born ranks, and it feeds Grundy.

### Omega (Spectral)

Adds ω to a selected card's modifier. The card keeps its rank and its rank's chips, and starts eating (§ 2.4). An
earlier version turned a 2 into ω, but a Spectral pack's hand often holds no 2: 8 cards contain one only about 52% of
the time.
- **The ω³ = 2 nod stays in the text:** ω is the smallest cube root of 2 in nim arithmetic, and no finite rank is one
  (the nim-cubes of 1–15 are only 1, 8, 10, Q and K).
- **No bonus for using a 2.** Making ω's siblings ω·2 and ω·3, the other two cube roots, as well would give three
  eaters from one card, since infinities don't eat each other. That's too strong.

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
- **Thermograph** (rare): hot cards score their mean, with no bite, and add their temperature as +mult.
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

### 4.1 As built (`src/jokers.lua`)

Claude's calls where the sketch left room, waiting on a9's say-so:

- **"Rank" means the rank a card plays as** in the hand being scored: a wild in a Pair of Kings is a King. Cards with
  no rank (Stone, 3½, ω) are invisible to nim-sums and the mex, as a 0 is. Cards infinity ate don't count.
- **Bouton:** a flexible kicker (one that doesn't score) may play as any of its ranks, because you choose in a
  confused position. So a wild kicker completes a Bouton whenever the other cards nim-sum to a rank it can play as
  (K, Q and a wild: K ⊕ Q = 3). Scoring cards keep the rank the hand gave them.
- **Generator** pays **+2 chips per place** on the Ace's cycle (A 2, 9 4, …, 1 30; 16 on average), from the card's own
  rank, then steps that rank. It acts on the rank under any modifier (K+ω becomes 6+ω), never on Stone cards, and
  the 0 neither pays nor moves. Blueprint copies the chips but not the step.
- **Grundy** grows before the hand scores, so the mex counts the same hand. Only the scoring cards count, so a High
  Card's kickers don't.
- **Hotstrat** retriggers cards whose value has temperature above 0: 7±2 and the wild, not *, ↑ or ↓.
- **Thermograph** leaves the wild alone: its temperature is infinite (ω/2 − 1), and an infinite +mult has no
  meaning. Every other hot card plays as its mean in the hand's play-out, so nobody moves in it, and gives its
  temperature (which can be fractional) as +mult. With Hotstrat both happen twice.
- **Sprouts** makes the new card as Cut does: a copy of the left card, worth {left | right}, taking what it lacks
  (enhancement, edition, seal) from the right one. Like DNA, the card goes into the hand.
- **Cantor** picks a missing standard pair at random, then a missing born-rank pair (0, 1, C) once all 52 are there.
  On a full Field Deck there is nothing to add, and it does nothing. A Stone card, or a 3 worth 3½, doesn't hold its
  pair.
- **Cantor's Paradise** hears about eating through a custom context (`context.ww_eaten`, sent by `src/omega.lua`
  before the hand scores), so the new ×mult applies to that same hand.
- **Conway's end cards** have one side empty: {|R} is 0 and {L|} is L rounded up. So [2, 3, 4, 5, x] is a straight
  for any x, as x plays as {5|} = 6. Stone cards get no ranks and act as no neighbour. The extra ranks only widen
  what cards play as; every card still scores its own value (K 5 K scores the 5's 5 chips).
- **Costs:** Bouton $8, Generator $7, Grundy $6, Hotstrat $5, Thermograph $8, Sprouts $8, Cantor $6, Cantor's
  Paradise $7, Conway $20.

## 5. Blinds and decks — Decided

- **The Heap** (Boss): a hand whose scoring cards nim-sum to 0 scores nothing. Because a ⊕ a = 0, Pairs, Two Pairs
  and Four of a Kinds never score under it.
  - **As built** (`src/blinds.lua`): it reads Steamodded's final scoring cards (Splash, Stone and ω cards
    included) as the ranks they play as. It appears from Ante 2, pays $5 and has the usual ×2 target.
- **Field Deck:** 64 cards, ranks 0 through A with the Cavalier (the field F₁₆) in every suit.
  - **As built** (`src/decks.lua`): the born ranks join the deck through vanilla's `extra_cards` when it is built,
    so they count toward the starting deck size (Erosion sees 64).

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

## 7. Candidates — Jokers

a9 thought most of these were great. They wait on tuning and a final call.

**Hot games.**

- **Coupons** (uncommon, economy): Berlekamp priced temperature with coupon stacks. Earn $1 per point of temperature
  on each hot card the Blind takes.

**Numbers and surreals.**

- **Birthday** (uncommon): pays for complicated values, e.g. +mult per day a scored card was born after its integer
  part (3 is born on day 3, 3½ on day 4, 3¼ on day 5). Needs a number.
- **Magic Square** (uncommon): ×3 mult if three scored ranks from A to 9 (Ace as 1) sum to 15. Pick Fifteen is
  tic-tac-toe in disguise, played on the 3×3 magic square.
- **Wythoff** (uncommon): ×2 mult if the hand contains a Wythoff pair: 1·2, 3·5, 4·7, 6·10, 8·Q or 9·A. These are the
  losing positions of Wythoff's game, ⌊nφ⌋ and ⌊nφ²⌋: golden-ratio cousins of vanilla's Fibonacci.

**Nimbers.**

- **Nothing** (uncommon): each 0 held in hand gives ×1.5 mult; Baron for the game with no moves.
- **Moore** (rare, for experts): ×mult if, in every binary place, the played ranks' bits sum to a multiple of 3.
  These are the losing positions of Moore's Nim₂, Bouton's big brother. It's opaque, so cut it if the roster is full.

**Transfinite.**

- **Hilbert's Hotel** (rare): takes no Joker slot, because there's always room for one more, and gives +1 Joker slot.
  That makes it worth two slots, so it needs a cost. Ectoplasm's −1 hand size is one option.

**Rows.** The hand is ordered.

- **Toads and Frogs** (common): +12 mult if the played cards alternate colour from left to right.
- **Tweedledee** (uncommon): ×2 mult if the hand mirrors itself: read backwards, the ranks are the same and the colours
  are swapped, as in 7♠ K♥ 3♣ K♠ 7♥. This is G + (−G) = 0, the mirror strategy.
- **Glider** (rare): copies the Joker to its right, like Blueprint, but moves one slot right after every round,
  wrapping around. It's the glider from Conway's Life, which the last chapter of Winning Ways covers.

**Legendaries: the authors.** Conway is decided (§ 4).

- **Berlekamp:** each scored hot card gives ×1.5 mult. He wrote the book on thermography (and on Dots and Boxes).
- **Guy:** the Strong Law of Small Numbers. Each scored card of rank 5 or lower, 0 and 1 included, gives ×1.5 mult: a
  Triboulet for small numbers.

## 8. Candidates — Blinds and decks

- **Zugzwang** (Boss): the Blind moves first, so you score the Right stop. It only hurts hot cards, the way The Plant
  only hurts face cards.
- **The Misère** (Boss): the last mover loses, so your final hand of the round scores nothing.
- **Ordinal Deck:** starts with an ω card and a Cut.
- **Later:** vouchers, tags, challenges, and the Moves' Game Pack art.

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
- **ω:**
  - ω³ = 2 in nim arithmetic, and the three cube roots of 2 are ω, ω·2 and ω·3. They nim-sum to 0 and nim-multiply
    to 2 (Vieta).
  - Ordinal addition: ω + 1 ≠ 1 + ω = ω, and ω ⊕ ω = 0.
- **Standard results:**
  - A switch {a|b} with a > b is confused with every number in [b, a].
  - ±x is its own negative.
  - Wythoff's losing positions are (⌊nφ⌋, ⌊nφ²⌋).
  - Moore's Nim_k loses exactly when every binary place sums to 0 mod k + 1.

## 10½. Questions a9 asked along the way

- **Doesn't K + ω reduce to ω?** Not for surreal numbers, whose (Conway's) sum commutes, so K + ω = ω + 14, a
  different number from ω. Only ordinal addition, which depends on order, absorbs: 14 + ω = ω, but ω + 14 ≠ ω even
  there. That ordinal rule is what the played row uses for eating (§ 2.4); values use Conway's sum.

## 11. Engine

Built and tested (`src/engine/`, `tests/`); nothing in the game uses it yet.

- **Numbers** (`num.lua`) have the form k·ω + x, with k and x dyadic, stored as doubles on a grid: multiples of
  2^-32 below 2^20 in magnitude. That takes 52 of a double's 53 bits, so sums are exact. A value off the grid, such
  as a 33rd nested Cut between neighbours, is refused when it's made rather than rounded. Notation that isn't
  dyadic, like "1/3", is refused too.
  - Order is lexicographic.
  - A number's sign expansion is k's signs, each repeated ω times, followed by x's signs (Gonshor). The simplest
    number between two numbers is computed on these expansions, so {15|ω} = 16 and {ω/2|ω} = ω − 1 come out of the
    same code as {3|4} = 3½.
  - Canonical options come from the expansions too. ω's Left options (0, 1, 2, …) are an infinite family with no
    best member.
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
  - **Ranks:** the born ranks are registered, with fronts Fable drew from vanilla's sprites (`art/fronts.py`).
  - **Reading a hand:** `evaluate_poker_hand` runs the game's own evaluator once per candidate assignment, so other
    mods' hands count too, and keeps the best hand by the hand list's order, then the most scoring cards.
  - **Faces:** a modifier is colour text beside the corner index, mirrored like vanilla's (3+½, 7±2, K+ω). The wild's
    index is a white ± stamp on mult red. A * is a halo. Fable's symbol font is a fallback for Balatro's pixel font,
    so text can say ω, ½ and ↑ (`src/faces.lua`, `src/font.lua`).
  - **Hooks:** while a hand is assigned, `get_id`, `get_nominal` and `is_face` report the rank a card plays as.
    `get_X_same` handles tie groups. Straights are Steamodded's own: the optional Cavalier is just another entry in
    the Jack's next list.
  - **Values:** a card's value is computed as rank + modifier and cached by both. `WW.set_value` puts a made value
    on its rank, and `WW.add_mod` adds to a modifier (for Nimbus and Omega).
  - **Scoring:** `SMODS.calculate_main_scoring` resolves the scoring cards' values, and `get_chip_bonus` pays each
    card the chips for the number it ends on.
  - **Speed:** reading a hand with two wilds and a hot card takes about 3 ms in the game.
- **Exercised end to end:** `scripts/runtest` starts a real run on the Field Deck with saving switched off and plays
  scripted hands through the game's own code:
  - the deck: 64 cards, 12 of them born ranks;
  - a hot card's bite: 7 7 7±2 scores exactly 159;
  - infinity eating: 7 7 K+ω 9 9 is a Pair worth 104, the 7s are destroyed, and the King keeps +14;
  - Cut used through the game's own button;
  - each joker in turn: Bouton on 1 2 3 (24), Generator on an Ace (18, and it becomes a 9), Grundy on 0 1 2 3 4
    (+5 mult), Hotstrat and Thermograph on a lone 7±2 (23 and 36), Sprouts on 3 7 (a new 4), Cantor at a Blind
    (a missing pair), Cantor's Paradise on 7 7 K+ω 9 9 (×1.2, 124), Conway on K 5 K (Three of a Kind, 165);
  - The Heap: a Pair scores 0, three 9s score 171.
- **Still to build:**
  - **Card faces:** with modifiers, a card shows its normal rank front plus a modifier badge (+½, *, ±2, ω), with
    the exact value in the tooltip. That's far easier than procedural fronts, but it is still the next thing to
    prototype.
