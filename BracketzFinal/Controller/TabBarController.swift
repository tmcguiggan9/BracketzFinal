//
//  TabBarControllerViewController.swift
//  BracketzFinal
//
//  Created by Edward McGuiggan on 6/10/21.
//

import UIKit

class TabBarController: UITabBarController, UITabBarControllerDelegate, SideMenuVCDelegate {
    func handleLogout() {
        print("123")
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        configureNavigationBar(withTitle: "BRACKETZ", prefersLargeTitles: false)

        let image = UIImage(systemName: "envelope.badge")
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(presentInviteController))
        let image2 = UIImage(systemName: "line.horizontal.3")
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: image2, style: .plain, target: self, action: #selector(presentMenu))
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let view1 = TournyTypeVC()
        let view2 = JoinTournyVC()
        let icon1 = UITabBarItem(title: "Create", image: UIImage(systemName: "plus"), selectedImage: UIImage(systemName: "plus"))
        let icon2 = UITabBarItem(title: "Join", image: UIImage(systemName: "person.3.fill"), selectedImage: UIImage(systemName: "person.3.fill"))
        view1.tabBarItem = icon1
        view2.tabBarItem = icon2
        let controllers = [view1, view2]
        self.viewControllers = controllers
    
    }
    
    @objc func presentMenu() {
        let controller = SideMenuVC()
        controller.delegate = self
        let nav = UINavigationController(rootViewController: controller)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true, completion: nil)
    }
    
    @objc func presentInviteController() {
        let controller = InvitesVC()
        navigationController?.pushViewController(controller, animated: true)
    }
    
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        return true
        
    }

}
