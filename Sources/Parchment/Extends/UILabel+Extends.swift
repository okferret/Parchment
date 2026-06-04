//
//  UILabel+Extends.swift
//  Parchment
//
//  Created by okferret on 2026/6/4.
//

#if canImport(UIKit)
import UIKit

extension UILabel {
    
    /// 构造函数
    /// - Parameter attributedText: NSAttributedString
    internal convenience init(_ attributedText: NSAttributedString) {
        self.init(frame: .zero)
        self.attributedText = attributedText
        self.sizeToFit()
    }
}

#endif
