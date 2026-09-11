//
//  MatchmakingRulesTests.swift
//  BracketzFinalTests
//

import XCTest
@testable import BracketzFinal

final class MatchmakingRulesTests: XCTestCase {
    func testJoiningAddsPlayerOnce() {
        XCTAssertEqual(MatchmakingRules.joining(userID: "player-2", users: ["player-1"], capacity: 2), ["player-1", "player-2"])
        XCTAssertEqual(MatchmakingRules.joining(userID: "player-1", users: ["player-1"], capacity: 2), ["player-1"])
    }

    func testJoiningRejectsFullTournament() {
        XCTAssertNil(MatchmakingRules.joining(userID: "player-3", users: ["player-1", "player-2"], capacity: 2))
    }

    func testCandidatesMustBePublicOpenAndCorrectSize() {
        let candidates = [
            MatchmakingCandidate(tournamentID: "open", tournamentSize: 4, isPublic: true, userIDs: ["one"]),
            MatchmakingCandidate(tournamentID: "private", tournamentSize: 4, isPublic: false, userIDs: ["one"]),
            MatchmakingCandidate(tournamentID: "full", tournamentSize: 4, isPublic: true, userIDs: ["one", "two", "three", "four"]),
            MatchmakingCandidate(tournamentID: "wrong-size", tournamentSize: 8, isPublic: true, userIDs: ["one"])
        ]

        XCTAssertEqual(
            MatchmakingRules.eligibleCandidates(from: candidates, tournamentSize: 4, userID: "new-player").map(\.tournamentID),
            ["open"]
        )
    }

    func testExistingTournamentIsPreferredForReconnection() {
        let candidates = [
            MatchmakingCandidate(tournamentID: "a-new", tournamentSize: 4, isPublic: true, userIDs: ["someone-else"]),
            MatchmakingCandidate(tournamentID: "z-existing", tournamentSize: 4, isPublic: true, userIDs: ["current-user"])
        ]

        XCTAssertEqual(
            MatchmakingRules.eligibleCandidates(from: candidates, tournamentSize: 4, userID: "current-user").map(\.tournamentID),
            ["z-existing", "a-new"]
        )
    }
}
