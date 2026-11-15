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
          "it eats the cards played",
          "to its left",
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
      k_move = "Move",
      b_move_cards = "Moves",
    },
  },
}
