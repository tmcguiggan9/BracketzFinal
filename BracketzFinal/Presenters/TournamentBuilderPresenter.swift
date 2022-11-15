//
//  CreateTournyVIewModel.swift
//  BracketzFinal
//
//  Created by Edward McGuiggan on 7/20/22.
//

import Foundation
import UIKit
import Firebase
import MapKit


class TournamentBuilderPresenter {
    var tournySize = 2
    var sizeOptions = [2, 4, 8, 16]
    var buyInOptions = ["$.25"]
    var view: TournamentBuilderVC
    var currentUser: User?
    
    
    
    init(_ view: TournamentBuilderVC) {
        self.view = view
    }
    
    func fetchCurrentUserData() {
        let currentUser = Auth.auth().currentUser
        
        if let currentUser = currentUser {
            Service.shared.fetchUserData(uid: currentUser.uid) { (currentUserData) in
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
        if let currentUser = currentUser {
            Service.shared.findPublicTournament(tournySize: tournySize, currentUser: currentUser, view: view)
        } else {
            print("Could not fetch current user data")
        }
    }
}
