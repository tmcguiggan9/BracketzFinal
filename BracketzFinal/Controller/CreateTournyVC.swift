//
//  ViewController.swift
//  BracketzFinal
//
//  Created by Edward McGuiggan on 5/1/21.
//

import UIKit
import Firebase

class CreateTournyVC: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    var viewModel: CreateTournyViewModel?
    
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
    
    private let selectUsersButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Create Tournament", for: .normal)
        button.layer.cornerRadius = 5
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        button.backgroundColor = #colorLiteral(red: 0.8351245241, green: 0.8433930838, blue: 0.8433930838, alpha: 1)
        button.layer.borderColor = #colorLiteral(red: 0.04823023291, green: 0.04672234866, blue: 0.1949952411, alpha: 1)
        button.layer.borderWidth = 1
        button.setTitleColor(#colorLiteral(red: 0.04823023291, green: 0.04672234866, blue: 0.1949952411, alpha: 1) , for: .normal)
        button.setHeight(height: 50)
        button.isEnabled = true
        button.addTarget(self, action: #selector(presentUserSelectionVC), for: .touchUpInside)
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
        viewModel = CreateTournyViewModel(self)
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
        
        view.addSubview(selectUsersButton)
        selectUsersButton.anchor(left: view.leftAnchor, bottom: view.safeAreaLayoutGuide.bottomAnchor, right: view.rightAnchor, paddingLeft: 30, paddingBottom: 40, paddingRight: 30)
        
        let image = UIImage(systemName: "envelope.badge")
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(presentInvitesController))
        let image2 = UIImage(systemName: "line.horizontal.3")
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: image2, style: .plain, target: self, action: #selector(presentMenu))
        
        // presentLoginScreen()
    }
    
    func checkLoggedIn() {
        if Auth.auth().currentUser == nil {
            presentLoginScreen()
        }
    }
    
    @objc func presentUserSelectionVC() {
        viewModel!.presentUserSelectionVC()
    }
    
    @objc func presentMenu() {
        viewModel!.presentMenu()
    }
    
    @objc func presentInvitesController() {
        viewModel!.presentInvitesController()
    }
    
    func presentLoginScreen() {
        DispatchQueue.main.async {
            self.viewModel!.presentLoginScreen()
        }
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView == sizePicker {
            return viewModel!.sizeOptions.count
        } else {
            return viewModel!.buyInOptions.count
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView == sizePicker {
            let row = String(viewModel!.sizeOptions[row])
            return row
        } else {
            let row = viewModel!.buyInOptions[row]
            return row
        }
        
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        viewModel!.tournySize = viewModel!.sizeOptions[row]
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

extension CreateTournyVC: SideMenuVCDelegate {
    func handleLogout() {
        signOut()
    }
}
