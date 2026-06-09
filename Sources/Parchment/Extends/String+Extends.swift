//
//  String+Extends.swift
//  Parchment
//
//  Created by okferret on 2026/6/8.
//

#if canImport(Foundation) && canImport(CryptoKit) && canImport(UIKit)
import Foundation
import CryptoKit
import UIKit

extension String.Encoding {
    
    /// GBK_95
    internal static let GBK: String.Encoding = {
        let cfEncoding: CFStringEncoding = CFStringEncoding(CFStringEncodings.GBK_95.rawValue)
        let rawValue: UInt = CFStringConvertEncodingToNSStringEncoding(cfEncoding)
        return .init(rawValue: rawValue)
    }()
    
    /// GB_18030_2000
    internal static let GB18030: String.Encoding = {
        let cfEncoding: CFStringEncoding = CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue)
        let rawValue: UInt = CFStringConvertEncodingToNSStringEncoding(cfEncoding)
        return .init(rawValue: rawValue)
    }()
    
    /// GB_2312_80
    internal static let GB2312: String.Encoding = {
        let cfEncoding: CFStringEncoding = CFStringEncoding(CFStringEncodings.GB_2312_80.rawValue)
        let rawValue: UInt = CFStringConvertEncodingToNSStringEncoding(cfEncoding)
        return .init(rawValue: rawValue)
    }()
}

extension String: CompatibleValue {}
extension CompatibleWrapper where Base == String {
    
    /// Data
    internal var utf8Data: Data {
        return Data(base.utf8)
    }
    
    /// md5
    internal var md5: String {
        return Insecure.MD5.hash(data: base.hub.utf8Data).map { String(format: "%02x", $0) }.joined()
    }
    
    /// Bool
    internal var isBlank: Bool {
        return base.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true
    }
    
    /// String
    internal var cleanText: String {
        return base
            .components(separatedBy: .newlines)
            .map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) })
            .filter({ $0.hub.isBlank == false })
            .joined(separator: "\n")
    }
    
    /// 计算字符串在指定字体下的宽度
    /// - Parameter font: UIFont
    /// - Returns: CGFloat
    internal func width(with font: UIFont) -> CGFloat {
        let attributes = [NSAttributedString.Key.font: font]
        let size = (base as NSString).size(withAttributes: attributes)
        return size.width
    }
    
}

#endif
