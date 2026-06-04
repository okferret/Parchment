//
//  UIImage+Extends.swift
//  Parchment
//
//  Created by okferret on 2026/6/4.
//

#if canImport(UIKit)
import UIKit

extension UIImage {
    
    /// module
    /// - Parameter named: String
    /// - Returns: Optional<UIImage>
    internal static func module(named: String) -> Optional<UIImage> {
        return .init(named: named, in: .module, compatibleWith: .none)
    }
}

#endif
