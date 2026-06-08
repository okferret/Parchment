//
//  ChapterEntity+Extends.swift
//  Parchment
//
//  Created by okferret on 2026/6/8.
//

import CoreData
import Foundation

extension ChapterEntity {
    
    /// Want
    struct Want: Hashable {
        internal let objectID: NSManagedObjectID
        internal let title: String
        internal let sketchText: String
        internal let offset: Int64
        internal let length: Int64
        internal let book: NSManagedObjectID
    }
}

extension ChapterEntity: Compatible {}
extension CompatibleWrapper where Base: ChapterEntity {
    
    /// ChapterEntity.Want
    internal var want: ChapterEntity.Want {
        return .init(objectID:      base.objectID,
                     title:         base.title,
                     sketchText:    base.sketchText,
                     offset:        base.offset,
                     length:        base.length,
                     book:          base.book.objectID)
    }
}
