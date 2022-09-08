//
//  UserSelectionPresenter.swift
//  BracketzFinal
//
//  Created by Edward McGuiggan on 8/11/22.
//

import Foundation


class UserSelectionPresenter {
    
    var view: UserSelectionVC
    var tournySize: Int
    var tournyUsers = [String]()
    var finalTournyUsers = [User]()
    var currentUser: User
    
    init(_ view: UserSelectionVC, tournySize: Int, currentUser: User) {
        self.view = view
        self.tournySize = tournySize
        self.currentUser = currentUser
        tournyUsers.append(currentUser.uid)
        finalTournyUsers.append(currentUser)
    }
    
    func cancelTournament() {
        view.navigationController?.popViewController(animated: true)
    }
    
    func sendInvitesAndCreateTournament() {
        guard tournyUsers.count == tournySize else {
            return
        }
        Service.shared.sendInvitesAndCreateTournament(tournyUsers: tournyUsers, tournySize: tournySize, view: view)
    }
    
    func fetchUsers() {
        Service.shared.fetchUsers { (users) in
            self.view.usersFoundBySearch = users
        }
    }
    
}
