//
//  Service.swift
//  BracketzFinal
//
//  Created by Edward McGuiggan on 5/17/21.
//

import Foundation
import UIKit
import FirebaseDatabase

let DB_REF = Database.database().reference()
let REF_USERS = DB_REF.child("users")
let REF_TOURNAMENTS = DB_REF.child("tournaments")
let REF_MATCHES = DB_REF.child("matches")
let REF_MATCHMAKING = DB_REF.child("matchmaking")

struct MatchmakingSession {
    let tournamentID: String
    let userIDs: [String]
}

enum MatchmakingError: Error {
    case unavailable
}

struct Service {
    
    static let shared = Service()
    
    
    func fetchUserData(uid: String, completion: @escaping (User?) -> Void) {
        REF_USERS.child(uid).observeSingleEvent(of: .value) { (snapshot) in
            guard let dictionary = snapshot.value as? [String: Any] else {
                completion(nil)
                return
            }
            let uid = snapshot.key
            let user = User(uid: uid, dictionary: dictionary)
            
            completion(user)
        }
    }
    
    
    func fetchUsers(completion: @escaping([User]) -> Void) {
        REF_USERS.observeSingleEvent(of: .value) { (snapshot) in
            guard let users = snapshot.value as? [String: Any] else {
                completion([])
                return
            }

            let newUsers = users.compactMap { uid, value -> User? in
                guard let dictionary = value as? [String: Any] else { return nil }
                return User(uid: uid, dictionary: dictionary)
            }

            completion(newUsers)
        }
    }
    
    @discardableResult
    func observeInvites(uid: String, completion: @escaping ([String]) -> Void) -> DatabaseHandle {
        REF_USERS.child(uid).child("unresolvedTournaments").observe(.value) { snapshot in
            completion(snapshot.value as? [String] ?? [])
        }
    }

    func stopObservingInvites(uid: String, handle: DatabaseHandle) {
        REF_USERS.child(uid).child("unresolvedTournaments").removeObserver(withHandle: handle)
    }
    
    @discardableResult
    func observePresentUsers(tournamentID: String, completion: @escaping (Int) -> Void) -> DatabaseHandle {
        REF_TOURNAMENTS.child(tournamentID).child("acceptedUsers").observe(.value) { snapshot in
            completion(Self.intValue(snapshot.value) ?? 0)
        }
    }

    func stopObservingPresentUsers(tournamentID: String, handle: DatabaseHandle) {
        REF_TOURNAMENTS.child(tournamentID).child("acceptedUsers").removeObserver(withHandle: handle)
    }

    @discardableResult
    func observeMatches(tournamentID: String, completion: @escaping ([TournamentMatch]) -> Void) -> DatabaseHandle {
        REF_TOURNAMENTS.child(tournamentID).child("matches").observe(.value) { snapshot in
            completion(Self.tournamentMatches(from: snapshot.value))
        }
    }

    func stopObservingMatches(tournamentID: String, handle: DatabaseHandle) {
        REF_TOURNAMENTS.child(tournamentID).child("matches").removeObserver(withHandle: handle)
    }

    func configureRound(tournamentID: String, userIDs: [String], completion: @escaping (Bool) -> Void) {
        guard let expectedMatches = BracketRules.matches(for: userIDs) else {
            completion(false)
            return
        }

        REF_TOURNAMENTS.child(tournamentID).child("matches").runTransactionBlock { currentData -> TransactionResult in
            let existingMatches = Self.tournamentMatches(from: currentData.value)
            if BracketRules.matchesAreComplete(existingMatches, expectedUserIDs: userIDs) {
                return TransactionResult.success(withValue: currentData)
            }

            currentData.value = Dictionary(uniqueKeysWithValues: expectedMatches.map { match in
                (match.matchID, ["users": match.userIDs])
            })
            return TransactionResult.success(withValue: currentData)
        } andCompletionBlock: { error, committed, _ in
            completion(error == nil && committed)
        }
    }
    
    func findOrCreatePublicTournament(
        tournamentSize: Int,
        userID: String,
        completion: @escaping (Result<MatchmakingSession, MatchmakingError>) -> Void
    ) {
        REF_TOURNAMENTS.observeSingleEvent(of: .value) { snapshot in
            let candidates = Self.matchmakingCandidates(from: snapshot)
            let eligibleCandidates = MatchmakingRules.eligibleCandidates(
                from: candidates,
                tournamentSize: tournamentSize,
                userID: userID
            )

            self.claimFirstAvailable(
                eligibleCandidates.map(\.tournamentID),
                tournamentSize: tournamentSize,
                userID: userID
            ) { session in
                if let session {
                    completion(.success(session))
                } else {
                    self.reserveAndClaimPublicTournament(
                        tournamentSize: tournamentSize,
                        userID: userID,
                        completion: completion
                    )
                }
            }
        }
    }

