//
//  InvitesPresenter.swift
//  BracketzFinal
//
//  Created by Edward McGuiggan on 9/6/22.
//

import Foundation

class InvitesPresenter {
    var view: InvitesVC
    var currentUser: User
    
    var invites: [String]? {
        didSet {
            view.tableView.reloadData()
        }
    }
    
    init(_ view: InvitesVC, currentUser: User) {
        self.view = view
        self.currentUser = currentUser
    }
    
    func fetchInvites() {
        let uid = currentUser.uid
        Service.shared.fetchInvites(uid: uid) { (invites) in
            self.invites = invites
        }
    }
    
    func acceptInvite(indexPath: IndexPath) {
        view.dismiss(animated: true) {
            if let invites = self.invites {
                Service.shared.addUserToInviteList(invites: invites, row: indexPath.row, view: self.view, currentUser: self.currentUser)
            }
        }
    }
    
    func deleteInvite(indexPath: IndexPath) {
        let uid = currentUser.uid
        REF_TOURNAMENTS.child(invites![indexPath.row]).removeValue()
        invites?.remove(at: indexPath.row)
        REF_USERS.child(uid).updateChildValues(["unresolvedTournaments": invites!])
        view.tableView.reloadData()
    }
}
