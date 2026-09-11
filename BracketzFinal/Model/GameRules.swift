//
//  GameRules.swift
//  BracketzFinal
//

import Foundation

enum GameMove: String, CaseIterable {
    case rock
    case paper
    case scissors

    init?(userInput: String?) {
        guard let value = userInput?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased() else {
            return nil
        }

        self.init(rawValue: value)
    }
}

enum MatchOutcome: Equatable {
    case win
    case loss
    case tie
}

enum GameRules {
    static func outcome(myMove: String?, opponentMove: String?) -> MatchOutcome {
        guard let myMove = GameMove(userInput: myMove) else {
            return .loss
        }

        // A player who does not submit a valid move before time expires forfeits.
        guard let opponentMove = GameMove(userInput: opponentMove) else {
            return .win
        }

        if myMove == opponentMove {
            return .tie
        }

        switch (myMove, opponentMove) {
        case (.rock, .scissors), (.paper, .rock), (.scissors, .paper):
            return .win
        default:
            return .loss
        }
    }
}
