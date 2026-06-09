//
//  URL+Extends.swift
//  Parchment
//
//  Created by okferret on 2026/6/9.
//

import Foundation

extension URL {
    
    /// URL
    internal static let dirURL: URL = {
        let dirURL: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let newURL: URL
        if #available(iOS 16.0, *) {
            newURL = dirURL.appending(path: "Parchment", directoryHint: .isDirectory)
        } else {
            newURL = dirURL.appendingPathComponent("Parchment", isDirectory: true)
        }
        var isDir: ObjCBool = .init(false)
        if FileManager.default.fileExists(atPath: newURL.path, isDirectory: &isDir) == true && isDir.boolValue == false {
            return newURL
        } else {
            try? FileManager.default.removeItem(at: newURL)
            try? FileManager.default.createDirectory(at: newURL, withIntermediateDirectories: true)
            return newURL
        }
    }()
}
