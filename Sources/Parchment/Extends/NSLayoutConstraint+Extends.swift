//
//  NSLayoutConstraint+Extends.swift
//  Parchment
//
//  Created by okferret on 2026/6/4.
//

#if canImport(UIKit)
import UIKit

extension NSLayoutConstraint: Compatible {}
extension CompatibleWrapper where Base: NSLayoutConstraint {

    /// firstItem
    /// - Returns: Optional<T>
    internal func firstItem<T>() -> Optional<T> {
        return base.firstItem as? T
    }
    
    /// secondItem
    /// - Returns: Optional<T>
    internal func secondItem<T>() -> Optional<T> {
        return base.secondItem as? T
    }
}

#endif
