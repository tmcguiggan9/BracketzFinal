//
//  moveButton.swift
//  BracketzFinal
//
//  Created by Edward McGuiggan on 9/8/22.
//

import Foundation
import UIKit


class MoveButton: UIButton {
    
    init(image: UIImage, move: String) {
        super.init(frame: .zero)
        
        let tintedImage = image.withRenderingMode(.alwaysTemplate)
        setImage(tintedImage, for: .normal)
        tintColor = .black
        imageEdgeInsets = UIEdgeInsets(top: 12,left: 20,bottom: 12,right: 20)
        layer.borderWidth = 3
        layer.borderColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        setTitle("rock", for: .normal)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
