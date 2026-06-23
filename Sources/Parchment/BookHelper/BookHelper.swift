//
//  BookHelper.swift
//  Parchment
//
//  Created by okferret on 2026/6/5.
//

#if canImport(UIKit) && canImport(CoreData)

import UIKit
import CoreData

/// BookHelper
public class BookHelper: NSObject {
    
    //  MARK: - 公开属性
    
    /// 单例对象
    internal static let shared: BookHelper = .init()
    
    /// NSManagedObjectContext
    internal static var viewContext: NSManagedObjectContext {
        return BookHelper.shared.container.viewContext
    }
    
    /// UIEdgeInsets
    public static var safeAreaInsets: UIEdgeInsets {
        if Thread.isMainThread == true {
            if let keyWindow = UIApplication.shared.hub.keyWindow {
                return .init(top:       max(keyWindow.safeAreaInsets.top, 47.0),
                             left:      max(keyWindow.safeAreaInsets.left, 16.0),
                             bottom:    max(keyWindow.safeAreaInsets.bottom, 34.0),
                             right:     max(keyWindow.safeAreaInsets.right, 16.0))
            } else {
                return .init(top: 47.0, left: 16.0, bottom: 34.0, right: 16.0)
            }
        } else {
            return DispatchQueue.main.sync { BookHelper.safeAreaInsets }
        }
    }
    
    //  MARK: - 私有属性
    
    /// URL
    private static let storeURL: URL = {
        let fileURL: URL
        if #available(iOS 16.0, *) {
            fileURL = URL.dirURL.appending(component: "Database/Parchment.sqlite", directoryHint: .notDirectory)
        } else {
            fileURL = URL.dirURL.appendingPathComponent("Database/Parchment.sqlite", isDirectory: false)
        }
        try? FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        return fileURL
    }()

    /// NSPersistentContainer
    internal let container: NSPersistentContainer = {
        // SQLite 优化选项
        let dict: Dictionary<String, String> = [
            "journal_mode": "WAL",  // Write-Ahead Logging 模式
            "cache_size": "2000",   // 缓存大小
            "synchronous": "NORMAL" // 可选：平衡性能与安全
        ]
        let option: NSPersistentStoreDescription = .init(url: BookHelper.storeURL)
        option.shouldAddStoreAsynchronously = false
        option.shouldMigrateStoreAutomatically = true
        option.shouldInferMappingModelAutomatically = true
        option.setOption(dict as NSDictionary, forKey: NSSQLitePragmasOption)
        option.type = NSSQLiteStoreType
        // 从 Swift Package Bundle 中加载 Core Data 模型
        guard let modelURL = Bundle.module.url(forResource: "Parchment", withExtension: "momd"),
              let model = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("无法从 Bundle 加载 Core Data 模型: Parchment.momd")
        }
        let container: NSPersistentContainer = .init(name: "Parchment", managedObjectModel: model)
        container.persistentStoreDescriptions = [option]
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        let semaphore = DispatchSemaphore(value: 0)
        container.loadPersistentStores { (_, error) in
            defer { semaphore.signal() }
            if let error = error {
                #if DEBUG
                // 调试期直接崩溃，便于第一时间发现存储加载失败（如模型不兼容、磁盘损坏）
                fatalError("Core Data load error: \(error)")
                #else
                print("Core Data load error: \(error)")
                #endif
            }
        }
        semaphore.wait()
        return container
    }()
}

extension BookHelper {
    
    /// newBackgroundContext
    /// - Returns: NSManagedObjectContext
    public static func newBackgroundContext() -> NSManagedObjectContext {
        let context: NSManagedObjectContext = .init(concurrencyType: .privateQueueConcurrencyType)
        context.parent = BookHelper.shared.container.viewContext
        context.automaticallyMergesChangesFromParent = true
        context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        return context
    }
    
    /// performAndWait
    /// - Parameter block: @escaping (_ context: NSManagedObjectContext) -> Void
    public static func performAndWait<T>(_ block: @escaping (_ context: NSManagedObjectContext) throws -> T) throws -> T {
        return try BookHelper.newBackgroundContext().hub.performAndWait { context in
            return try block(context)
        }
    }
    
    /// relativeUID for
    /// - Parameter fileURL: URL
    /// - Returns: String
    public static func relativeUID(for fileURL: URL) -> String {
        return FileManager.default.hub.relativePath(for: fileURL).hub.md5
    }
    
    /// 解析内容
    /// - Parameters:
    ///   - fileURL: URL
    /// - Returns: BookEntity.Want
    public static func parseWith(_ fileURL: URL, encoding: Optional<String.Encoding> = .none) throws -> BookEntity.Want {
        return try BookParser.parseWith(fileURL, encoding: encoding)
    }
    
    /// cleanWith
    /// - Parameter fileURL: URL
    public static func cleanWith(_ fileURL: URL) {
        Task<Void, Never>(priority: .userInitiated) {
            do {
                let relativeUID: String = BookHelper.relativeUID(for: fileURL)
                let context: NSManagedObjectContext = BookHelper.newBackgroundContext()
                try context.hub.performAndWait { context in
                    let freq: NSFetchRequest<BookEntity> = BookEntity.fetchRequest()
                    freq.predicate = .init(format: "relativeUID == %@", relativeUID)
                    let objs: Array<BookEntity> = try context.fetch(freq)
                    objs.forEach { context.delete($0) }
                    try context.hub.saveAndWait()
                }
            } catch {
                print("BookHelper.cleanWith error: \(error)")
            }
        }
    }
    
