//
//  InvitationRulesTests.swift
//  BracketzFinalTests
//

import XCTest
@testable import BracketzFinal

final class InvitationRulesTests: XCTestCase {
    func testAcceptingInviteAddsUserOnce() {
        let users = ["creator", "invitee"]

        let firstAcceptance = InvitationRules.acceptedUserIDs(
            existing: ["creator"],
            tournamentUsers: users,
            acceptingUserID: "invitee"
        )
        let duplicateAcceptance = InvitationRules.acceptedUserIDs(
            existing: firstAcceptance,
            tournamentUsers: users,
            acceptingUserID: "invitee"
        )

        XCTAssertEqual(firstAcceptance, ["creator", "invitee"])
        XCTAssertEqual(duplicateAcceptance, firstAcceptance)
    }

    func testAcceptingLegacyInvitePreservesCreator() {
        XCTAssertEqual(
            InvitationRules.acceptedUserIDs(
                existing: nil,
                tournamentUsers: ["creator", "invitee"],
                acceptingUserID: "invitee"
            ),
            ["creator", "invitee"]
        )
    }

    func testUserOutsideTournamentCannotAcceptInvite() {
        XCTAssertNil(
            InvitationRules.acceptedUserIDs(
                existing: ["creator"],
                tournamentUsers: ["creator", "invitee"],
                acceptingUserID: "stranger"
            )
        )
    }

    func testDecliningRemovesOnlySelectedInvitation() {
        XCTAssertEqual(
            InvitationRules.removingInvite("tournament-b", from: ["tournament-a", "tournament-b", "tournament-c"]),
            ["tournament-a", "tournament-c"]
        )
    }

    func testRemovingInviteAlsoCleansLegacyDuplicates() {
        XCTAssertEqual(
            InvitationRules.removingInvite("tournament-a", from: ["tournament-a", "tournament-b", "tournament-a"]),
            ["tournament-b"]
        )
    }
}
