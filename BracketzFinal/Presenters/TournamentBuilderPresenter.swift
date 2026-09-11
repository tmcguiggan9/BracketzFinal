//
//  CreateTournyVIewModel.swift
//  BracketzFinal
//
//  Created by Edward McGuiggan on 7/20/22.
//

import Foundation
import UIKit
import FirebaseAuth
import FirebaseDatabase


class TournamentBuilderPresenter {
    var tournySize = 2
    var sizeOptions = [2, 4, 8, 16]
    var buyInOptions = ["$.25"]
    unowned let view: TournamentBuilderVC
    var currentUser: User?
    private var tournamentID: String?
    private var tournamentUsersHandle: DatabaseHandle?
    private var isSearching = false
    private var didNavigateToLobby = false
    
    init(_ view: TournamentBuilderVC) {
        self.view = view
    }
    
    func fetchCurrentUserData() {
        let currentUser = Auth.auth().currentUser
        
        if let currentUser = currentUser {
            Service.shared.fetchUserData(uid: currentUser.uid) { (currentUserData) in
                guard let currentUserData else {
                    self.view.presentError("Unable to load your profile. Please try again.")
                    return
                }
                self.presentUserSelectionVC(currentUserData: currentUserData)
                print("Debug: Current User is \(currentUserData)")
            }
        } else {
            print("DEBUG: Could not collect current user data")
        }
        
    }
    
    func presentUserSelectionVC(currentUserData: User) {
        let controller = UserSelectionVC(currentUser: currentUserData, tournySize: tournySize)
        view.navigationController?.pushViewController(controller, animated: true)
    }
    
    func presentLoginScreen() {
        let controller = LoginController()
        let nav = UINavigationController(rootViewController: controller)
        nav.modalPresentationStyle = .fullScreen
        view.present(nav, animated: true, completion: nil)
    }
    
    func searchForTournyAndEnterLobby() {
        guard !isSearching else { return }
        guard let authenticatedUser = Auth.auth().currentUser else {
            presentLoginScreen()
            return
        }

        isSearching = true
        didNavigateToLobby = false
        view.shouldPresentLoadingView(true, message: "Finding a tournament...")

        Service.shared.fetchUserData(uid: authenticatedUser.uid) { [weak self] currentUser in
            guard let self else { return }
            guard let currentUser else {
                self.stopMatchmaking()
                self.view.shouldPresentLoadingView(false)
                self.view.presentError("Unable to load your profile. Please try again.")
                return
            }
            self.currentUser = currentUser
            self.beginMatchmaking(currentUser: currentUser)
        }
    }

    func stopMatchmaking() {
        if let tournamentID, let tournamentUsersHandle {
            Service.shared.stopObservingTournamentUsers(tournamentID: tournamentID, handle: tournamentUsersHandle)
        }
        tournamentUsersHandle = nil
        tournamentID = nil
        isSearching = false
    }

    private func beginMatchmaking(currentUser: User) {
        Service.shared.findOrCreatePublicTournament(
            tournamentSize: tournySize,
            userID: currentUser.uid
        ) { [weak self] result in
            guard let self else { return }

            switch result {
            case .success(let session):
                self.tournamentID = session.tournamentID
                if session.userIDs.count == self.tournySize {
                    self.enterLobby(tournamentID: session.tournamentID, users: session.userIDs, currentUser: currentUser)
                } else {
                    self.view.shouldPresentLoadingView(false)
                    self.view.shouldPresentLoadingView(true, message: "Waiting for other users to join...")
                    self.observeTournament(tournamentID: session.tournamentID, currentUser: currentUser)
                }
            case .failure:
                self.stopMatchmaking()
                self.view.shouldPresentLoadingView(false)
                self.view.presentError("Unable to join matchmaking. Please try again.")
            }
        }
    }

    private func observeTournament(tournamentID: String, currentUser: User) {
        tournamentUsersHandle = Service.shared.observeTournamentUsers(tournamentID: tournamentID) { [weak self] users in
            guard let self, let users else { return }
            guard users.count == self.tournySize else { return }
            self.enterLobby(tournamentID: tournamentID, users: users, currentUser: currentUser)
        }
    }

    private func enterLobby(tournamentID: String, users: [String], currentUser: User) {
        guard !didNavigateToLobby else { return }
        didNavigateToLobby = true
        stopMatchmaking()
        view.shouldPresentLoadingView(false)

        let tournament = Tournament(tournamentID, tournamentUsers: users, true)
        let controller = LobbyVC(currentUser: currentUser, tournySize: tournySize, tourny: tournament)
        view.navigationController?.popToRootViewController(animated: false)
        view.navigationController?.pushViewController(controller, animated: true)
    }

    deinit {
        stopMatchmaking()
    }
}
