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
    var tournyUsers = [String]()
    
    
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
        REF_TOURNAMENTS.observeSingleEvent(of: .value) { (snapshot) in
            if let tournys = snapshot.value as? [String: Any] {
                for x in tournys {
                    var dictionary: [String: Any]
                    dictionary = x.value as! [String: Any]
                    if dictionary["isPublic"] as! Int == 1 && dictionary["tournySize"] as! Int == self.tournySize{
                        print(x.key)
                        
                        REF_TOURNAMENTS.child(x.key).runTransactionBlock { (currentData: MutableData) -> TransactionResult in
                            var tourny = currentData.value as? [String: Any]
                            
                            
                            if tourny == nil {
                                tourny = [:]
                            } else {
                                tourny!["acceptedUsers"] = tourny!["acceptedUsers"] as! Int + 1
                                self.tournyUsers = (tourny!["tournamentUsers"] as? [String])!
                                self.tournyUsers.append(self.currentUser!)
                                tourny!["tournamentUsers"] = self.tournyUsers
                                
                                currentData.value = tourny
                            }
                            
                            REF_TOURNAMENTS.child(x.key).child("tournamentUsers").observe(.value) { (snapshot) in
                                guard let users = snapshot.value as? [String] else { return }
                                
                                if users.count == self.tournySize {
                                    self.shouldPresentLoadingView(false)
                                    DispatchQueue.main.async {
                                        let controller = LobbyVC()
                                        controller.tourny = Tournament(x.key, tournamentUsers: users, true)
                                        controller.tournySize = self.tournySize
                                        self.navigationController?.popToRootViewController(animated: true)
                                        self.navigationController?.pushViewController(controller, animated: true)
                                    }
                                }
                                self.shouldPresentLoadingView(true, message: "Waiting for other users to join...")
                            }
                            return TransactionResult.success(withValue: currentData)
                        }
                        return
                    }
                }
            }
            let values = ["tournamentUsers": [self.currentUser], "acceptedUsers": 1, "isPublic": true, "tournySize": self.tournySize] as [String: Any]
            REF_TOURNAMENTS.childByAutoId().updateChildValues(values) { (error, ref) in
                
                REF_TOURNAMENTS.child(ref.key!).child("tournamentUsers").observe(.value) { (snapshot) in
                    guard let users = snapshot.value as? [String] else { return }
                    
                    if users.count == self.tournySize {
                        REF_TOURNAMENTS.child(ref.key!).updateChildValues(["isPublic": false])
                        self.shouldPresentLoadingView(false)
                        DispatchQueue.main.async {
                            let controller = LobbyVC()
                            controller.tourny = Tournament(ref.key!, tournamentUsers: users, true)
                            controller.tournySize = self.tournySize
                            self.navigationController?.popToRootViewController(animated: true)
                            self.navigationController?.pushViewController(controller, animated: true)
                        }
                        
                    }
                    self.shouldPresentLoadingView(true, message: "Waiting for other users to join...")
                }
                
            }
        }
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
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(presentInviteController))

    }
    
    @objc func presentInviteController() {
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

//extension TournyTypeVC: SideMenuVCDelegate {
//    func handleLogout() {
//        signOut()
//    }
//}
