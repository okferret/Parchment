//
//  MarkEntity+Extends.swift
//  Parchment
//
//  Created by okferret on 2026/6/8.
//

import CoreData
import Foundation

extension MarkEntity {
    
    /// Want
    struct Want: Hashable {
        internal let objectID: NSManagedObjectID
        internal let sketchText: String
        internal let offset: Int64
        internal let length: Int64
        internal let createdAt: Date
        internal let book: NSManagedObjectID
    }
}

extension CompatibleWrapper where Base: MarkEntity {
    
    /// MarkEntity.Want 
    internal var want: MarkEntity.Want {
        return .init(objectID:      base.objectID,
                     sketchText:    base.sketchText,
                     offset:        base.offset,
                     length:        base.length,
                     createdAt:     base.createdAt,
                     book:          base.book.objectID)
    }
}
