//
//  PlayerCollectionCell.swift
//  BracketzFinal
//
//  Created by Edward McGuiggan on 6/7/21.
//

import UIKit

class PlayerCollectionCell: UICollectionViewCell {
    
    var user: User? {
        didSet {
            configure()
        }
    }
    
    
    private let profileImageView: UIView = {
        let view = UIView()
        
        view.backgroundColor = #colorLiteral(red: 0.04823023291, green: 0.04672234866, blue: 0.1949952411, alpha: 1)
        view.setDimensions(height: 50, width: 50)
        view.layer.cornerRadius = 50/2
        return view
    }()
    
    private let userNameLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.textAlignment = .left
        label.textColor = #colorLiteral(red: 0.04823023291, green: 0.04672234866, blue: 0.1949952411, alpha: 1)
        return label
    }()
    
    private let fullNameLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont.systemFont(ofSize: 15)
        label.textAlignment = .left
        label.textColor = #colorLiteral(red: 0.04823023291, green: 0.04672234866, blue: 0.1949952411, alpha: 1)
        return label
    }()
    
    
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        
        self.layer.shadowOffset = CGSize(width: 0.0, height: 2.0)
        self.layer.shadowRadius = 0.0
        self.layer.shadowOpacity = 0.3
        self.layer.borderColor = #colorLiteral(red: 0.04823023291, green: 0.04672234866, blue: 0.1949952411, alpha: 1)
        self.layer.borderWidth = 1
   //     setHeight(height: 50)
        
        
        addSubview(profileImageView)
        profileImageView.centerY(inView: self)
        profileImageView.anchor(left: self.leftAnchor, paddingLeft: 15)
        
        let stack = UIStackView(arrangedSubviews: [userNameLabel, fullNameLabel])
        stack.axis = .vertical
        stack.spacing = 5
        
        addSubview(stack)
        stack.centerY(inView: self)
        stack.anchor(left: profileImageView.rightAnchor, paddingLeft: 15)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure() {
        userNameLabel.text = user!.username
        fullNameLabel.text = user!.fullname
    }
}
