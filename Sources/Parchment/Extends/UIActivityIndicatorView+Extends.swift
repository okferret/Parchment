//
//  UIActivityIndicatorView+Extends.swift
//  Parchment
//
//  Created by okferret on 2026/6/10.
//

#if canImport(UIKit)
import UIKit

extension CompatibleWrapper where Base: UIActivityIndicatorView {
    
    /// startAnimating
    internal func startAnimating() {
        base.hub.broughtToFront()
        base.startAnimating()
    }
    
    /// stopAnimating
    internal func stopAnimating() {
        base.stopAnimating()
    }
}

#endif
