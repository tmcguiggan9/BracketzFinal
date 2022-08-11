//
//  Tournament.swift
//  BracketzFinal
//
//  Created by Edward McGuiggan on 5/13/21.
//

import Foundation


public enum TournamentType {
    case create
    case join
}

struct Tournament {
    let tournamentID: String
    let tournamentUsers: [String]
    var acceptedUsers = 1
    let isPublic: Bool
    
    init(_ tournamentID: String, tournamentUsers: [String],_ isPublic: Bool) {
        self.tournamentID = tournamentID
        self.tournamentUsers = tournamentUsers
        self.isPublic = isPublic
    }
}
