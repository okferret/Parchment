//
//  UIAlertController+Extends.swift
//  Parchment
//
//  Created by okferret on 2026/8/17.
//

#if canImport(UIKit)

import UIKit

extension CompatibleWrapper where Base: UIAlertController {
    
    /// add action
    /// - Parameters:
    ///   - title: String
    ///   - style: UIAlertAction.Style
    ///   - handler: Optional<() -> Void>
    internal func addAction(title: String,
                            style: UIAlertAction.Style = .default,
                            handler: Optional<() -> Void> = .none) {
        let action: UIAlertAction = .init(title: title, style: style) { _ in
            handler?()
        }
        base.addAction(action)
    }
}

#endif
