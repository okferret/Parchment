//
//  NSObject+Extends.swift
//  Parchment
//
//  Created by okferret on 2026/6/10.
//

import Foundation

extension NSObject: Compatible {}
extension CompatibleWrapper where Base: NSObject {
    
    /// copy
    /// - Returns: Optional<T>
    internal func copy<T>() -> Optional<T> where T: NSObject {
        return base.copy() as? T
    }
    
    /// mutableCopy
    /// - Returns: Optional<T>
    internal func mutableCopy<T>() -> Optional<T> where T: NSObject {
        return base.mutableCopy() as? T
    }
}
