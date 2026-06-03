//
//  FileManager+Extends.swift
//  Parchment
//
//  Created by okferret on 2026/6/3.
//

#if canImport(Foundation)
import Foundation

extension FileManager: Compatible {}
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
}


#endif
