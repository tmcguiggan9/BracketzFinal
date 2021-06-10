//
//  User.swift
//  BracketzFinal
//
//  Created by Edward McGuiggan on 5/13/21.
//

import Foundation


struct User: Equatable {
    let email: String
    let fullname: String
    let username: String
    let uid: String
    let unresolvedTournaments = [String]()
    
    
    init(uid: String, dictionary: [String: Any]) {
        self.email = dictionary["email"] as? String ?? ""
        self.fullname = dictionary["fullname"] as? String ?? ""
        self.username = dictionary["username"] as? String ?? ""
        self.uid = uid
    }
}
