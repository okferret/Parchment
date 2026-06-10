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
    struct Want: Hashable {
        internal let objectID: NSManagedObjectID
        internal let relativeUID: String
        internal let relativePath: String
        internal let filename: String
        internal let encoding: String.Encoding
        internal let cacheURL: URL
        internal let chapters: Array<NSManagedObjectID>
        internal let pages: Array<NSManagedObjectID>
        internal let marks: Array<NSManagedObjectID>
        private(set) var completedUnitCount: Int64
        internal let totalUnitCount: Int64
        internal let isReady: Bool
        
        /// completedUnitCount
        /// - Parameter completedUnitCount: Int64
        internal mutating func completedUnitCount(_ completedUnitCount: Int64) {
            self.completedUnitCount = completedUnitCount
        }
        
        /// page at index
        /// - Parameter index: Int64
        /// - Returns: Optional<PageEntity.Want>
        internal func pageAt(_ index: Optional<Int64>) -> Optional<PageEntity.Want> {
            do {
                let newIndex: Int = Int(index ?? completedUnitCount)
                guard (0 ..< pages.count).contains(newIndex) == true else { return .none }
                let context: NSManagedObjectContext = BookHelper.viewContext
                return try context.hub.performAndWait { context in
                    let freq: NSFetchRequest<PageEntity> = PageEntity.fetchRequest()
                    freq.predicate = .init(format: "book == %@ AND index == %ld", objectID, newIndex)
                    freq.fetchLimit = 1
                    return try context.fetch(freq).first?.hub.want
                }
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
        return .init(objectID:               base.objectID,
                     relativeUID:           base.relativeUID,
                     relativePath:          base.relativePath,
                     filename:              base.filename,
                     encoding:              base.hub.encoding,
                     cacheURL:              base.hub.cacheURL,
                     chapters:              base.chapters.map(\.objectID),
                     pages:                 base.pages.map(\.objectID),
                     marks:                 base.marks.map(\.objectID),
                     completedUnitCount:    base.completedUnitCount,
                     totalUnitCount:        base.totalUnitCount,
                     isReady:               base.isReady)
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