    @discardableResult
    func observeTournamentUsers(tournamentID: String, completion: @escaping ([String]?) -> Void) -> DatabaseHandle {
        REF_TOURNAMENTS.child(tournamentID).child("tournamentUsers").observe(.value) { snapshot in
            completion(Self.stringArray(snapshot.value))
        }
    }

    func stopObservingTournamentUsers(tournamentID: String, handle: DatabaseHandle) {
        REF_TOURNAMENTS.child(tournamentID).child("tournamentUsers").removeObserver(withHandle: handle)
    }

    private func claimFirstAvailable(
        _ tournamentIDs: [String],
        tournamentSize: Int,
        userID: String,
        completion: @escaping (MatchmakingSession?) -> Void
    ) {
        guard let tournamentID = tournamentIDs.first else {
            completion(nil)
            return
        }

        claimPublicTournament(tournamentID: tournamentID, tournamentSize: tournamentSize, userID: userID) { session in
            if let session {
                completion(session)
            } else {
                self.claimFirstAvailable(
                    Array(tournamentIDs.dropFirst()),
                    tournamentSize: tournamentSize,
                    userID: userID,
                    completion: completion
                )
            }
        }
    }

    private func reserveAndClaimPublicTournament(
        tournamentSize: Int,
        userID: String,
        attemptsRemaining: Int = 2,
        completion: @escaping (Result<MatchmakingSession, MatchmakingError>) -> Void
    ) {
        guard attemptsRemaining > 0 else {
            completion(.failure(.unavailable))
            return
        }

        guard let proposedID = REF_TOURNAMENTS.childByAutoId().key else {
            completion(.failure(.unavailable))
            return
        }

        let reservation = REF_MATCHMAKING.child(String(tournamentSize))
        reservation.runTransactionBlock { currentData -> TransactionResult in
            if currentData.value == nil || currentData.value is NSNull {
                currentData.value = proposedID
            }
            return TransactionResult.success(withValue: currentData)
        } andCompletionBlock: { error, committed, snapshot in
            guard error == nil, committed, let tournamentID = snapshot?.value as? String else {
                completion(.failure(.unavailable))
                return
            }

            self.claimPublicTournament(
                tournamentID: tournamentID,
                tournamentSize: tournamentSize,
                userID: userID,
                createIfMissing: true
            ) { session in
                if let session {
                    completion(.success(session))
                    return
                }

                reservation.runTransactionBlock { currentData -> TransactionResult in
                    if currentData.value as? String == tournamentID {
                        currentData.value = nil
                    }
                    return TransactionResult.success(withValue: currentData)
                } andCompletionBlock: { _, _, _ in
                    self.reserveAndClaimPublicTournament(
                        tournamentSize: tournamentSize,
                        userID: userID,
                        attemptsRemaining: attemptsRemaining - 1,
                        completion: completion
                    )
                }
            }
        }
    }

    private func claimPublicTournament(
        tournamentID: String,
        tournamentSize: Int,
        userID: String,
        createIfMissing: Bool = false,
        completion: @escaping (MatchmakingSession?) -> Void
    ) {
        REF_TOURNAMENTS.child(tournamentID).runTransactionBlock { currentData -> TransactionResult in
            var tournament: [String: Any]
            if let existingTournament = currentData.value as? [String: Any] {
                tournament = existingTournament
            } else if createIfMissing {
                tournament = [
                    "tournamentUsers": [],
                    "acceptedUserIDs": [],
                    "acceptedUsers": 0,
                    "isPublic": true,
                    "tournySize": tournamentSize
                ]
            } else {
                return TransactionResult.abort()
            }

            guard Self.boolValue(tournament["isPublic"]),
                  Self.intValue(tournament["tournySize"]) == tournamentSize,
                  let users = Self.stringArray(tournament["tournamentUsers"]),
                  let joinedUsers = MatchmakingRules.joining(userID: userID, users: users, capacity: tournamentSize) else {
                return TransactionResult.abort()
            }

            tournament["tournamentUsers"] = joinedUsers
            tournament["acceptedUserIDs"] = joinedUsers
            tournament["acceptedUsers"] = joinedUsers.count
            tournament["isPublic"] = joinedUsers.count < tournamentSize
            currentData.value = tournament
            return TransactionResult.success(withValue: currentData)
        } andCompletionBlock: { error, committed, snapshot in
            guard error == nil,
                  committed,
                  let tournament = snapshot?.value as? [String: Any],
                  let users = Self.stringArray(tournament["tournamentUsers"]) else {
                completion(nil)
                return
            }
            completion(MatchmakingSession(tournamentID: tournamentID, userIDs: users))
        }
    }
    
    
    func acceptInvite(tournamentID: String, currentUser: User, completion: @escaping (Tournament?) -> Void) {
        let tournamentReference = REF_TOURNAMENTS.child(tournamentID)

        tournamentReference.runTransactionBlock { currentData -> TransactionResult in
            guard var tournament = currentData.value as? [String: Any],
                  let tournamentUsers = Self.stringArray(tournament["tournamentUsers"]),
                  let acceptedUserIDs = InvitationRules.acceptedUserIDs(
                    existing: Self.stringArray(tournament["acceptedUserIDs"]),
                    tournamentUsers: tournamentUsers,
                    acceptingUserID: currentUser.uid
                  ) else {
                return TransactionResult.abort()
            }

            tournament["acceptedUserIDs"] = acceptedUserIDs
            tournament["acceptedUsers"] = max(Self.intValue(tournament["acceptedUsers"]) ?? 0, acceptedUserIDs.count)
            currentData.value = tournament
            return TransactionResult.success(withValue: currentData)
        } andCompletionBlock: { error, committed, snapshot in
            guard error == nil,
                  committed,
                  let tournament = snapshot?.value as? [String: Any],
                  let users = Self.stringArray(tournament["tournamentUsers"]) else {
                completion(nil)
                return
            }

            self.removeInvite(tournamentID: tournamentID, uid: currentUser.uid) {
                completion(Tournament(tournamentID, tournamentUsers: users, false))
            }
        }
    }

