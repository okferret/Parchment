//
//  UIApplication+Extends.swift
//  Parchment
//
//  Created by okferret on 2026/6/4.
//

#if canImport(UIKit)
import UIKit

extension UIApplication {
    
    /// Optional<Void>
    fileprivate static var safeAreaInsetsKey: Optional<Void> = .none
}

extension CompatibleWrapper where Base: UIApplication {
    
    /// 获取key window
    internal var keyWindow: Optional<UIWindow> {
        if #available(iOS 15.0, *) {
            // iOS 15+ 的简洁写法
            return UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.flatMap { $0.windows }.first(where: { $0.isKeyWindow })
        } else if #available(iOS 13.0, *) {
            // iOS 13-14 的处理
            return UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }.first { $0.activationState == .foregroundActive }?.windows.first(where: { $0.isKeyWindow })
        } else {
            // iOS 12 及以下
            return UIApplication.shared.windows.first(where: { $0.isKeyWindow })
        }
    }
    
    /// UIEdgeInsets
    internal var safeAreaInsets: UIEdgeInsets {
        return base.hub.keyWindow?.safeAreaInsets ?? .zero
    }
    
    /// CGFloat
    internal var brightness: CGFloat {
        return base.hub.keyWindow?.screen.brightness ?? 0.5
    }
}

#endif
