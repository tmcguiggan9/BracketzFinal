//
//  TabBarControllerViewController.swift
//  BracketzFinal
//
//  Created by Edward McGuiggan on 6/10/21.
//

import UIKit
import Firebase

class TabBarController: UITabBarController, UITabBarControllerDelegate, SideMenuVCDelegate {
    
    let view1 = TournamentBuilderVC(tournamentType: .create)
    let view2 = TournamentBuilderVC(tournamentType: .join)
    let currentUser = Auth.auth().currentUser
    
    func handleLogout() {
        do {
            try Auth.auth().signOut()
            DispatchQueue.main.async {
                let nav = UINavigationController(rootViewController: LoginController())
                nav.modalPresentationStyle = .fullScreen
                self.present(nav, animated: true, completion: nil)
            }
        } catch {
            print("error signing out")
        }
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        configureNavigationBar(withTitle: "BRACKETZ", prefersLargeTitles: false)

        let image = UIImage(systemName: "envelope.badge")
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(fetchCurrentUserData))
        let image2 = UIImage(systemName: "line.horizontal.3")
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: image2, style: .plain, target: self, action: #selector(presentMenu))
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        checkLoggedIn()
//        let view1 = TournamentBuilderVC(tournamentType: .create)
//        let view2 = TournamentBuilderVC(tournamentType: .join)
        let icon1 = UITabBarItem(title: "Create", image: UIImage(systemName: "plus"), selectedImage: UIImage(systemName: "plus"))
        let icon2 = UITabBarItem(title: "Join", image: UIImage(systemName: "person.3.fill"), selectedImage: UIImage(systemName: "person.3.fill"))
        view1.tabBarItem = icon1
        view2.tabBarItem = icon2
        let controllers = [view1, view2]
        self.viewControllers = controllers
    
    }
    
    @objc func fetchCurrentUserData() {
        guard let currentUser = currentUser else { return }
        Service.shared.fetchUserData(uid: currentUser.uid) { (currentUserData) in
            self.presentInvitesController(currentUserData: currentUserData)
            print("Debug: Current User is \(currentUserData)")
        }
    }
    
    func checkLoggedIn() {
        if Auth.auth().currentUser == nil {
            presentLoginScreen()
        }
    }
    
    func presentLoginScreen() {
        DispatchQueue.main.async {
            let controller = LoginController()
            let nav = UINavigationController(rootViewController: controller)
            nav.modalPresentationStyle = .fullScreen
            self.present(nav, animated: true, completion: nil)
        }
    }
    
    @objc func presentMenu() {
        let controller = SideMenuVC()
        controller.delegate = self
        let nav = UINavigationController(rootViewController: controller)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true, completion: nil)
    }
    
    func presentInvitesController(currentUserData: User) {
        let controller = InvitesVC(currentUser: currentUserData)
        navigationController?.pushViewController(controller, animated: true)
    }
    
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        return true
        
    }

}
