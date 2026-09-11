//
//  GameRulesTests.swift
//  BracketzFinalTests
//

import XCTest
@testable import BracketzFinal

final class GameRulesTests: XCTestCase {
    func testEveryValidMoveCombination() {
        let cases: [(mine: String, theirs: String, expected: MatchOutcome)] = [
            ("rock", "rock", .tie),
            ("rock", "paper", .loss),
            ("rock", "scissors", .win),
            ("paper", "rock", .win),
            ("paper", "paper", .tie),
            ("paper", "scissors", .loss),
            ("scissors", "rock", .loss),
            ("scissors", "paper", .win),
            ("scissors", "scissors", .tie)
        ]

        for testCase in cases {
            XCTAssertEqual(
                GameRules.outcome(myMove: testCase.mine, opponentMove: testCase.theirs),
                testCase.expected,
                "Expected \(testCase.mine) against \(testCase.theirs) to be \(testCase.expected)"
            )
        }
    }

    func testOpponentForfeitsWhenMoveIsMissingOrInvalid() {
        XCTAssertEqual(GameRules.outcome(myMove: "rock", opponentMove: nil), .win)
        XCTAssertEqual(GameRules.outcome(myMove: "paper", opponentMove: ""), .win)
        XCTAssertEqual(GameRules.outcome(myMove: "scissors", opponentMove: "lizard"), .win)
    }

    func testPlayerForfeitsWhenMoveIsMissingOrInvalid() {
        XCTAssertEqual(GameRules.outcome(myMove: nil, opponentMove: "rock"), .loss)
        XCTAssertEqual(GameRules.outcome(myMove: "", opponentMove: "paper"), .loss)
        XCTAssertEqual(GameRules.outcome(myMove: "spock", opponentMove: "scissors"), .loss)
        XCTAssertEqual(GameRules.outcome(myMove: nil, opponentMove: nil), .loss)
    }

    func testMoveInputIsNormalized() {
        XCTAssertEqual(GameRules.outcome(myMove: " ROCK ", opponentMove: "Scissors\n"), .win)
    }
}