    /// clean all
    public static func clearAll() {
        Task<Void, Never>(priority: .userInitiated) {
            do {
                let context: NSManagedObjectContext = BookHelper.newBackgroundContext()
                try context.hub.performAndWait { context in
                    let freq: NSFetchRequest<BookEntity> = BookEntity.fetchRequest()
                    let objs: Array<BookEntity> = try context.fetch(freq)
                    objs.forEach { context.delete($0) }
                    try context.hub.saveAndWait()
                }
            } catch {
                print("BookHelper.clearAll error: \(error)")
            }
        }
    }
}

extension BookHelper {
    
    /// parseWith
    /// - Parameters:
    ///   - fileURL: URL
    ///   - encoding: Optional<String.Encoding>
    ///   - safeArea: CGSize
    ///   - textAttributes: Dictionary<NSAttributedString.Key, Any>
    /// - Returns: BookEntity.Want
    internal func parseWith(_ fileURL: URL,
                            encoding: Optional<String.Encoding> = .none,
                            safeArea: CGSize,
                            textAttributes: Dictionary<NSAttributedString.Key, Any>,
                            useCached: Bool = true) async throws -> BookEntity.Want {
        return try await Task<BookEntity.Want, Error>(priority: .userInitiated) {
            let bookWant: BookEntity.Want = try await BookParser.parseWith(fileURL, encoding: encoding)
            if useCached == false || bookWant.isReady == false {
                return try paginateWith(bookWant, safeArea: safeArea, textAttributes: textAttributes)
            } else {
                return bookWant
            }
        }.value
    }
    
    /// parseWith
    /// - Parameters:
    ///   - fileURL: URL
    ///   - encoding: Optional<String.Encoding>
    ///   - safeArea: CGSize
    ///   - textAttributes: Dictionary<NSAttributedString.Key, Any>
    ///   - useCached: Bool
    /// - Returns: BookEntity.Want
    internal static func parseWith(_ fileURL: URL,
                                   encoding: Optional<String.Encoding> = .none,
                                   safeArea: CGSize,
                                   textAttributes: Dictionary<NSAttributedString.Key, Any>,
                                   useCached: Bool = true) async throws -> BookEntity.Want {
       return try await BookHelper.shared.parseWith(fileURL, encoding: encoding, safeArea: safeArea, textAttributes: textAttributes, useCached: useCached)
    }
    
    /// paginateWith
    /// - Parameters:
    ///   - bookWant: BookEntity.Want
    ///   - safeArea: CGSize
    ///   - textAttributes: Dictionary<NSAttributedString.Key, Any>
    /// - Returns: Entity.Want
    public static func paginateWith(_ bookWant: BookEntity.Want,
                                    safeArea: CGSize,
                                    textAttributes: Dictionary<NSAttributedString.Key, Any>) throws -> BookEntity.Want {
        return try BookHelper.shared.paginateWith(bookWant, safeArea: safeArea, textAttributes: textAttributes)
    }
    
    /// paginateWith
    /// - Parameters:
    ///   - bookWant: BookEntity.Want
    ///   - safeAreaInsets: UIEdgeInsets
    ///   - textAttributes: BookEntity.Want
    /// - Returns: Dictionary<NSAttributedString.Key, Any>
    private func paginateWith(_ bookWant: BookEntity.Want,
                              safeArea: CGSize,
                              textAttributes: Dictionary<NSAttributedString.Key, Any>) throws -> BookEntity.Want {
        // 获取当前偏移量
        let offset: Int64
        if let newWant: PageEntity.Want = bookWant.pageAt(bookWant.currentIndex) {
            offset = newWant.offset
        } else {
            offset = 0
        }
        // 读取数据
        let newText: String = try .init(contentsOf: bookWant.cacheURL, encoding: bookWant.encoding)
        // 执行分页
        let newArray = TextPaginator.paginate(text: newText, safeArea: safeArea, textAttributes: textAttributes)
        // 同步数据库
        let context: NSManagedObjectContext = BookHelper.newBackgroundContext()
        let newWant: BookEntity.Want = try context.hub.performAndWait { context in
            let bookObj: BookEntity = try context.hub.fetchAny(for: bookWant.objectID)
            // 先删除旧的 pages，但不立即保存，与新数据一起原子提交
            bookObj.pages.forEach { context.delete($0) }
            bookObj.pages = []
            bookObj.isReady = false
            let enumerated = newArray.enumerated()
            enumerated.forEach { (index, element) in
                let obj: PageEntity = .init(context: context)
                obj.index   = Int64(index)
                obj.offset  = element.offset
                obj.length  = element.length
                obj.isTruncated = element.isTruncated
                bookObj.addToPages(obj)
            }
            bookObj.isReady = true
            bookObj.totalUnitCount = Int64(newArray.count)
            // 使用枚举索引（页码）而非字节偏移，与 pageAt(_:) 的数组下标语义一致。
            // 查找首个 offset >= 原阅读字节偏移的新页作为恢复位置；
            // 若全部新页 offset 都 < offset（原位置接近全书末尾），则回退到最后一页，
            // 而非跳回书首（index 0），避免重排后丢失阅读进度。
            if let matchedIndex = enumerated.first(where: { $0.element.offset >= offset })?.0 {
                bookObj.currentIndex = Int64(matchedIndex)
            } else {
                bookObj.currentIndex = Int64(max(0, newArray.count - 1))
            }
            try context.obtainPermanentIDs(for: Array(bookObj.pages))
            try context.hub.saveAndWait()
            return bookObj.hub.want
        }
        // 返回新数据
        return newWant
    }
}

extension BookHelper {
    
    /// BookHelper.progressNotification
    internal static let progressNotification: Notification.Name  = .init(rawValue: "BookHelper.progressNotification")
    
}



#endif
