//
//  Match.swift
//  BracketzFinal
//
//  Created by Edward McGuiggan on 5/13/21.
//

import Foundation

struct TournamentMatch: Equatable {
    let matchID: String
    let userIDs: [String]
}

enum LiveMatchStatus: String, Equatable {
    case waiting
    case tie
    case resolved
}

struct LiveMatchState: Equatable {
    let matchID: String
    let userIDs: [String]
    let round: Int
    let status: LiveMatchStatus
    let user1Move: String?
    let user2Move: String?
    let winnerID: String?
    let loserID: String?
}

struct MatchResolution: Equatable {
    let status: LiveMatchStatus
    let winnerID: String?
    let loserID: String?
}

enum MatchLifecycleRules {
    static func resolve(userIDs: [String], user1Move: String?, user2Move: String?) -> MatchResolution? {
        guard userIDs.count == 2 else { return nil }
        let firstMove = GameMove(userInput: user1Move)
        let secondMove = GameMove(userInput: user2Move)

        switch (firstMove, secondMove) {
        case (nil, nil):
            return MatchResolution(status: .tie, winnerID: nil, loserID: nil)
        case (_?, nil):
            return MatchResolution(status: .resolved, winnerID: userIDs[0], loserID: userIDs[1])
        case (nil, _?):
            return MatchResolution(status: .resolved, winnerID: userIDs[1], loserID: userIDs[0])
        case (_?, _?):
            switch GameRules.outcome(myMove: user1Move, opponentMove: user2Move) {
            case .win:
                return MatchResolution(status: .resolved, winnerID: userIDs[0], loserID: userIDs[1])
            case .loss:
                return MatchResolution(status: .resolved, winnerID: userIDs[1], loserID: userIDs[0])
            case .tie:
                return MatchResolution(status: .tie, winnerID: nil, loserID: nil)
            }
        }
    }
}
