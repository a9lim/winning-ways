-- Written in vanilla's voice: short lines, no full stops, numbers and key words in {C:attention}, verbs as the
-- Tarots and Spectrals use them, and the terms of art (hot, mex, nim-sum, ω) explained in their own info boxes.
local pack_text = {
  "Choose {C:attention}#1#{} of up to",
  "{C:attention}#2#{C:ww_move} Move{} cards to",
  "be used immediately",
}

return {
  descriptions = {
    Back = {
      b_ww_lab = {
        name = "Laboratory Deck",
        text = {
          "Start run with one",
          "card of every {C:attention}modifier{},",
          "a {C:attention}0{}, a {C:attention}1{} and",
          "{C:attention}2{} Cavaliers",
        },
      },
      b_ww_field = {
        name = "Field Deck",
        text = {
          "Start run with a",
          "{C:attention}0{}, {C:attention}1{} and {C:attention}Cavalier{}",
          "of each suit",
        },
      },
      b_ww_ordinal = {
        name = "Ordinal Deck",
        text = {
          "Start run with an",
          "extra {C:attention}0{} worth {C:attention}ω{}",
          "and a {C:ww_move,T:c_ww_cut}Cut{} card",
        },
      },
    },
    Blind = {
      bl_ww_heap = {
        name = "The Heap",
        text = { "No hands that", "nim-sum to 0" },
      },
      bl_ww_misere = {
        name = "The Misère",
        text = { "Final hand of", "round scores nothing" },
      },
    },
    Joker = {
      j_ww_bouton = {
        name = "Bouton",
        text = {
          "{X:mult,C:white} X#1# {} Mult if played",
          "cards of {C:attention}3{} or more ranks",
          "{C:attention}nim-sum{} to {C:attention}0",
        },
      },
      j_ww_generator = {
        name = "Generator",
        text = {
          "Played cards give {C:chips}+#1#{}",
          "Chips per place on the",
          "{C:attention}Ace's cycle{} when scored,",
          "then move one place",
        },
      },
      j_ww_grundy = {
        name = "Grundy",
        text = {
          "This Joker gains Mult",
          "equal to the {C:attention}mex{} of",
          "the scoring cards",
          "{C:inactive}(Currently {C:mult}+#1#{C:inactive} Mult)",
        },
      },
      j_ww_hotstrat = {
        name = "Hotstrat",
        text = { "Retrigger all", "played {C:mult}hot{} cards" },
      },
      j_ww_thermograph = {
        name = "Thermograph",
        text = {
          "{C:mult}Hot{} cards score their",
          "{C:attention}mean{} and give {C:mult}+#1#{} Mult",
          "per degree of {C:attention}temperature",
        },
      },
      j_ww_sprouts = {
        name = "Sprouts",
        text = {
          "If {C:attention}first hand{} of round",
          "has exactly {C:attention}2{} cards, add",
          "their {C:ww_move}Cut{} to deck and",
          "draw it to {C:attention}hand",
        },
      },
      j_ww_cantor = {
        name = "Cantor",
        text = {
          "Adds a card {C:attention}missing{}",
          "from your deck when",
          "{C:attention}Blind{} is selected",
          "{C:inactive}(by rank and suit)",
        },
      },
      j_ww_paradise = {
        name = "Cantor's Paradise",
        text = {
          "This Joker gains {X:mult,C:white} X#1# {} Mult",
          "for every card {C:attention}ω{} eats",
          "{C:inactive}(Currently {X:mult,C:white} X#2# {C:inactive} Mult)",
        },
      },
      j_ww_birthday = {
        name = "Birthday",
        text = {
          "Played cards give {C:mult}+#1#{} Mult",
          "per day younger than",
          "their {C:attention}whole number{}",
          "when scored",
          "{C:inactive}(ex: {C:attention}3½{C:inactive} is 2 days younger)",
        },
      },
      j_ww_hilbert = {
        name = "Hilbert's Hotel",
        text = { "{C:dark_edition}+#1#{} Joker slots", "{C:red}-#2#{} hand size" },
      },
      j_ww_berlekamp = {
        name = "Berlekamp",
        text = { "Played {C:mult}hot{} cards", "each give {X:mult,C:white} X#1# {} Mult", "when scored" },
      },
      j_ww_guy = {
        name = "Guy",
        text = {
          "Played cards of rank",
          "{C:attention}#2#{} or lower each give",
          "{X:mult,C:white} X#1# {} Mult when scored",
          "{C:inactive}(5, 4, 3, 2, 1, 0)",
        },
      },
      j_ww_conway = {
        name = "Conway",
        text = {
          "Each played card can",
          "also play as the {C:ww_move}Cut{}",
          "of its neighbours",
        },
      },
    },
    Move = {
      c_ww_cut = {
        name = "Cut",
        text = {
          "Fuses {C:attention}#1#{} selected cards",
          "into the simplest card",
          "{C:attention}between{} them",
          "{C:inactive}(Left higher makes it {C:mult}hot{C:inactive})",
          "{s:0.8}1 card rounds up, none makes a 0",
        },
      },
      c_ww_sum = {
        name = "Sum",
        text = { "Fuses {C:attention}#1#{} selected", "cards into their {C:attention}sum" },
      },
      c_ww_heat = {
        name = "Heat",
        text = { "Increases temperature", "of up to {C:attention}#1#{} selected", "{C:mult}hot{} cards by {C:attention}1" },
      },
      c_ww_cool = {
        name = "Cool",
        text = { "Decreases temperature", "of up to {C:attention}#1#{} selected", "{C:mult}hot{} cards by {C:attention}1" },
      },
      c_ww_frobenius = {
        name = "Frobenius",
        text = {
          "Nim-squares the",
          "rank of up to {C:attention}#1#{}",
          "selected cards",
          "{C:inactive}(ex: {C:attention}2{C:inactive} -> {C:attention}3{C:inactive}, {C:attention}4{C:inactive} -> {C:attention}6{C:inactive})",
        },
      },
      c_ww_tweedledum = {
        name = "Tweedledum",
        text = {
          "Creates the last",
          "{C:ww_move}Move{} card used",
          "during this run",
          "{s:0.8,C:ww_move}Tweedledum{s:0.8} excluded",
        },
      },
      c_ww_repaint = {
        name = "Repaint",
        text = {
          "Swaps {C:spades}Spades{} with {C:hearts}Hearts{}",
          "and {C:clubs}Clubs{} with {C:diamonds}Diamonds{}",
          "in up to {C:attention}#1#{} selected cards",
        },
      },
      c_ww_nimbus = {
        name = "Nimbus",
        text = { "Adds {C:attention}*{} to up to", "{C:attention}#1#{} selected cards", "{C:inactive}(5* plays as 5)" },
      },
      c_ww_mex = {
        name = "Mex",
        text = {
          "Select up to {C:attention}#1#{} cards,",
          "convert the {C:attention}left{} card",
          "into the {C:attention}mex{} of the rest",
          "{C:inactive}(Drag to rearrange)",
        },
      },
    },
    Spectral = {
      c_ww_omega = {
        name = "Omega",
        text = { "Add {C:attention}ω{} to {C:attention}1{}", "selected card", "in your hand" },
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
      p_ww_game_normal_1 = { name = "Game Pack", text = pack_text },
      p_ww_game_normal_2 = { name = "Game Pack", text = pack_text },
      p_ww_game_jumbo_1 = { name = "Jumbo Game Pack", text = pack_text },
      p_ww_game_mega_1 = { name = "Mega Game Pack", text = pack_text },
      ww_ace_cycle = {
        name = "Ace's Cycle",
        text = {
          "A 9 Q C 3 10 7 J",
          "8 2 5 K 6 4 1",
          "{C:inactive}(Ace is 1st, 1 is 15th,",
          "{C:inactive}then back to the Ace)",
        },
      },
      ww_hot = {
        name = "Hot",
        text = {
          "Like {C:attention}7±2{}: plays as",
          "any rank from {C:attention}5{} to {C:attention}9",
          "{C:inactive}(mean 7, temperature 2)",
        },
      },
      ww_mex = {
        name = "Mex",
        text = {
          "The smallest rank",
          "missing, from {C:attention}0{} up",
          "{C:inactive}(ex: {C:attention}0 1 3{C:inactive} -> {C:attention}2{C:inactive})",
        },
      },
      ww_nim_sum = {
        name = "Nim-sum",
        text = {
          "Add ranks in binary",
          "without carrying",
          "{C:inactive}(ex: {C:attention}3 5 6{C:inactive} -> {C:attention}0{C:inactive})",
        },
      },
      ww_omega = {
        name = "ω",
        text = {
          "Eats the cards played",
          "to its left and gains",
          "{C:attention}double{} their {C:chips}Chips",
          "{C:inactive}(Eaten cards are destroyed)",
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
