//
//  DrawnImageView.swift
//  Casino 150 cash
//
//  Created by Dmytro Maksymyak on 04.08.2021.
//

import UIKit

class MyScrollView: UIScrollView {
    
    var previousLocation = CGPoint.zero
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("Began")
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("Moved")
    }
}
