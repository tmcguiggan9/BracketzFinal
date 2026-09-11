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
    
    func fetchInvites(uid: String, completion: @escaping([String]) -> Void) {
        REF_USERS.child(uid).child("unresolvedTournaments").observe( .value) { (snapshot) in
            guard let invites = snapshot.value as? [String] else { return }
    
            completion(invites)
        }
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
            let values = ["tournamentUsers": [currentUser.uid], "acceptedUsers": 1, "isPublic": true, "tournySize": tournySize] as [String: Any]
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
    
    
    func addUserToInviteList(invites: [String], row: Int, view: UIViewController, currentUser: User) {
        
        REF_TOURNAMENTS.child(invites[row]).child("acceptedUsers").observeSingleEvent(of: .value) { (snapshot) in
            guard var presentUsers = snapshot.value as? Int else { return }
            presentUsers += 1
            REF_TOURNAMENTS.child(invites[row]).updateChildValues(["acceptedUsers": presentUsers])
        }
        
        
        REF_TOURNAMENTS.child(invites[row]).child("tournamentUsers").observeSingleEvent(of: .value) { (snapshot) in
            guard let users = snapshot.value as? [String] else { return }
            let newTourny = Tournament(invites[row], tournamentUsers: users, false)
            let controller = LobbyVC(currentUser: currentUser, tournySize: users.count, tourny: newTourny)
            view.navigationController?.pushViewController(controller, animated: true)
        }
    }
    
    
    
    func sendInvitesAndCreateTournament(tournyUsers: [String], tournySize: Int, view: UIViewController, currentUser: User) {
        let values = ["tournamentUsers": tournyUsers, "acceptedUsers": 1, "isPublic": false, "tournySize": tournySize] as [String: Any]
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
}
