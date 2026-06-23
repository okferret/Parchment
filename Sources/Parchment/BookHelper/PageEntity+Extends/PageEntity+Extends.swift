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
    /// Want
    struct Want: Hashable {
        internal let objectID: NSManagedObjectID
        internal let index: Int64
        internal let offset: Int64
        internal let length: Int64
        internal let isTruncated: Bool
        internal let book: NSManagedObjectID
        /// 书籍正文缓存文件地址（UTF-8 编码全文）
        /// 页文本不再冗余存储于数据库，改为按 `offset`/`length` 从该文件按字节切片读取。
        internal let cacheURL: URL
        
        /// 页文本（按需从缓存文件读取）
        ///
        /// `offset`/`length` 为分页时产出的 **UTF-8 字节偏移**，与 `cacheURL`
        /// 中以 UTF-8 编码写入的全文完全对齐，故可直接按字节范围切片还原页内容。
        ///
        /// ⚠️ 每次访问都会发生一次文件读取，调用方若需多次使用应先取出到局部变量。
        internal var text: String {
            guard length > 0 else { return "" }
            do {
                let handle: FileHandle = try .init(forReadingFrom: cacheURL)
                defer { handle.closeFile() }
                handle.seek(toFileOffset: UInt64(offset))
                let data: Data = handle.readData(ofLength: Int(length))
                return String(decoding: data, as: UTF8.self)
            } catch {
                return ""
            }
        }
    }
}

extension CompatibleWrapper where Base: PageEntity {
    
    /// PageEntity.Want
    internal var want: PageEntity.Want {
        return .init(objectID:      base.objectID,
                     index:         base.index,
                     offset:        base.offset,
                     length:        base.length,
                     isTruncated:   base.isTruncated,
                     book:          base.book.objectID,
                     cacheURL:      base.book.hub.cacheURL)
    }
}
