//
//  FileManager+Extends.swift
//  Parchment
//
//  Created by okferret on 2026/6/3.
//

#if canImport(UIKit)
import UIKit
import CryptoKit

extension CompatibleWrapper where Base: FileManager {
    
    /// 获取相对路径
    /// - Parameter fileURL: URL
    /// - Returns: String
    internal func relativePath(for fileURL: URL) -> String {
        if fileURL.isFileURL == true, let startIndex: String.Index = fileURL.absoluteString.range(of: NSHomeDirectory())?.upperBound {
            return String(fileURL.absoluteString[startIndex...])
        } else {
            return fileURL.absoluteString
        }
    }
    
    /// fileExists
    /// - Parameters:
    ///   - url: URL
    ///   - isDirectory: Optional<UnsafeMutablePointer<ObjCBool>>
    /// - Returns: Bool
    internal func fileExists(atURL url: URL, isDirectory: Optional<UnsafeMutablePointer<ObjCBool>>) -> Bool {
        return base.fileExists(atPath: url.path, isDirectory: isDirectory)
    }
}

extension CompatibleWrapper where Base: FileManager {
    
    /// 计算Hash
    /// - Parameters:
    ///   - fileURL: URL
    ///   - hashType: HashType
    /// - Returns: String
    internal func hashWith(_ fileURL: URL, hashType: HashType) throws -> String {
#if DEBUG
        let start = CACurrentMediaTime()
        defer {
            let end = CACurrentMediaTime()
            print("计算哈希耗时 =>", end - start)
        }
#endif
        var isDir: ObjCBool = .init(false)
        guard FileManager.default.hub.fileExists(atURL: fileURL, isDirectory: &isDir) == true else {
            throw PAError.customWith("当前文件不存在")
        }
        guard isDir.boolValue == false else {
            throw PAError.customWith("该方法不支持文件夹类型")
        }
        // 初始化 哈希计算器
        var hasher: any HashFunction
        switch hashType {
        case .MD5:
            hasher = Insecure.MD5()
        case .SHA1:
            hasher = Insecure.SHA1()
        case .SHA2(let variant) where variant == .SHA2_256:
            hasher = SHA256()
        case .SHA2(let variant) where variant == .SHA2_384:
            hasher = SHA384()
        case .SHA2(let variant) where variant == .SHA2_512:
            hasher = SHA512()
        default:
            throw PAError.customWith("暂不支持其它变体")
        }
        // 打开文件句柄
        let fileHandle: FileHandle = try .init(forReadingFrom: fileURL)
        // 及时关闭句柄
        defer { try? fileHandle.close() }
        // 分块读取文件 (推荐 1MB 每块)
        let chunkUnitCount = 1024 * 1024 // 1MB
        while autoreleasepool(invoking: {
            let newData: Optional<Data>
            if #available(iOS 13.4, *) {
                newData = try? fileHandle.read(upToCount: chunkUnitCount)
            } else {
                newData = fileHandle.readData(ofLength: chunkUnitCount)
            }
            guard let chunkData = newData, chunkData.isEmpty == false else {
                return false // 读取完毕或读取失败
            }
            // 更新哈希计算
            hasher.update(data: chunkData)
            return true
        }) {}
        // 完成计算并返回十六进制字符串
        return hasher.finalize().toHex()
    }
    
    /// 计算MD5
    /// - Parameter fileURL: 文件存储位置
    /// - Returns: String
    internal func md5(atURL fileURL: URL) throws -> String {
        return try base.hub.hashWith(fileURL, hashType: .MD5)
    }
    
    /// 计算sha1
    /// - Parameter fileURL: URL
    /// - Returns: String
    internal func sha1(atURL fileURL: URL) throws -> String {
        return try base.hub.hashWith(fileURL, hashType: .SHA1)
    }
}



#endif
