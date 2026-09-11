//
//  BracketRules.swift
//  BracketzFinal
//

import Foundation

enum BracketRules {
    static func matches(for userIDs: [String]) -> [TournamentMatch]? {
        guard userIDs.count >= 2, userIDs.count.isMultiple(of: 2), Set(userIDs).count == userIDs.count else {
            return nil
        }

        return stride(from: 0, to: userIDs.count, by: 2).map { index in
            TournamentMatch(
                matchID: "match-\(index / 2)",
                userIDs: [userIDs[index], userIDs[index + 1]]
            )
        }
    }

    static func match(for userID: String, in matches: [TournamentMatch]) -> TournamentMatch? {
        matches.first { $0.userIDs.contains(userID) }
    }

    static func matchesAreComplete(_ matches: [TournamentMatch], expectedUserIDs: [String]) -> Bool {
        guard let expectedMatches = self.matches(for: expectedUserIDs) else { return false }
        return matches.sorted(by: { $0.matchID < $1.matchID }) == expectedMatches
    }
}
