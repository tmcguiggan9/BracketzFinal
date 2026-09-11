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

struct Service {
    
    static let shared = Service()
    
    
    func fetchUserData(uid: String, completion: @escaping(User) -> Void) {
        REF_USERS.child(uid).observeSingleEvent(of: .value) { (snapshot) in
            guard let dictionary = snapshot.value as? [String: Any] else { return }
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
    
    func observePresentUsers(uid: String, completion: @escaping(Int) -> Void) {
        REF_TOURNAMENTS.child(uid).child("acceptedUsers").observe(.value) { (snapshot) in
            guard let presentUsers = snapshot.value as? Int else { return }
            completion(presentUsers)
        }
    }
    
    func observeMatches(uid: String, completion: @escaping([String]) -> Void) {
        
        REF_TOURNAMENTS.child(uid).child("matches").observe(.value) { (snapshot) in
            
            guard let matches = snapshot.value as? [String: Any] else { return }
            var finalMatches = [String]()
            for x in matches {
                finalMatches.append(x.key)
            }
            completion(finalMatches)
        }
    }
    
    func removeObserver(uid: String) {
    
        REF_TOURNAMENTS.child(uid).child("acceptedUsers").removeAllObservers()
    }
    
    func findPublicTournament(tournySize: Int, currentUser: User, view: UIViewController) {
        var tournyUsers = [String]()
        REF_TOURNAMENTS.observeSingleEvent(of: .value) { (snapshot) in
            if let tournys = snapshot.value as? [String: Any] {
                for x in tournys {
                    guard let dictionary = x.value as? [String: Any],
                          Self.boolValue(dictionary["isPublic"]),
                          Self.intValue(dictionary["tournySize"]) == tournySize else {
                        continue
                    }
                        
                        REF_TOURNAMENTS.child(x.key).runTransactionBlock { (currentData: MutableData) -> TransactionResult in
                            guard var tourny = currentData.value as? [String: Any],
                                  let acceptedUsers = Self.intValue(tourny["acceptedUsers"]),
                                  var users = tourny["tournamentUsers"] as? [String],
                                  users.count < tournySize else {
                                return TransactionResult.abort()
                            }

                            if !users.contains(currentUser.uid) {
                                users.append(currentUser.uid)
                                let acceptedUserIDs = Self.stringArray(tourny["acceptedUserIDs"]) ?? []
                                tourny["acceptedUserIDs"] = acceptedUserIDs + [currentUser.uid]
                                tourny["acceptedUsers"] = acceptedUsers + 1
                                tourny["tournamentUsers"] = users
                                currentData.value = tourny
                            }
                            
                            REF_TOURNAMENTS.child(x.key).child("tournamentUsers").observe(.value) { (snapshot) in
                                guard let users = snapshot.value as? [String] else { return }
                                
                                if users.count == tournySize {
                                    view.shouldPresentLoadingView(false)
                                    DispatchQueue.main.async {
                                        let newTourny = Tournament(x.key, tournamentUsers: users, true)
                                        let controller = LobbyVC(currentUser: currentUser, tournySize: tournySize, tourny: newTourny)
                                        view.navigationController?.popToRootViewController(animated: true)
                                        view.navigationController?.pushViewController(controller, animated: true)
                                    }
                                }
                                view.shouldPresentLoadingView(true, message: "Waiting for other users to join...")
                            }
                            return TransactionResult.success(withValue: currentData)
                        }
                        return
                }
            }
            let values = ["tournamentUsers": [currentUser.uid], "acceptedUserIDs": [currentUser.uid], "acceptedUsers": 1, "isPublic": true, "tournySize": tournySize] as [String: Any]
            REF_TOURNAMENTS.childByAutoId().updateChildValues(values) { (error, ref) in
                guard error == nil, let tournamentID = ref.key else {
                    view.shouldPresentLoadingView(false)
                    return
                }
                
                REF_TOURNAMENTS.child(tournamentID).child("tournamentUsers").observe(.value) { (snapshot) in
                    guard let users = snapshot.value as? [String] else { return }
                    
                    if users.count == tournySize {
                        REF_TOURNAMENTS.child(tournamentID).updateChildValues(["isPublic": false])
                        view.shouldPresentLoadingView(false)
                        DispatchQueue.main.async {
                            let newTourny = Tournament(tournamentID, tournamentUsers: users, true)
                            let controller = LobbyVC(currentUser: currentUser, tournySize: tournySize, tourny: newTourny)
                            view.navigationController?.popToRootViewController(animated: true)
                            view.navigationController?.pushViewController(controller, animated: true)
                        }
                        
                    }
                    view.shouldPresentLoadingView(true, message: "Waiting for other users to join...")
                }
                
            }
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
}
