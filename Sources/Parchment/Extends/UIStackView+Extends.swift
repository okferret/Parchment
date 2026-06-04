//
//  UIStackView+Extends.swift
//  Parchment
//
//  Created by okferret on 2026/6/4.
//

#if canImport(UIKit)
import UIKit

extension UIStackView {
    
    /// 构造函数
    /// - Parameters:
    ///   - arrangedSubviews: Array<UIView>
    ///   - axis: NSLayoutConstraint.Axis
    ///   - alignment: UIStackView.Alignment
    ///   - distribution: UIStackView.Distribution
    ///   - spacing: CGFloat
    internal convenience init(arrangedSubviews: Array<UIView>,
                              axis: NSLayoutConstraint.Axis = .vertical,
                              alignment: UIStackView.Alignment = .fill,
                              distribution: UIStackView.Distribution = .fill,
                              spacing: CGFloat = 6.0) {
        self.init(arrangedSubviews: arrangedSubviews)
        self.axis = axis
        self.alignment = alignment
        self.distribution = distribution
        self.spacing = spacing
    }
}


#endif
