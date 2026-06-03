//
//  ParchmentViewController+Extends.swift
//  Parchment
//
//  Created by okferret on 2026/6/3.
//

#if canImport(UIKit)

import UIKit

extension ParchmentViewController {
    
    /// 是否支持当前文件
    /// - Parameter fileURL: URL
    /// - Returns: Bool
    /// - Returns: Bool
    public static func isReadable(atURL fileURL: URL) -> Bool {
        guard fileURL.isFileURL == true else { return false }
        guard ["txt"].contains(fileURL.pathExtension.lowercased()) == true else { return false }
        var isDir: ObjCBool = .init(false)
        if FileManager.default.fileExists(atPath: fileURL.path, isDirectory: &isDir) == true, isDir.boolValue == false {
            return true
        } else {
            return false
        }
    }
}

#endif
