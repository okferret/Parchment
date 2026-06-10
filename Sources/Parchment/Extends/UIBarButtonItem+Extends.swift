//
//  UIBarButtonItem+Extends.swift
//  Parchment
//
//  Created by okferret on 2026/6/3.
//

#if canImport(UIKit)
import UIKit

extension UIBarButtonItem {
    
    /// flexible
    /// - Returns: UIBarButtonItem
    internal static func flexible() -> UIBarButtonItem {
        if #available(iOS 14.0, *) {
            return .flexibleSpace()
        } else {
            return .init(barButtonSystemItem: .flexibleSpace, target: .none, action: .none)
        }
    }
    
    /// State
    struct State: RawRepresentable, Hashable {
        internal typealias RawValue = Int
        internal let rawValue: Int
        internal init(rawValue: Int) {
            self.rawValue = rawValue
        }
        
        internal static var normal: State { .init(rawValue: 1 << 1) }
        internal static var selected: State { .init(rawValue: 1 << 2) }
    }
    
    /// Optional<Void>
    fileprivate static var stateKey: Optional<Void> = .none
}

extension CompatibleWrapper where Base: UIBarButtonItem {
    
    /// 状态
    internal var state: UIBarButtonItem.State {
        get { .init(rawValue: (objc_getAssociatedObject(base, &UIBarButtonItem.stateKey) as? Int) ?? 0) }
        set { objc_setAssociatedObject(base, &UIBarButtonItem.stateKey, newValue.rawValue, .OBJC_ASSOCIATION_ASSIGN) }
    }
}



#endif
