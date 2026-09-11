//
//  InvitesPresenter.swift
//  BracketzFinal
//
//  Created by Edward McGuiggan on 9/6/22.
//

import Foundation
import FirebaseDatabase

class InvitesPresenter {
    unowned let view: InvitesVC
    let currentUser: User
    private var invitesHandle: DatabaseHandle?
    
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
        stop()
        let uid = currentUser.uid
        invitesHandle = Service.shared.observeInvites(uid: uid) { [weak self] invites in
            self?.invites = invites
        }
    }
    
    func acceptInvite(indexPath: IndexPath) {
        guard let tournamentID = invites?[safe: indexPath.row] else { return }
        let navigationController = view.navigationController
        let currentUser = currentUser

        view.dismiss(animated: true) {
            Service.shared.acceptInvite(tournamentID: tournamentID, currentUser: currentUser) { tournament in
                guard let tournament else { return }
                let controller = LobbyVC(currentUser: currentUser, tournySize: tournament.tournamentUsers.count, tourny: tournament)
                navigationController?.pushViewController(controller, animated: true)
            }
        }
    }
    
    func deleteInvite(indexPath: IndexPath) {
        guard let tournamentID = invites?[safe: indexPath.row] else { return }
        Service.shared.removeInvite(tournamentID: tournamentID, uid: currentUser.uid)
    }

    func stop() {
        guard let invitesHandle else { return }
        Service.shared.stopObservingInvites(uid: currentUser.uid, handle: invitesHandle)
        self.invitesHandle = nil
    }

    deinit {
        stop()
    }
}

private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