    func removeInvite(tournamentID: String, uid: String, completion: (() -> Void)? = nil) {
        REF_USERS.child(uid).child("unresolvedTournaments").runTransactionBlock { currentData -> TransactionResult in
            let invites = currentData.value as? [String] ?? []
            currentData.value = InvitationRules.removingInvite(tournamentID, from: invites)
            return TransactionResult.success(withValue: currentData)
        } andCompletionBlock: { _, _, _ in
            completion?()
        }
    }
    
    
    
    func sendInvitesAndCreateTournament(tournyUsers: [String], tournySize: Int, view: UIViewController, currentUser: User) {
        let values = ["tournamentUsers": tournyUsers, "acceptedUserIDs": [currentUser.uid], "acceptedUsers": 1, "isPublic": false, "tournySize": tournySize] as [String: Any]
        REF_TOURNAMENTS.childByAutoId().updateChildValues(values) { (error, ref) in
            guard error == nil, let tournamentID = ref.key else {
                view.shouldPresentLoadingView(false)
                return
            }
            view.dismiss(animated: true, completion: nil)
            
            for x in tournyUsers {
                REF_USERS.child(x).child("unresolvedTournaments").observeSingleEvent(of: .value) { (snapshot) in
                    if var array = snapshot.value as? [String] {
                        if !array.contains(tournamentID) {
                            array.append(tournamentID)
                        }
                        REF_USERS.child(x).updateChildValues(["unresolvedTournaments": array])
                    } else {
                        REF_USERS.child(x).updateChildValues(["unresolvedTournaments": [tournamentID]])
                    }
                }
            }
            
                let newTourny = Tournament(tournamentID, tournamentUsers: tournyUsers, false)
                let controller = LobbyVC(currentUser: currentUser, tournySize: tournySize, tourny: newTourny)
            
                view.navigationController?.pushViewController(controller, animated: true)
            }
    }

    private static func intValue(_ value: Any?) -> Int? {
        if let value = value as? Int { return value }
        return (value as? NSNumber)?.intValue
    }

    private static func boolValue(_ value: Any?) -> Bool {
        if let value = value as? Bool { return value }
        return (value as? NSNumber)?.boolValue ?? false
    }

    private static func stringArray(_ value: Any?) -> [String]? {
        if let value = value as? [String] { return value }
        if let value = value as? [Any] { return value.compactMap { $0 as? String } }
        return nil
    }

    private static func matchmakingCandidates(from snapshot: DataSnapshot) -> [MatchmakingCandidate] {
        guard let tournaments = snapshot.value as? [String: Any] else { return [] }

        return tournaments.compactMap { tournamentID, value in
            guard let tournament = value as? [String: Any],
                  let tournamentSize = intValue(tournament["tournySize"]),
                  let users = stringArray(tournament["tournamentUsers"]) else {
                return nil
            }

            return MatchmakingCandidate(
                tournamentID: tournamentID,
                tournamentSize: tournamentSize,
                isPublic: boolValue(tournament["isPublic"]),
                userIDs: users
            )
        }
    }

    private static func tournamentMatches(from value: Any?) -> [TournamentMatch] {
        guard let matches = value as? [String: Any] else { return [] }

        return matches.compactMap { matchID, value in
            guard let match = value as? [String: Any],
                  let users = stringArray(match["users"]),
                  users.count == 2 else {
                return nil
            }
            return TournamentMatch(matchID: matchID, userIDs: users)
        }
    }
}
