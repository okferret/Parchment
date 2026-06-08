//
//  TXTParser.swift
//  Parchment
//
//  Created by okferret on 2026/6/5.
//

#if canImport(UIKit)

import UIKit
import Uchardet
import CoreData

/// BookParser
class BookParser: NSObject {
    
}

extension BookParser {
    
    /// 探测编码格式
    /// - Parameter fileURL: URL
    /// - Returns: String.Encoding
    private static func detectEncoding(for fileURL: URL) throws -> String.Encoding {
        guard fileURL.isFileURL == true else { throw PAError.customWith("不支持当前存储路径") }
        var isDir: ObjCBool = .init(false)
        guard FileManager.default.fileExists(atPath: fileURL.path, isDirectory: &isDir) == true && isDir.boolValue == false else {
            throw PAError.customWith("不支持当前文件")
        }
        return try Uchardet.detect(fileURL).encoding
    }
    
    /// 解析内容
    /// - Parameters:
    ///   - fileURL: URL
    /// - Returns: BookEntity.Want
    internal static func parseWith(_ fileURL: URL) throws -> BookEntity.Want {
        guard fileURL.isFileURL == true else { throw PAError.customWith("不支持当前存储路径") }
        var isDir: ObjCBool = .init(false)
        guard FileManager.default.fileExists(atPath: fileURL.path, isDirectory: &isDir) == true && isDir.boolValue == false else {
            throw PAError.customWith("不支持当前文件")
        }
        let relativeUID: String = BookParser.relativeUID(for: fileURL)
        // 查询数据库
        let context: NSManagedObjectContext = BookHelper.newBackgroundContext()
//        if let newWant: BookEntity.Want = try? context.hub.performAndWait({ context in
//            let freq: NSFetchRequest<BookEntity> = BookEntity.fetchRequest()
//            freq.predicate = .init(format: "relativeUID == %@", relativeUID)
//            freq.fetchLimit = 1
//            freq.resultType = .managedObjectResultType
//            return try context.fetch(freq).first?.hub.want
//        }) {
//            return newWant
//        }
        try? context.hub.performAndWait({ context in
            let freq: NSFetchRequest<BookEntity> = BookEntity.fetchRequest()
            freq.predicate = .init(format: "relativeUID == %@", relativeUID)
            freq.fetchLimit = 1
            freq.resultType = .managedObjectResultType
            let objs = try context.fetch(freq)
            objs.forEach { context.delete($0) }
            try context.hub.saveAndWait()
        })
        // 解析数据
        let filename: String = FileManager.default.displayName(atPath: fileURL.path)
        let encoding: String.Encoding = try BookParser.detectEncoding(for: fileURL)
        // 预处理
        var newText: String = try .init(contentsOf: fileURL, encoding: encoding)
        newText = newText
            .components(separatedBy: .newlines)
            .map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) })
            .filter({ $0.hub.isBlank == false })
            .joined(separator: "\n")
        guard let newData: Data = newText.data(using: .utf8) else {
            throw PAError.customWith("文件编码失败")
        }
        
        // 解析章节信息
        let elements = ChapterParser.parse(text: newText)
        // 准备参数
        let relativePath: String = "\(relativeUID)/\(filename)"
        let fileURL: URL
        if #available(iOS 16.0, *) {
            fileURL = Configuration.dirURL.appending(path: relativePath, directoryHint: .notDirectory)
        } else {
            fileURL = Configuration.dirURL.appendingPathComponent(relativePath, isDirectory: false)
        }
        // 写入磁盘
        try? FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? FileManager.default.removeItem(at: fileURL)
        try newData.write(to: fileURL, options: [.atomic])
        // 写入数据库
        let newWant: BookEntity.Want = try context.hub.performAndWait { context in
            let book: BookEntity = .init(context: context)
            book.relativeUID = relativeUID
            book.relativePath = relativePath
            book.hub.encoding = .utf8
            book.filename = filename
            book.chapters = []
            book.marks = []
            book.pages = []
            elements.forEach { (title, offset, length, sketchText) in
                let chapter: ChapterEntity = .init(context: context)
                chapter.title = title
                chapter.offset = offset
                chapter.length = length
                chapter.sketchText = sketchText
                book.addToChapters(chapter)
            }
            try context.obtainPermanentIDs(for: [book] + book.chapters)
            try context.hub.saveAndWait()
            return book.hub.want
        }
        return newWant
    }
    
    /// 计算关联ID
    /// - Parameter fileURL: URL
    /// - Returns: String
    private static func relativeUID(for fileURL: URL) -> String {
        let relativePath: String = FileManager.default.hub.relativePath(for: fileURL)
        return relativePath.hub.md5
    }
}


#endif
