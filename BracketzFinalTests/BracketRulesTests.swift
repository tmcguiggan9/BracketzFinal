//
//  BracketRulesTests.swift
//  BracketzFinalTests
//

import XCTest
@testable import BracketzFinal

final class BracketRulesTests: XCTestCase {
    func testPlayersArePairedInStableOrder() {
        XCTAssertEqual(
            BracketRules.matches(for: ["one", "two", "three", "four"]),
            [
                TournamentMatch(matchID: "match-0", userIDs: ["one", "two"]),
                TournamentMatch(matchID: "match-1", userIDs: ["three", "four"])
            ]
        )
    }

    func testPairingRejectsInvalidPlayerLists() {
        XCTAssertNil(BracketRules.matches(for: []))
        XCTAssertNil(BracketRules.matches(for: ["one", "two", "three"]))
        XCTAssertNil(BracketRules.matches(for: ["one", "one"]))
    }

    func testPlayerFindsMatchByMembershipNotDatabaseOrder() {
        let matches = [
            TournamentMatch(matchID: "match-1", userIDs: ["three", "four"]),
            TournamentMatch(matchID: "match-0", userIDs: ["one", "two"])
        ]

        XCTAssertEqual(BracketRules.match(for: "two", in: matches)?.matchID, "match-0")
        XCTAssertNil(BracketRules.match(for: "missing", in: matches))
    }

    func testCompletenessRequiresEveryExpectedPair() {
        let matches = BracketRules.matches(for: ["one", "two", "three", "four"]) ?? []
        XCTAssertTrue(BracketRules.matchesAreComplete(Array(matches.reversed()), expectedUserIDs: ["one", "two", "three", "four"]))
        XCTAssertFalse(BracketRules.matchesAreComplete(Array(matches.dropLast()), expectedUserIDs: ["one", "two", "three", "four"]))
    }
}
