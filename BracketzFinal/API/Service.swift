//
//  Service.swift
//  BracketzFinal
//
//  Created by Edward McGuiggan on 5/17/21.
//

import Foundation
import Firebase

let DB_REF = Database.database().reference()
let REF_USERS = DB_REF.child("users")
let REF_TOURNAMENTS = DB_REF.child("tournaments")
let REF_MATCHES = DB_REF.child("matches")

private var refHandle: DatabaseHandle!

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
            guard let users = snapshot.value as? [String: Any] else { return }
            var newUsers = [User]()
            for x in users {
                newUsers.append(User(uid: x.key, dictionary: x.value as! [String : Any]))
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
                    var dictionary: [String: Any]
                    dictionary = x.value as! [String: Any]
                    if dictionary["isPublic"] as! Int == 1 && dictionary["tournySize"] as! Int == tournySize{
                        print(x.key)
                        
                        REF_TOURNAMENTS.child(x.key).runTransactionBlock { (currentData: MutableData) -> TransactionResult in
                            var tourny = currentData.value as? [String: Any]
                            
                            
                            if tourny == nil {
                                tourny = [:]
                            } else {
                                tourny!["acceptedUsers"] = tourny!["acceptedUsers"] as! Int + 1
                                tournyUsers = (tourny!["tournamentUsers"] as? [String])!
                                tournyUsers.append(currentUser.uid)
                                tourny!["tournamentUsers"] = tournyUsers
                                
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
            }
            let values = ["tournamentUsers": [currentUser.uid], "acceptedUsers": 1, "isPublic": true, "tournySize": tournySize] as [String: Any]
            REF_TOURNAMENTS.childByAutoId().updateChildValues(values) { (error, ref) in
                
                REF_TOURNAMENTS.child(ref.key!).child("tournamentUsers").observe(.value) { (snapshot) in
                    guard let users = snapshot.value as? [String] else { return }
                    
                    if users.count == tournySize {
                        REF_TOURNAMENTS.child(ref.key!).updateChildValues(["isPublic": false])
                        view.shouldPresentLoadingView(false)
                        DispatchQueue.main.async {
                            let newTourny = Tournament(ref.key!, tournamentUsers: users, true)
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
        let values = ["tournamentUsers": tournyUsers, "acceptedUsers": 1, "isPublic": false] as [String: Any]
        REF_TOURNAMENTS.childByAutoId().updateChildValues(values) { (error, ref) in
            view.dismiss(animated: true, completion: nil)
            
            for x in tournyUsers {
                REF_USERS.child(x).child("unresolvedTournaments").observeSingleEvent(of: .value) { (snapshot) in
                    if var array = snapshot.value as? [String] {
                        array.append(ref.key!)
                        REF_USERS.child(x).updateChildValues(["unresolvedTournaments": array])
                    } else {
                        REF_USERS.child(x).updateChildValues(["unresolvedTournaments": [ref.key]])
                    }
                }
            }
            
                let newTourny = Tournament(ref.key!, tournamentUsers: tournyUsers, false)
                let controller = LobbyVC(currentUser: currentUser, tournySize: tournySize, tourny: newTourny)
            
                view.navigationController?.pushViewController(controller, animated: true)
            }
    }
}
