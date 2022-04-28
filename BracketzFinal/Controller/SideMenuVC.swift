//
//  SideMenuVCViewController.swift
//  BracketzFinal
//
//  Created by Edward McGuiggan on 6/7/21.
//

import UIKit

protocol SideMenuVCDelegate: AnyObject {
    func handleLogout()
}

class SideMenuVC: UIViewController {
    
    weak var delegate: SideMenuVCDelegate?
    
    private var logoutButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Log Out", for: .normal)
        button.layer.cornerRadius = 5
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        button.backgroundColor = #colorLiteral(red: 0.3958335519, green: 0.3949077725, blue: 0.4570672512, alpha: 1)
        button.setTitleColor(.white, for: .normal)
        button.setHeight(height: 50)
        button.isEnabled = true
        button.addTarget(self, action: #selector(handleLogout), for: .touchUpInside)
        return button
    }()
    
    @objc func handleLogout() {
        let alert = UIAlertController(title: nil, message: "Are you sure you want to logout?", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Log Out", style: .destructive, handler: { _ in
            self.dismiss(animated: true) {
                self.delegate?.handleLogout()
            }
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        configureUI()
        configureNavigationBar(withTitle: "", prefersLargeTitles: false)
        let image2 = UIImage(systemName: "arrow.backward")
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: image2, style: .plain, target: self, action: #selector(dismissMenu))
    }
    
    @objc func dismissMenu() {
        dismiss(animated: true, completion: nil)
    }
    
    func configureUI() {
        view.addSubview(logoutButton)
        logoutButton.anchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor, right: view.rightAnchor, paddingTop: 30, paddingLeft: 20, paddingRight: 20)
        
    }
    


}
