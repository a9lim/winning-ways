return {
  descriptions = {
    Back = {
      b_ww_lab = {
        name = "Laboratory Deck",
        text = {
          "{C:attention}Development deck{}: a standard",
          "deck with a sample of every",
          "kind of modifier, plus {C:attention}0{}, {C:attention}1{}",
          "and two {C:attention}Cavaliers{}",
        },
      },
      b_ww_field = {
        name = "Field Deck",
        text = {
          "Start with {C:attention}64{} cards: every",
          "rank from {C:attention}0{} to {C:attention}Ace{}, the",
          "{C:attention}Cavalier{} included, in all",
          "four suits",
        },
      },
      b_ww_ordinal = {
        name = "Ordinal Deck",
        text = {
          "Start with an {C:attention}ω{} card,",
          "a {C:attention}0{} worth exactly {C:attention}ω{},",
          "and a {C:attention}Cut{}",
        },
      },
    },
    Blind = {
      bl_ww_heap = {
        name = "The Heap",
        text = { "Hands that nim-sum", "to 0 score nothing" },
      },
      bl_ww_misere = {
        name = "The Misère",
        text = { "The last mover loses:", "your final hand scores nothing" },
      },
    },
    Joker = {
      j_ww_bouton = {
        name = "Bouton",
        text = {
          "{X:mult,C:white} X#1# {} Mult if the played",
          "cards {C:attention}nim-sum{} to {C:attention}0{} with at",
          "least {C:attention}3{} different ranks",
        },
      },
      j_ww_generator = {
        name = "Generator",
        text = {
          "Each scored card gives {C:chips}+#1#{} Chips",
          "per place it holds on the",
          "{C:attention}Ace's cycle{}, then moves",
          "one place along it",
        },
      },
      j_ww_grundy = {
        name = "Grundy",
        text = {
          "Gains {C:mult}Mult{} equal to the",
          "smallest rank, from {C:attention}0{} up,",
          "missing from the scoring cards",
          "{C:inactive}(Currently {C:mult}+#1#{C:inactive} Mult)",
        },
      },
      j_ww_hotstrat = {
        name = "Hotstrat",
        text = { "Retrigger each", "played {C:mult}hot{} card" },
      },
      j_ww_thermograph = {
        name = "Thermograph",
        text = {
          "{C:mult}Hot{} cards score their {C:attention}mean{}",
          "and give {C:mult}+#1#{} Mult per",
          "degree of {C:attention}temperature{}",
        },
      },
      j_ww_sprouts = {
        name = "Sprouts",
        text = {
          "If {C:attention}first hand{} of round",
          "has exactly {C:attention}2{} cards, add",
          "their {C:attention}Cut{} to deck and",
          "draw it to {C:attention}hand",
        },
      },
      j_ww_cantor = {
        name = "Cantor",
        text = {
          "When {C:attention}Blind{} is selected,",
          "add a card whose rank and",
          "suit no card in your",
          "deck has",
        },
      },
      j_ww_paradise = {
        name = "Cantor's Paradise",
        text = {
          "Gains {X:mult,C:white} X#1# {} Mult for",
          "each card {C:attention}ω{} eats",
          "{C:inactive}(Currently {X:mult,C:white} X#2# {C:inactive} Mult)",
        },
      },
      j_ww_birthday = {
        name = "Birthday",
        text = {
          "Each scored card gives {C:mult}+#1#{} Mult",
          "per day its value was born",
          "after its whole number",
          "{C:inactive}(3 on day 3, 3½ on day 5, 3¼ on day 6)",
        },
      },
      j_ww_hilbert = {
        name = "Hilbert's Hotel",
        text = {
          "Takes no Joker slot",
          "and gives {C:dark_edition}+#1#{} more",
          "{C:red}-#2#{} hand size",
        },
      },
      j_ww_berlekamp = {
        name = "Berlekamp",
        text = { "Each played {C:mult}hot{} card", "gives {X:mult,C:white} X#1# {} Mult", "when scored" },
      },
      j_ww_guy = {
        name = "Guy",
        text = {
          "Each played card of rank",
          "{C:attention}#2#{} or lower, {C:attention}0{} and {C:attention}1{} too,",
          "gives {X:mult,C:white} X#1# {} Mult when scored",
        },
      },
      j_ww_conway = {
        name = "Conway",
        text = {
          "Each played card can",
          "also play as the {C:attention}Cut{}",
          "of its left and right",
          "neighbours",
        },
      },
    },
    Move = {
      c_ww_cut = {
        name = "Cut",
        text = {
          "Fuses {C:attention}2{} selected cards into",
          "the {C:attention}simplest card between{}",
          "them, or a {C:mult}hot{} card if the",
          "left one is higher.",
          "{C:attention}1{} card rounds up; none",
          "makes a {C:attention}0{}",
        },
      },
      c_ww_sum = {
        name = "Sum",
        text = { "{C:attention}2{} selected cards", "become their {C:attention}sum{}" },
      },
      c_ww_heat = {
        name = "Heat",
        text = {
          "Raises the temperature of",
          "up to {C:attention}#1#{} selected {C:mult}hot{} cards:",
          "a wider range, a bigger bite",
        },
      },
      c_ww_cool = {
        name = "Cool",
        text = {
          "Lowers the temperature of",
          "up to {C:attention}#1#{} selected {C:mult}hot{} cards,",
          "toward a plain rank",
        },
      },
      c_ww_frobenius = {
        name = "Frobenius",
        text = {
          "Squares the rank of up to",
          "{C:attention}#1#{} selected cards in",
          "{C:attention}nim{} arithmetic",
        },
      },
      c_ww_tweedledum = {
        name = "Tweedledum",
        text = {
          "Creates the last",
          "{C:attention}Move{} used",
          "{C:inactive}(Tweedledum excluded){}",
          "{s:0.8}Last: {C:attention,s:0.8}#1#{}",
        },
      },
      c_ww_repaint = {
        name = "Repaint",
        text = {
          "Swaps the colour of up to",
          "{C:attention}#1#{} selected cards:",
          "{C:spades}Spades{} and {C:hearts}Hearts{},",
          "{C:clubs}Clubs{} and {C:diamonds}Diamonds{}",
        },
      },
      c_ww_nimbus = {
        name = "Nimbus",
        text = {
          "Adds a {C:attention}*{} halo to up to",
          "{C:attention}#1#{} selected cards: a nimber,",
          "which plays as the same rank",
        },
      },
      c_ww_mex = {
        name = "Mex",
        text = {
          "The {C:attention}leftmost{} selected card",
          "becomes the smallest rank",
          "missing from the others",
          "{C:inactive}(up to #1# cards){}",
        },
      },
    },
    Spectral = {
      c_ww_omega = {
        name = "Omega",
        text = {
          "Adds {C:attention}ω{} to {C:attention}1{} selected card:",
          "it eats the cards played to",
          "its left, gaining {C:attention}double{}",
          "their chips for good",
        },
      },
    },
    Other = {
      undiscovered_move = {
        name = "Not Discovered",
        text = {
          "Purchase or use",
          "this card in an",
          "unseeded run to",
          "learn what it does",
        },
      },
      p_ww_game_normal_1 = {
        name = "Game Pack",
        text = { "Choose {C:attention}#1#{} of up to", "{C:attention}#2#{} {C:attention}Move{} cards to", "be used immediately" },
      },
      p_ww_game_normal_2 = {
        name = "Game Pack",
        text = { "Choose {C:attention}#1#{} of up to", "{C:attention}#2#{} {C:attention}Move{} cards to", "be used immediately" },
      },
      p_ww_game_jumbo_1 = {
        name = "Jumbo Game Pack",
        text = { "Choose {C:attention}#1#{} of up to", "{C:attention}#2#{} {C:attention}Move{} cards to", "be used immediately" },
      },
      p_ww_game_mega_1 = {
        name = "Mega Game Pack",
        text = { "Choose {C:attention}#1#{} of up to", "{C:attention}#2#{} {C:attention}Move{} cards to", "be used immediately" },
      },
      ww_ace_cycle = {
        name = "The Ace's cycle",
        text = {
          "Nim-multiplying by {C:attention}15{} moves",
          "a rank one place along:",
          "{C:attention}A{} 9 Q C 3 10 7 J 8 2 5 K 6 4 {C:attention}1",
          "{C:inactive}(the Ace is 1st, the 1 is 15th;",
          "{C:inactive}then back to the Ace. 0 stays)",
        },
      },
      ww_hot = {
        name = "Hot",
        text = {
          "A card is {C:mult}hot{} when its",
          "value is a hot game, like",
          "{C:attention}7±2{}: it plays as {C:attention}5{} to {C:attention}9{}",
        },
      },
      ww_modifier = {
        name = "Modifier",
        text = {
          "{C:attention}#1#{}",
          "Worth {C:chips}#2#{}",
          "Plays as {C:attention}#3#{}",
        },
      },
    },
  },
  misc = {
    ranks = {
      ww_0 = "0",
      ww_1 = "1",
      ww_C = "Cavalier",
    },
    dictionary = {
      k_ww_no_rank = "no rank",
      k_ww_wild_rank = "Wild rank",
      k_ww_game_pack = "Game Pack",
      k_ww_generated = "Generated!",
      k_ww_sprouted = "Sprouted!",
      k_ww_diagonal = "Diagonal!",
      k_move = "Move",
      b_move_cards = "Moves",
    },
  },
}
