//
//  UIFont+Extends.swift
//  Parchment
//
//  Created by okferret on 2026/6/4.
//

#if canImport(UIKit)
import UIKit

extension UIFont {
    
    /// pingfangSC
    /// - Parameters:
    ///   - fontSize: CGFloat
    ///   - weight: UIFont.Weight
    /// - Returns: UIFont
    internal static func pingfangSC(ofSize fontSize: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
        switch weight {
        case .ultraLight:   return .init(name: "PingFangSC-Ultralight", size: fontSize)!
        case .thin:         return .init(name: "PingFangSC-Thin", size: fontSize)!
        case .light:        return .init(name: "PingFangSC-Light", size: fontSize)!
        case .regular:      return .init(name: "PingFangSC-Regular", size: fontSize)!
        case .medium:       return .init(name: "PingFangSC-Medium", size: fontSize)!
        case .semibold:     return .init(name: "PingFangSC-Semibold", size: fontSize)!
        default:            return .systemFont(ofSize: fontSize, weight: weight)
        }
    }
}

#endif
