//
//  UIView+Extends.swift
//  Parchment
//
//  Created by okferret on 2026/6/10.
//

#if canImport(UIKit)
import UIKit

extension CompatibleWrapper where Base: UIView {
    
    /// broughtToFront
    internal func broughtToFront() {
        base.superview?.bringSubviewToFront(base)
    }
}

#endif
