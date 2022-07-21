//
//  CreateTournyVIewModel.swift
//  BracketzFinal
//
//  Created by Edward McGuiggan on 7/20/22.
//

import Foundation
import UIKit


class CreateTournyViewModel {
    var tournySize = 2
    var sizeOptions = [2, 4, 8, 16]
    var buyInOptions = ["$.25"]
    var view: CreateTournyVC
    
    
    init(_ view: CreateTournyVC) {
        self.view = view
    }
    
    func presentUserSelectionVC() {
        let controller = UserSelectionVC()
        controller.tournySize = tournySize
        view.navigationController?.pushViewController(controller, animated: true)
    }
    
    func presentMenu() {
        let controller = SideMenuVC()
        controller.delegate = view
        let nav = UINavigationController(rootViewController: controller)
        nav.modalPresentationStyle = .fullScreen
        view.present(nav, animated: true, completion: nil)
    }
    
    func presentInvitesController() {
        let controller = InvitesVC()
        view.navigationController?.pushViewController(controller, animated: true)
    }
    
    func presentLoginScreen() {
        let controller = LoginController()
        let nav = UINavigationController(rootViewController: controller)
        nav.modalPresentationStyle = .fullScreen
        view.present(nav, animated: true, completion: nil)
    }
}
