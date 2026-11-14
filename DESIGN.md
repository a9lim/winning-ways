# Winning Ways — design sketch

*Status: the value engine is being built (§ 11); none of the content exists yet. **Decided** sections record what a9
and Claude have agreed. **Candidates** are proposals still waiting on a9's call. § 10 lists the facts the design
rests on, each one checked with ogdoad or marked standard.*

Winning Ways is a Balatro mod about Conway's numbers and games. It's named for Berlekamp, Conway and Guy's book, and it
makes one promise: the maths is exact. Every value a card can hold is a real surreal number or combinatorial game,
every rule is a theorem or a definition from the literature, and ogdoad (a9's library) checks the engine.

## 1. The idea

Conway built every number and every game from one definition: a position {L | R}, given by the options Left and Right
can move to. Balatro's ranks are already numbers (2–10, J = 11, Q = 12, K = 13, A = 14), so every card is already a
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
- Vanilla cards are the integers 2–14.
- **Born ranks** are not in the starting deck; only Moves (and Generator) make them:
  - **0** = {|}, the game with no moves.
  - **1** = {0|}.
  - **Knight** = {A|} = 15. It is a face card (tarot's fourth court card, which the French deck dropped), scores 15
    chips, and sits above the Ace in straights (J-Q-K-A-Kn). The corner letter is open; "C" for *Cavalier* is one
    option.
- With the born ranks, the deck's ranks 0–15 form the field F₁₆ under nim arithmetic.
- Straights run through the born ranks, from 0-1-2-3-4 up to J-Q-K-A-Kn, and the Ace still plays low (A-2-3-4-5).

### 2.2 Loose confusion

A card **acts as any rank its value equals or is confused with**. For example:

| value | acts as |
| --- | --- |
| 7 | 7 |
| 3½ | no rank (scores 3.5 chips) |
| 5* | 5 |
| 5±1 = {6 \| 4} | 4, 5 or 6 |
| 8±6 = {A \| 2} | every rank from 2 to A |
| {ω \| 2} | every rank from 2 up: the **wild rank** |
| ω | no rank |

- **Hand type:** you choose the ranks. You are the first player in a confused position, and the first player wins
  those. Assigning ranks is a matching problem like Quintessence's suit matching, and easier, because each card's
  options form one range of ranks.
- **Equal values pair**, even when they have no rank: two 3½s are a Pair, and so are two ωs.
- **Rank-specific jokers** see the rank a card played as. Wee sees a 2 in a Five of a Kind of 2s.

### 2.3 Scoring: the hand is a game

- The scoring cards' values add up to one game. You move first, the Blind replies, and chips come from the Left
  stop of the sum.
- **Per card**, chips follow the hotstrat. The hottest scoring card pays you its top value, the Blind takes the bottom
  value of the next-hottest, and so on, alternating. This is exact for sums of switches. For general games the
  engine searches the (small) sum exactly.
- A hand of plain numbers scores exactly as in vanilla.
- **Infinite parts never become chips.** A card scores its value's finite part: ω scores 0 and ω + 13 scores 13.

### 2.4 Transfinites

- **ω only enters from outside**, through the Omega Spectral. No chain of Moves on finite cards can reach it, because
  every value they build is born on a finite day.
- **An ω card:**
  - is above every rank, and pairs only with an equal value;
  - always scores, like a Stone card;
  - **eats** the finite cards between it and the nearest infinite card to its left (n + ω = ω). Eaten cards don't
    count toward the hand, and are destroyed;
  - **grows like Ceremonial Dagger**: the eaten cards' chips become its permanent bonus chips. Its value stays
    exactly ω; the bonus is stored the way Hiker's is.
- **Infinities don't eat each other.** [junk, ω, junk, ω] adds up to ω + ω = ω·2, so each ω eats its own junk and
  both survive.
- **Two additions.** The played row uses ordinal addition, which depends on order. Sum uses Conway's sum, which
  commutes. So ω·k only comes from Sum (ω + ω = ω·2), and Sum(K, ω) = ω + 13, which scores 13 chips.
- **The wild rank {ω|2}** (made with Cut) has infinite temperature, so it is always the hottest card in a hand. You
  take ω (0 chips), and the Blind gets first pick of your other hot cards.

## 3. Moves — Decided

Moves are a new consumable type (working name), sold in Game Packs.

### Cut

- Select 0, 1 or 2 cards. With two, the card further left in hand is L.
- Both parents are used up and a new card is born: the old positions become the new card's options.
  - The new card takes both parents' enhancement, edition and seal.
  - When both parents have one of a kind, the left parent's wins, and so does its suit.
- With no cards selected, Cut makes a new 0. With one card it makes {A|}, which rounds up: 7 → 8, 3½ → 4, A → Knight.

| Cut on | value | plays as |
| --- | --- | --- |
| (nothing) | 0 | 0 |
| 3, 7 | 4 | 4 |
| 3, 4 | 3½ | no rank |
| 5, 5 | 5* | 5 |
| 9, 5 | 7±2 | 5–9 |
| A, 2 | 8±6 | 2–A |
| ω, 2 | {ω \| 2} | every rank |

### Sum

A + B under Conway's sum, with the same inheritance as Cut:

- 3 + 4 = 7.
- 5±1 + 5±1 = 10, because ±1 is its own negative.
- K + ω = ω + 13.

### Heat and Cool

- **Heat** raises a game's temperature by 1 ({6|4} → {7|3}), giving a wider range and a bigger bite. Numbers don't
  heat.
- **Cool** lowers it by 1. Cooling 5±1 gives 5*, which plays as 5.

### Frobenius

Nim-squares a card's rank. The cycles are 2↔3, 4→6→5→7→4, 8→K→10→A→8 and 9→Q→J→Kn→9; 0 and 1 stay where they are.

### Tweedledum

The set's Fool: it copies the last Move used. The Tweedledum-and-Tweedledee strategy is copying your opponent's move.

### Repaint

Hackenbush's negation paints every blue edge red. Up to three cards swap colour (♠↔♥, ♣↔♦): a flush fixer with a
game-theory reason.

### Fuzz

Adds * to up to two cards. *Fuzz* is a working name: "Star" is taken by the vanilla Tarot, and n* is fuzzy with n.
"Nimbus" (a nimber halo) is another option.
- For hands nothing changes: n* plays as n.
- In nim arithmetic, n* is the heap n ⊕ 1, so Fuzz is Bouton's tuning knob.
- Fuzzy cards also cancel in pairs under Sum: 5* + 5* = 10.

### Mex

The leftmost selected card becomes the mex of the other selected cards. On its own, a card becomes a 0; beside a 0 it
becomes a 1; beside a 0 and a 1 it becomes a 2. It's the easy way to make born ranks, and it feeds Grundy.

### Omega (Spectral)

A selected card becomes ω. The rule is revised and waits on a9's yes. It used to require a 2, but a Spectral pack's
hand often holds none: 8 cards contain a 2 only about 52% of the time.
- **The ω³ = 2 nod stays in the text:** ω is the smallest cube root of 2 in nim arithmetic, and no finite rank is one
  (the nim-cubes of 1–15 are only 1, 8, 10, K and A).
- **Optional bonus:** a 2 could also bring ω's siblings ω·2 and ω·3, the other two cube roots. Since infinities don't
  eat each other, that's three eaters from one card, which is probably too strong.

## 4. Jokers — Decided

- **Bouton** (rare): ×3 mult if the played cards nim-sum to 0 and include at least three distinct ranks. Your
  kickers are your Nim move.
  - Of 8-card hands, 99.4% can make some Bouton play, 75.5% can make one that contains a Pair, and 0.53% can make
    one as a flush.
  - No straight ever nim-sums to 0.
  - The 0 card is invisible to nim-sums, so it is a free kicker. That also rescues Two Pair: a, a, b, b, 0 has three
    distinct ranks.
- **Generator** (uncommon): after scoring, each scored card's rank is nim-multiplied by 15. That moves it one step
  along 15's cycle: 15 → 9 → K → Q → 3 → 10 → 7 → J → 8 → 2 → 5 → A → 6 → 4 → 1 → 15.
  - **Payout:** each card pays its place on the cycle, its discrete log: Knight 1, 9 is 2, …, 4 is 14, 1 is 15. A
    card's payout rises by one each time it scores, then wraps.
  - **Effects on the deck:** it keeps pairs, flushes and nim-zero hands (nim-multiplication distributes over
    nim-addition), scrambles straights, and turns 4s into 1s and 1s into Knights.
  - **The numbers need tuning:** as raw +mult it averages about +8 per card, which is far too much.
- **Grundy** (uncommon): gains +mult equal to each scored hand's mex, the smallest rank counting from 0 that is
  missing from the scoring cards. It does nothing until you've made a 0, and a 0-1-2-3-4 straight adds 5.
- **Hotstrat** (common): retrigger the hottest scored card twice, like Hanging Chad. It does nothing in a deck with no
  hot cards, the way suit jokers do nothing without their suit.
- **Thermograph** (rare): hot cards score their mean, with no bite, and add their temperature as +mult.
- **Sprouts** (rare): if the first hand of a round is exactly two cards, add their Cut to the deck; the parents stay.
  Conway and Paterson's Sprouts adds a new spot on every line drawn. The shape is like DNA's.
- **Cantor** (uncommon): when a Blind is selected, add a card whose rank and suit pair isn't in your deck (the
  diagonal argument). When every pair is present, it adds a born rank.
- **Cantor's Paradise** (uncommon): gains ×0.1 mult each time an ω card eats a card; Canio for the eating engine. The
  name is from Hilbert: "No one shall expel us from the paradise that Cantor has created."

## 5. Blinds and decks — Decided

- **The Heap** (Boss): a hand whose scoring cards nim-sum to 0 scores nothing. Because a ⊕ a = 0, Pairs, Two Pairs
  and Four of a Kinds never score under it.
- **Field Deck:** 64 cards, ranks 0 through Knight (the field F₁₆) in every suit.

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
- **Wythoff** (uncommon): ×2 mult if the hand contains a Wythoff pair: 1·2, 3·5, 4·7, 6·10, 8·K or 9·Kn. These are the
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

**Legendaries: the authors.**

- **Conway** (reworked): each played card can also act as {its left neighbour | its right neighbour}. This is the
  positional Cut card from the first sketch, applied to every card, and only while it's played: no values change.
  - [4, x, 6] lets x play as 5; [K, x, K] lets it play as K; [A, x, 2] lets it play as any rank.
  - Rising neighbours that are adjacent, like [Q, x, K], give 12½ and no rank. Bigger cards go on the left.
  - It turns three Kings and two junk cards into Five of a Kind ([K, x, K, y, K]), so it's probably the strongest
    card in the mod. That suits a legendary, but it needs watching.
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

- Omega's revised rule (§ 3), and whether a 2 brings ω's siblings.
- Fuzz or Nimbus.
- Conway's strength.

## 10. Facts this rests on

Checked with ogdoad's Python bindings unless marked standard.

- **Cut values:** {3|7} = 4, {3|4} = 3½, {3|} = 4, {|2} = 0, {|} = 0, {5|5} = 5*, {9|5} = 7±2 and {6|4} = 5±1.
  {6|4} is confused with exactly 4, 5 and 6, and 5* is confused with 5.
- **The hotstrat** matched the exact Left stop on 200 random sums of switches.
- **Heat and Cool:** heating leaves 5 unchanged and turns {6|4} into {7|3}. Cooling {6|4} by 1 gives stops (5, 5).
- **Nimbers:**
  - Ranks 2–A contain 22 distinct-rank triples, 55 quadruples and 72 quintuples that nim-sum to 0.
  - A random 5-card hand nim-sums to 0 6.2% of the time.
  - An 8-card hand holds a zero-sum triple 91.5% of the time.
  - No straight, including the ones through born ranks, nim-sums to 0.
  - Any 5 ranks contain a group that nim-sums to 0 (standard: linear dependence in F₂⁴).
- **Squares** (nim-multiplication) permute ranks in the Frobenius cycles above. **15 generates F₁₆'s
  multiplicative group**: its powers visit every nonzero rank once.
- **ω:**
  - ω³ = 2 in nim arithmetic, and the three cube roots of 2 are ω, ω·2 and ω·3. They nim-sum to 0 and nim-multiply
    to 2 (Vieta).
  - Ordinal addition: ω + 1 ≠ 1 + ω = ω, and ω ⊕ ω = 0.
- **Standard results:**
  - A switch {a|b} with a > b is confused with every number in [b, a].
  - ±x is its own negative.
  - Wythoff's losing positions are (⌊nφ⌋, ⌊nφ²⌋).
  - Moore's Nim_k loses exactly when every binary place sums to 0 mod k + 1.

## 11. Engine

- **Values:**
  - Dyadics are stored as numerator / 2^k, which LuaJIT's doubles represent exactly up to 2^53.
  - Surreal leaves have the form ω·k + x.
  - Short games are kept in canonical form.
- **Operations:**
  - canonical form, comparison, sum and negation;
  - stops, heat and cool;
  - the confusion test against each rank;
  - the simplest number between two values;
  - nim arithmetic on F₁₆.
- **Storage:** a card stores its value as a canonical string, so saves need nothing special.
- **Hands:** each card's set of ranks feeds a matching. Values with no rank pair by equality.
- **Faces:** procedural text on a blank front ("3½", "5*", "7±2", "ω"), with the exact {L|R} in the tooltip. This is
  the riskiest piece, so prototype it first.
- **Tests:** a script in `tools/` uses ogdoad to generate fixtures: random games with their canonical forms, stops,
  confusion sets, heating and cooling. The Lua engine must agree with all of them. ogdoad is AGPL and stays a
  development tool; nothing from it ships.
