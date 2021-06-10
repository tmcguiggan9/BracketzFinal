//
//  playerView.swift
//  BracketzFinal
//
//  Created by Edward McGuiggan on 5/14/21.
//

import UIKit


class PlayerView: UIView {
    
    
    
    init(username: String) {
        super.init(frame: .zero)
        
        backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        
        self.layer.cornerRadius = 10
        self.layer.borderColor = #colorLiteral(red: 0.04823023291, green: 0.04672234866, blue: 0.1949952411, alpha: 1)
        self.layer.borderWidth = 1
        setHeight(height: 50)
        
        let nameLabel = UILabel()
        nameLabel.text = username
        nameLabel.font = UIFont.systemFont(ofSize: 30)
        nameLabel.textAlignment = .left
        nameLabel.textColor = #colorLiteral(red: 0.04823023291, green: 0.04672234866, blue: 0.1949952411, alpha: 1)
        
        addSubview(nameLabel)
        nameLabel.centerX(inView: self)
        nameLabel.centerY(inView: self)
    }

    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
