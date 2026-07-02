//
//  ParchmentViewController+Extends.swift
//  Parchment
//
//  Created by okferret on 2026/6/3.
//

#if canImport(UIKit)

import UIKit
import Uchardet

extension ParchmentViewController {
    
    /// 是否支持当前文件
    /// - Parameter fileURL: URL
    /// - Returns: Bool
    /// - Returns: Bool
    public static func isReadable(atURL fileURL: URL) -> Bool {
        guard fileURL.isFileURL == true else { return false }
        guard ["txt"].contains(fileURL.pathExtension.lowercased()) == true else { return false }
        var isDir: ObjCBool = .init(false)
        guard FileManager.default.fileExists(atPath: fileURL.path, isDirectory: &isDir) == true, isDir.boolValue == false else {
            return false
        }
        do {
            _ = try Uchardet.detect(fileURL).encoding
            return true
        } catch {
            return false
        }
    }
}

#endif
