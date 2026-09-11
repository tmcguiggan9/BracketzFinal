//
//  MatchLifecycleRulesTests.swift
//  BracketzFinalTests
//

import XCTest
@testable import BracketzFinal

final class MatchLifecycleRulesTests: XCTestCase {
    private let users = ["player-one", "player-two"]

    func testValidMovesResolveOneWinner() {
        XCTAssertEqual(
            MatchLifecycleRules.resolve(userIDs: users, user1Move: "rock", user2Move: "scissors"),
            MatchResolution(status: .resolved, winnerID: "player-one", loserID: "player-two")
        )
        XCTAssertEqual(
            MatchLifecycleRules.resolve(userIDs: users, user1Move: "paper", user2Move: "scissors"),
            MatchResolution(status: .resolved, winnerID: "player-two", loserID: "player-one")
        )
    }

    func testEqualMovesProduceTie() {
        XCTAssertEqual(
            MatchLifecycleRules.resolve(userIDs: users, user1Move: "rock", user2Move: "rock"),
            MatchResolution(status: .tie, winnerID: nil, loserID: nil)
        )
    }

    func testMissingMoveIsForfeit() {
        XCTAssertEqual(
            MatchLifecycleRules.resolve(userIDs: users, user1Move: "paper", user2Move: nil),
            MatchResolution(status: .resolved, winnerID: "player-one", loserID: "player-two")
        )
        XCTAssertEqual(
            MatchLifecycleRules.resolve(userIDs: users, user1Move: nil, user2Move: "paper"),
            MatchResolution(status: .resolved, winnerID: "player-two", loserID: "player-one")
        )
    }

    func testBothMissingMovesRestartAsTie() {
        XCTAssertEqual(
            MatchLifecycleRules.resolve(userIDs: users, user1Move: nil, user2Move: nil),
            MatchResolution(status: .tie, winnerID: nil, loserID: nil)
        )
    }

    func testInvalidUserListCannotResolve() {
        XCTAssertNil(MatchLifecycleRules.resolve(userIDs: ["only-player"], user1Move: "rock", user2Move: "paper"))
    }
}
