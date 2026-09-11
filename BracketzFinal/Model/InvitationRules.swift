//
//  InvitationRules.swift
//  BracketzFinal
//

import Foundation

enum InvitationRules {
    static func acceptedUserIDs(
        existing: [String]?,
        tournamentUsers: [String],
        acceptingUserID: String
    ) -> [String]? {
        guard tournamentUsers.contains(acceptingUserID) else {
            return nil
        }

        // Older tournaments did not store accepted user IDs. Their creator is
        // always the first tournament user, so use that as the migration base.
        let initialIDs = existing ?? tournamentUsers.first.map { [$0] } ?? []
        var acceptedIDs = initialIDs.filter(tournamentUsers.contains)

        acceptedIDs = acceptedIDs.reduce(into: []) { uniqueIDs, userID in
            if !uniqueIDs.contains(userID) {
                uniqueIDs.append(userID)
            }
        }

        if !acceptedIDs.contains(acceptingUserID) {
            acceptedIDs.append(acceptingUserID)
        }

        return acceptedIDs
    }

    static func removingInvite(_ tournamentID: String, from invites: [String]) -> [String] {
        invites.filter { $0 != tournamentID }
    }
}
