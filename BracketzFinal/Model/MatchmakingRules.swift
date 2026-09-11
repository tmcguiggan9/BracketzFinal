//
//  MatchmakingRules.swift
//  BracketzFinal
//

import Foundation

struct MatchmakingCandidate: Equatable {
    let tournamentID: String
    let tournamentSize: Int
    let isPublic: Bool
    let userIDs: [String]
}

enum MatchmakingRules {
    static func eligibleCandidates(
        from candidates: [MatchmakingCandidate],
        tournamentSize: Int,
        userID: String
    ) -> [MatchmakingCandidate] {
        candidates
            .filter {
                $0.isPublic &&
                $0.tournamentSize == tournamentSize &&
                ($0.userIDs.contains(userID) || $0.userIDs.count < tournamentSize)
            }
            .sorted {
                let firstContainsUser = $0.userIDs.contains(userID)
                let secondContainsUser = $1.userIDs.contains(userID)
                if firstContainsUser != secondContainsUser {
                    return firstContainsUser
                }
                return $0.tournamentID < $1.tournamentID
            }
    }

    static func joining(userID: String, users: [String], capacity: Int) -> [String]? {
        guard capacity > 0 else { return nil }
        if users.contains(userID) { return users }
        guard users.count < capacity else { return nil }
        return users + [userID]
    }
}
