//
//  BookEntity+Extends.swift
//  Parchment
//
//  Created by okferret on 2026/6/8.
//

import CoreData
import Foundation

extension BookEntity {
    
    /// prepareForDeletion
    public override func prepareForDeletion() {
        defer { super.prepareForDeletion() }
        // 删除数据
        if FileManager.default.fileExists(atPath: hub.cacheURL.path) == true {
            try? FileManager.default.removeItem(at: hub.cacheURL)
        }
    }
}

extension BookEntity {
    
    /// Want
    class Want: NSObject {
        internal let objectID: NSManagedObjectID
        internal let relativeUID: String
        internal let relativePath: String
        internal let filename: String
        internal let encoding: String.Encoding
        internal let cacheURL: URL
        private(set) var chapters: Set<NSManagedObjectID>
        private(set) var pages: Set<NSManagedObjectID>
        private(set) var marks: Set<NSManagedObjectID>
        private(set) var currentIndex: Int64
        private(set) var totalUnitCount: Int64
        private(set) var isReady: Bool
        /// 构造函数
        internal init(objectID: NSManagedObjectID,
                      relativeUID: String,
                      relativePath: String,
                      filename: String,
                      encoding: String.Encoding,
                      cacheURL: URL,
                      chapters: Set<NSManagedObjectID>,
                      pages: Set<NSManagedObjectID>,
                      marks: Set<NSManagedObjectID>,
                      currentIndex: Int64,
                      totalUnitCount: Int64,
                      isReady: Bool) {
            self.objectID = objectID
            self.relativeUID = relativeUID
            self.relativePath = relativePath
            self.filename = filename
            self.encoding = encoding
            self.cacheURL = cacheURL
            self.chapters = chapters
            self.pages = pages
            self.marks = marks
            self.currentIndex = currentIndex
            self.totalUnitCount = totalUnitCount
            self.isReady = isReady
            super.init()
        }
        
        /// currentIndex
        /// - Parameter currentIndex: Int64
        internal func currentIndex(_ currentIndex: Int64) {
            self.currentIndex = currentIndex
        }
        
        /// remakeWith
        /// - Parameter newWant: BookEntity.Want
        internal func remakeWith(_ newWant: BookEntity.Want) {
            self.chapters = newWant.chapters
            self.pages = newWant.pages
            self.marks = newWant.marks
            self.currentIndex = newWant.currentIndex
            self.totalUnitCount = newWant.totalUnitCount
            self.isReady = newWant.isReady
        }
        
        /// page at index
        /// - Parameter index: Int64
        /// - Returns: Optional<PageEntity.Want>
        internal func pageAt(_ index: Optional<Int64>, context: NSManagedObjectContext = BookHelper.viewContext) -> Optional<PageEntity.Want> {
            do {
                let newIndex: Int = Int(index ?? currentIndex)
                guard (0 ..< pages.count).contains(newIndex) == true else { return .none }
                return try context.hub.performAndWait { context in
                    let freq: NSFetchRequest<PageEntity> = PageEntity.fetchRequest()
                    freq.predicate = .init(format: "book == %@ AND index == %lld", objectID, newIndex)
                    freq.fetchLimit = 1
                    return try context.fetch(freq).first?.hub.want
                }
            } catch {
                return .none
            }
        }
        
        /// 获取章节信息
        /// - Parameters:
        ///   - pageIndex: Optional<Int64>
        ///   - context: NSManagedObjectContext
        /// - Returns: Optional<ChapterEntity.Want>
        internal func chapterAt(_ pageIndex: Optional<Int64>, context: NSManagedObjectContext = BookHelper.viewContext) -> Optional<ChapterEntity.Want> {
            do {
                let newIndex: Int = Int(pageIndex ?? currentIndex)
                let newWant: Optional<ChapterEntity.Want> = try context.hub.performAndWait { context in
                    // 查询单页信息，仅获取 offset 与 length
                    let pfreq: NSFetchRequest<PageEntity> = PageEntity.fetchRequest()
                    pfreq.predicate = .init(format: "book == %@ AND index == %lld", objectID, newIndex)
                    pfreq.fetchLimit = 1
                    pfreq.propertiesToFetch = [#keyPath(PageEntity.offset), #keyPath(PageEntity.length)]
                    guard let page = try context.fetch(pfreq).first else { return .none }
                    let pageOffset = page.offset
                    let pageEnd    = page.offset + page.length - 1
                    // 页面与章节范围有交集的条件：chapterOffset <= pageEnd && chapterEnd >= pageOffset
                    // 数据库层面用 offset <= pageEnd 缩小候选集，按 offset 降序排列
                    // NSPredicate 不支持字段间算术，chapterEnd >= pageOffset 在内存中验证
                    let freq: NSFetchRequest<ChapterEntity> = ChapterEntity.fetchRequest()
                    freq.predicate = .init(format: "book == %@ AND offset <= %lld", objectID, pageEnd)
                    freq.sortDescriptors = [.init(key: #keyPath(ChapterEntity.offset), ascending: false)]
                    let objs: Array<ChapterEntity> = try context.fetch(freq)
                    // 从最近章节起逐一验证：章节末尾 >= 页面起始（即存在交集）
                    return objs.first { obj in
                        obj.offset + obj.length - 1 >= pageOffset
                    }?.hub.want
                }
                return newWant
            } catch {
                return .none
            }
        }
    }
}

extension CompatibleWrapper where Base: BookEntity {
    
    /// String.Encoding
    internal var encoding: String.Encoding {
        get { .init(rawValue: UInt(base.encoding)) }
        set { base.encoding = Int64(newValue.rawValue) }
    }
    
    /// BookEntity.Want
    internal var want: BookEntity.Want {
        return .init(objectID:          base.objectID,
                     relativeUID:       base.relativeUID,
                     relativePath:      base.relativePath,
                     filename:          base.filename,
                     encoding:          base.hub.encoding,
                     cacheURL:          base.hub.cacheURL,
                     chapters:          Set(base.chapters.map(\.objectID)),
                     pages:             Set(base.pages.map(\.objectID)),
                     marks:             Set(base.marks.map(\.objectID)),
                     currentIndex:      base.currentIndex,
                     totalUnitCount:    base.totalUnitCount,
                     isReady:           base.isReady)
    }
    
    /// URL
    internal var cacheURL: URL {
        let cacheURL: URL
        if #available(iOS 16.0, *) {
            cacheURL = Configuration.dirURL.appending(path: base.relativePath, directoryHint: .notDirectory)
        } else {
            cacheURL = Configuration.dirURL.appendingPathComponent(base.relativePath, isDirectory: false)
        }
        return cacheURL
    }
}
