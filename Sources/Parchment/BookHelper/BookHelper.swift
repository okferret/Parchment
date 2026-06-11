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
    internal static var safeAreaInsets: UIEdgeInsets {
        guard let keyWindow = UIApplication.shared.hub.keyWindow else { return .zero }
        let safeAreaInsets: UIEdgeInsets = .init(top:       max(keyWindow.safeAreaInsets.top, 32.0),
                                                 left:      max(keyWindow.safeAreaInsets.left, 16.0),
                                                 bottom:    max(keyWindow.safeAreaInsets.bottom, 32.0),
                                                 right:     max(keyWindow.safeAreaInsets.right, 16.0))
        return safeAreaInsets
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
                print("Core Data load error: \(error)")
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
    public static func performAndWait(_ block: @escaping (_ context: NSManagedObjectContext) -> Void) {
        block(BookHelper.newBackgroundContext())
    }
    
    /// cleanWith
    /// - Parameter fileURL: URL
    public static func cleanWith(_ fileURL: URL) {
        Task(priority: .userInitiated) {
            let relativeUID: String = FileManager.default.hub.relativePath(for: fileURL).hub.md5
            let context: NSManagedObjectContext = BookHelper.newBackgroundContext()
            try context.hub.performAndWait { context in
                let freq: NSFetchRequest<BookEntity> = BookEntity.fetchRequest()
                freq.predicate = .init(format: "relativeUID == %@", relativeUID)
                let objs: Array<BookEntity> = try context.fetch(freq)
                objs.forEach { context.delete($0) }
                try context.hub.saveAndWait()
            }
        }
    }
    
    /// clean all
    internal static func clearnAll() {
        Task(priority: .userInitiated) {
            let context: NSManagedObjectContext = BookHelper.newBackgroundContext()
            try context.hub.performAndWait { context in
                let freq: NSFetchRequest<BookEntity> = BookEntity.fetchRequest()
                let objs: Array<BookEntity> = try context.fetch(freq)
                objs.forEach { context.delete($0) }
                try context.hub.saveAndWait()
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
        let bookWant: BookEntity.Want = try await BookParser.parseWith(fileURL, encoding: encoding)
        if useCached == false || bookWant.isReady == false {
            return try await paginateWith(bookWant, safeArea: safeArea, textAttributes: textAttributes)
        } else {
            return bookWant
        }
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
    ///   - safeAreaInsets: UIEdgeInsets
    ///   - textAttributes: BookEntity.Want
    /// - Returns: Dictionary<NSAttributedString.Key, Any>
    private func paginateWith(_ bookWant: BookEntity.Want,
                              safeArea: CGSize,
                              textAttributes: Dictionary<NSAttributedString.Key, Any>) async throws -> BookEntity.Want {
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
                obj.text    = element.text
                obj.isTruncated = element.isTruncated
                bookObj.addToPages(obj)
            }
            bookObj.totalUnitCount = Int64(newArray.count)
            bookObj.isReady = true
            // 修复：使用枚举索引（页码）而非字节偏移，与 pageAt(_:) 的数组下标语义一致
            bookObj.currentIndex = Int64(enumerated.first(where: { $0.element.offset >= offset })?.0 ?? 0)
            bookObj.totalUnitCount = Int64(newArray.count)
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
