//
//  CryptoKit+Extends.swift
//  Parchment
//
//  Created by okferret on 2026/6/10.
//

import Foundation
import CryptoKit

/// Insecure
extension Insecure {
    /// 变体
    enum Variant {
        case SHA1
        case MD5
    }
}

/// HMAC<Insecure.SHA1>
extension HMAC<Insecure.SHA1>.MAC {
    
    /// to hex string
    /// - Returns: String
    internal func toHex() -> String {
        return self.map { String(format: "%02x", $0) }.joined()
    }
    
    /// base64EncodedString
    internal func toBase64() -> String {
        return Data(self).base64EncodedString()
    }
}

/// HMAC<Insecure.MD5>
extension HMAC<Insecure.MD5>.MAC {
    
    /// to hex string
    /// - Returns: String
    internal func toHex() -> String {
        return self.map { String(format: "%02x", $0) }.joined()
    }
    
    /// base64EncodedString
    internal func toBase64() -> String {
        return Data(self).base64EncodedString()
    }
}

/// Digest
extension Digest {
    
    /// to hex string
    /// - Returns: String
    internal func toHex() -> String {
        return self.map { String(format: "%02x", $0) }.joined()
    }
    
    /// base64EncodedString
    internal func toBase64() -> String {
        return Data(self).base64EncodedString()
    }
}

/// SHA2
struct SHA2 {
    /// 变体
    enum Variant {
        case SHA2_256
        case SHA2_384
        case SHA2_512
    }
}

/// SHA3
struct SHA3 {
    /// 变体
    enum Variant {
        case SHA3_256
        case SHA3_384
        case SHA3_512
    }
}

enum HashType {
    case MD5
    case SHA1
    case SHA2(_ variant: SHA2.Variant)
}
