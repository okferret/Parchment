//
//  PAError.swift
//  Parchment
//
//  Created by okferret on 2026/6/5.
//
#if canImport(Foundation)
import Foundation

/// PAError
struct PAError {
    
    /// 错误码
    struct Code: RawRepresentable {
        internal typealias RawValue = UInt
        internal let rawValue: UInt
        internal init(rawValue: UInt) {
            self.rawValue = rawValue
        }
    }
    
    /// 错误码
    internal let code: Code
    /// 错误信息
    internal let message: String
    
    /// 构造函数
    /// - Parameters:
    ///   - code: 错误码
    ///   - message: String
    internal init(code: Code, message: String) {
        self.code = code
        self.message = message
    }
    
    /// 自定义错误信息
    /// - Parameters:
    ///   - code: 错误码
    ///   - message: 错误信息
    /// - Returns: ParchError
    internal static func customWith(_ message: String) -> PAError {
        return .init(code: .custom, message: message)
    }
    
    /// 发生了未知错误
    internal static var unknown: PAError {
        return .init(code: .custom, message: "发生了未知错误")
    }
    
    /// 用户取消了操作
    internal static var cancelled: PAError {
        return .init(code: .cancelled, message: "用户取消了操作")
    }
}

extension PAError.Code {
    
    /// 自定义错误
    internal static var custom: PAError.Code { .init(rawValue: 9001) }
    
    /// 用户取消了操作
    internal static var cancelled: PAError.Code { .init(rawValue: 90002) }
}

// MARK: - Error
extension PAError: LocalizedError {
    
    /// A localized message describing what error occurred.
    internal var errorDescription: String? {
        return message
    }
}

#endif
