//
//  UIColor+Extends.swift
//  Parchment
//
//  Created by okferret on 2026/6/3.
//

#if canImport(UIKit)
import UIKit

extension UIColor {
    
    /// hex color
    /// - Parameters:
    ///   - hex: String
    ///   - alpha: CGFloat
    /// - Returns: UIColor
    internal static func hex(_ hex: String, alpha: CGFloat = 1.0) -> UIColor {
        return .init(hex: hex, alpha: alpha)
    }
    
    /// to hex string
    /// - Parameter includeAlpha: Bool
    /// - Returns: String
    internal func toHex(includeAlpha: Bool = false) -> String? {
        guard let components = self.cgColor.components, components.count >= 3 else {
            return nil
        }
        
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        var a: Float = 1.0
        
        if components.count >= 4 {
            a = Float(components[3])
        }
        
        if includeAlpha {
            return String(format: "#%02lX%02lX%02lX%02lX",
                          lroundf(r * 255),
                          lroundf(g * 255),
                          lroundf(b * 255),
                          lroundf(a * 255))
        } else {
            return String(format: "#%02lX%02lX%02lX",
                          lroundf(r * 255),
                          lroundf(g * 255),
                          lroundf(b * 255))
        }
    }
    
    /// 构造函数
    /// - Parameters:
    ///   - hex: hex string
    ///   - alpha: 透明度
    private convenience init(hex: String, alpha: CGFloat = 1.0) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        let length = hexSanitized.count
        let r, g, b: CGFloat
        
        if length == 6 {
            r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            b = CGFloat(rgb & 0x0000FF) / 255.0
        } else if length == 3 {
            r = CGFloat((rgb & 0xF00) >> 8) / 15.0
            g = CGFloat((rgb & 0x0F0) >> 4) / 15.0
            b = CGFloat(rgb & 0x00F) / 15.0
        } else {
            self.init(white: 0, alpha: 1)
            return
        }
        
        self.init(red: r, green: g, blue: b, alpha: alpha)
    }
    
    /// 构造函数
    /// - Parameters:
    ///   - lightHex: hex value of light mode color
    ///   - darkHex: hex value of dark mode color
    internal convenience init(light lightHex: String, dark darkHex: String) {
        self.init { trait in
            switch trait.userInterfaceStyle {
            case .dark: return .init(hex: darkHex)
            default:    return .init(hex: lightHex)
            }
        }
    }
    
    /// 随机色
    internal static var random: UIColor {
        return UIColor(red: .random(in: 0...1), green: .random(in: 0...1), blue: .random(in: 0...1), alpha: 1.0)
    }
}

#endif
