//
//  PageEntity+Extends.swift
//  Parchment
//
//  Created by okferret on 2026/6/8.
//

import CoreData
import Foundation

extension PageEntity {
    
    /// Want
    struct Want: Hashable {
        internal let objectID: NSManagedObjectID
        internal let text: String
        internal let sketchText: String
        internal let index: Int64
        internal let offset: Int64
        internal let length: Int64
        internal let isTruncated: Bool
        internal let book: NSManagedObjectID
    }
}

extension PageEntity: Compatible {}
extension CompatibleWrapper where Base: PageEntity {
    
    /// PageEntity.Want
    internal var want: PageEntity.Want {
        return .init(objectID:      base.objectID,
                     text:          base.text,
                     sketchText:    base.sketchText,
                     index:         base.index,
                     offset:        base.offset,
                     length:        base.length,
                     isTruncated:   base.isTruncated,
                     book:          base.objectID)
    }
}
