//
//  ViewController.swift
//  BracketzFinal
//
//  Created by Edward McGuiggan on 5/1/21.
//

import UIKit
import Firebase

class JoinTournyVC: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    
    
    var tournySize = 2
    var sizeOptions = [2, 4, 8, 16]
    var buyInOptions = ["$.25"]
    let currentUser = Auth.auth().currentUser?.uid
    
    
    
    private let tournySizeLabel: UILabel = {
        let label = UILabel()
        label.text = "Tournament Size:"
        label.font = UIFont.boldSystemFont(ofSize: 30)
        label.textAlignment = .center
        return label
    }()
    
    private let buyInLabel: UILabel = {
        let label = UILabel()
        label.text = "Buy-In Amount:"
        label.font = UIFont.boldSystemFont(ofSize: 30)
        label.textAlignment = .center
        return label
    }()
    
    private let sizePicker: UIPickerView = {
        let picker = UIPickerView()
        return picker
    }()
    
    private let buyInPicker: UIPickerView = {
        let picker = UIPickerView()
        return picker
    }()
    
    private let joinTournyButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Join Tournament", for: .normal)
        button.layer.cornerRadius = 5
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        button.backgroundColor = #colorLiteral(red: 0.8351245241, green: 0.8433930838, blue: 0.8433930838, alpha: 1)
        button.layer.borderColor = #colorLiteral(red: 0.04823023291, green: 0.04672234866, blue: 0.1949952411, alpha: 1)
        button.layer.borderWidth = 1
        button.setTitleColor(#colorLiteral(red: 0.04823023291, green: 0.04672234866, blue: 0.1949952411, alpha: 1) , for: .normal)
        button.setHeight(height: 50)
        button.isEnabled = true
        button.addTarget(self, action: #selector(checkForTourny), for: .touchUpInside)
        return button
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = #colorLiteral(red: 0.9254901961, green: 0.9411764706, blue: 0.9450980392, alpha: 1)
        sizePicker.delegate = self as UIPickerViewDelegate
        sizePicker.dataSource = self as UIPickerViewDataSource
        buyInPicker.delegate = self as UIPickerViewDelegate
        buyInPicker.dataSource = self as UIPickerViewDataSource
        configureUI()
        //signOut()
        configureNavigationBar(withTitle: "BRACKETZ", prefersLargeTitles: false)
        checkLoggedIn()
        
    }
    
    func checkLoggedIn() {
        if Auth.auth().currentUser == nil {
            presentLoginScreen()
        }
    }
    
    
    @objc func checkForTourny() {
        guard let currentUser = currentUser else { return }
        Service.shared.findPublicTournament(tournySize: tournySize, currentUser: currentUser, view: self)
    }
    
    
    
    func presentUserSelectionVC() {
        let controller = UserSelectionVC()
        controller.tournySize = tournySize
        navigationController?.pushViewController(controller, animated: true)
    }
    
    
    func configureUI() {
        view.backgroundColor = .white
        
        view.addSubview(tournySizeLabel)
        tournySizeLabel.anchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor, right: view.rightAnchor, paddingTop: 60, paddingLeft: 20, paddingRight: 20)
        
        view.addSubview(sizePicker)
        sizePicker.anchor(top: tournySizeLabel.bottomAnchor, left: view.leftAnchor, right: view.rightAnchor, paddingTop: -25, paddingLeft: 30, paddingRight: 30)
        
        view.addSubview(buyInLabel)
        buyInLabel.anchor(top: sizePicker.bottomAnchor, left: view.leftAnchor, right: view.rightAnchor, paddingTop: 10, paddingLeft: 8, paddingRight: 8)
        
        view.addSubview(buyInPicker)
        buyInPicker.anchor(top: buyInLabel.bottomAnchor, left: view.leftAnchor, right: view.rightAnchor, paddingTop: -25, paddingLeft: 30, paddingRight: 30)
        
        view.addSubview(joinTournyButton)
        joinTournyButton.anchor(left: view.leftAnchor, bottom: view.safeAreaLayoutGuide.bottomAnchor, right: view.rightAnchor, paddingLeft: 30, paddingBottom: 40, paddingRight: 30)
        
        let image = UIImage(systemName: "envelope")
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(presentInvitesController))

    }
    
    @objc func presentInvitesController() {
        let controller = InvitesVC()
        navigationController?.pushViewController(controller, animated: true)
    }
    
    
    func presentLoginScreen() {
        DispatchQueue.main.async {
            let controller = LoginController()
            let nav = UINavigationController(rootViewController: controller)
            nav.modalPresentationStyle = .fullScreen
            self.present(nav, animated: true, completion: nil)
        }
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView == sizePicker {
            return sizeOptions.count
        } else {
            return buyInOptions.count
        }
        
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView == sizePicker {
            let row = String(sizeOptions[row])
            return row
        } else {
            let row = buyInOptions[row]
            return row
        }
        
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        tournySize = sizeOptions[row]
    }
    
    func signOut() {
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
}
