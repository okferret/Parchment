//
//  BookEntity+Extends.swift
//  Parchment
//
//  Created by okferret on 2026/6/8.
//

import CoreData
import Foundation

extension BookEntity {
    
    /// Want
    struct Want: Hashable {
        internal let objectID: NSManagedObjectID
        internal let relativeUID: String
        internal let relativePath: String
        internal let filename: String
        internal let encoding: String.Encoding
        internal let cacheURL: URL
        internal let chapters: Array<ChapterEntity.Want>
        internal let pages: Array<PageEntity.Want>
        internal let marks: Array<MarkEntity.Want>
    }
}

extension BookEntity: Compatible {}
extension CompatibleWrapper where Base: BookEntity {
    
    /// String.Encoding
    internal var encoding: String.Encoding {
        get { .init(rawValue: UInt(base.encoding)) }
        set { base.encoding = Int64(newValue.rawValue) }
    }
    
    /// BookEntity.Want
    internal var want: BookEntity.Want {
        return .init(objectID:      base.objectID,
                     relativeUID:   base.relativeUID,
                     relativePath:  base.relativePath,
                     filename:      base.filename,
                     encoding:      base.hub.encoding,
                     cacheURL:      base.hub.cacheURL,
                     chapters:      base.chapters.sorted(by: { $0.offset < $1.offset }).map(\.hub.want),
                     pages:         base.pages.sorted(by: { $0.offset < $1.offset }).map(\.hub.want),
                     marks:         base.marks.sorted(by: { $0.offset < $1.offset }).map(\.hub.want))
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
