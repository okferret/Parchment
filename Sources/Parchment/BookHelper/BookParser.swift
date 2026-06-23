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
        // 注意：调用方（parseWith）已校验 fileURL 为合法文件，此处不再重复检查
        return try Uchardet.detect(fileURL).encoding
    }
    
    /// 解析内容
    /// - Parameters:
    ///   - fileURL: URL
    /// - Returns: BookEntity.Want
    internal static func parseWith(_ fileURL: URL, encoding: Optional<String.Encoding> = .none) async throws -> BookEntity.Want {
        return try await Task<BookEntity.Want, Error>(priority: .userInitiated) {
            return try BookParser.parseWith(fileURL, encoding: encoding)
        }.value
    }
    
    /// 解析内容
    /// - Parameters:
    ///   - fileURL: URL
    /// - Returns: BookEntity.Want
    internal static func parseWith(_ fileURL: URL, encoding: Optional<String.Encoding> = .none) throws -> BookEntity.Want {
        guard fileURL.isFileURL == true else { throw PAError.customWith("不支持当前存储路径") }
        var isDir: ObjCBool = .init(false)
        guard FileManager.default.fileExists(atPath: fileURL.path, isDirectory: &isDir) == true && isDir.boolValue == false else {
            throw PAError.customWith("不支持当前文件")
        }
        let relativeUID: String = BookHelper.relativeUID(for: fileURL)
        // 查询数据库 缓存
        let context: NSManagedObjectContext = BookHelper.newBackgroundContext()
        let bookWant: Optional<BookEntity.Want> = try? context.hub.performAndWait({ context in
            let freq: NSFetchRequest<BookEntity> = BookEntity.fetchRequest()
            freq.predicate = .init(format: "relativeUID == %@", relativeUID)
            freq.fetchLimit = 1
            let objs: Array<BookEntity> = try context.fetch(freq)
            return objs.first?.hub.want
        })
        if let bookWant = bookWant {
            // 校验缓存对应的磁盘文件是否仍存在：存在则直接复用缓存；
            // 若文件已被系统清理或误删，则删除失效记录并继续走重新解析流程。
            if FileManager.default.fileExists(atPath: bookWant.cacheURL.path) == true {
                return bookWant
            } else {
                try? context.hub.performAndWait { context in
                    let obj: BookEntity = try context.hub.fetchAny(for: bookWant.objectID)
                    context.delete(obj)
                    try context.hub.saveAndWait()
                }
            }
        }
        // 解析数据
        let filename: String = FileManager.default.displayName(atPath: fileURL.path)
        let newText: String
        if let encoding = encoding {
            do {
                newText = try .init(contentsOf: fileURL, encoding: encoding).hub.cleanText
            } catch {
                let encoding: String.Encoding = try BookParser.detectEncoding(for: fileURL)
                newText = try .init(contentsOf: fileURL, encoding: encoding).hub.cleanText
            }
        } else {
            let encoding: String.Encoding = try BookParser.detectEncoding(for: fileURL)
            newText = try .init(contentsOf: fileURL, encoding: encoding).hub.cleanText
        }
        guard let newData: Data = newText.data(using: .utf8) else {
            throw PAError.customWith("文件编码失败")
        }
        // 解析章节信息
        let elements = ChapterParser.parseWith(newText)
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
        // 保证原子性：数据库写入失败时回滚已写入的磁盘文件，避免产生无数据库记录的孤儿文件。
        do {
            let newWant: BookEntity.Want = try context.hub.performAndWait { context in
                let bookObj: BookEntity = .init(context: context)
                bookObj.relativeUID = relativeUID
                bookObj.relativePath = relativePath
                bookObj.hub.encoding = .utf8
                bookObj.filename = filename
                bookObj.chapters = []
                bookObj.marks = []
                bookObj.pages = []
                elements.forEach { (title, offset, length, sketchText) in
                    let chapter: ChapterEntity = .init(context: context)
                    chapter.title = title
                    chapter.offset = offset
                    chapter.length = length
                    chapter.sketchText = sketchText
                    bookObj.addToChapters(chapter)
                }
                try context.obtainPermanentIDs(for: [bookObj] + bookObj.chapters)
                try context.hub.saveAndWait()
                return bookObj.hub.want
            }
            return newWant
        } catch {
            // 数据库写入失败，清理刚写入的磁盘文件，保持磁盘与数据库一致
            try? FileManager.default.removeItem(at: fileURL)
            throw error
        }
    }
}

#endif
