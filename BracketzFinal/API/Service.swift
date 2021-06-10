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
}
