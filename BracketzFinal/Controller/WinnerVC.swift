//
//  WinnerVC.swift
//  BracketzFinal
//
//  Created by Edward McGuiggan on 6/8/21.
//

import UIKit

class WinnerVC: UIViewController {
    
    private let winLabel: UILabel = {
        let label = UILabel()
        label.text = "You won the tournament!"
        label.font = UIFont.boldSystemFont(ofSize: 30)
        label.textAlignment = .center
        return label
    }()
    
    private let returnButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Return Home", for: .normal)
        button.layer.cornerRadius = 5
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        button.backgroundColor = #colorLiteral(red: 0.04823023291, green: 0.04672234866, blue: 0.1949952411, alpha: 1)
        button.setTitleColor(.white, for: .normal)
        button.setHeight(height: 50)
        button.isEnabled = true
        button.addTarget(self, action: #selector(returnHome), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        configureUI()
        navigationController?.navigationBar.isHidden = true
        // Do any additional setup after loading the view.
    }
    
    
    @objc func returnHome() {
        navigationController?.navigationBar.isHidden = false
        navigationController?.popToRootViewController(animated: true)
    }
    
    func configureUI() {
        view.addSubview(winLabel)
        winLabel.centerY(inView: view)
        winLabel.centerX(inView: view)
        
        view.addSubview(returnButton)
        returnButton.anchor(left: view.leftAnchor, bottom: view.safeAreaLayoutGuide.bottomAnchor, right: view.rightAnchor, paddingLeft: 15, paddingBottom: 15, paddingRight: 15)
    }
    

}
