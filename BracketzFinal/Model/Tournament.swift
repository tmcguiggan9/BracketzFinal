//
//  Tournament.swift
//  BracketzFinal
//
//  Created by Edward McGuiggan on 5/13/21.
//

import Foundation



struct Tournament {
    let tournamentID: String
    let tournamentUsers: [String]
    var acceptedUsers = 1
    
    init(_ tournamentID: String, tournamentUsers: [String]) {
        self.tournamentID = tournamentID
        self.tournamentUsers = tournamentUsers
    }
}
