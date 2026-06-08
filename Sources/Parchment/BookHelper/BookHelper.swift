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
class BookHelper: NSObject {
    
    //  MARK: - 公开属性
    
    /// 单例对象
    internal static let shared: BookHelper = .init()
    
    /// NSManagedObjectContext
    internal static var viewContext: NSManagedObjectContext {
        return container.viewContext
    }
    
    //  MARK: - 私有属性
    
    /// NSPersistentContainer
    internal static let container: NSPersistentContainer = {
        // SQLite 优化选项
        let dict: Dictionary<String, String> = [
            "journal_mode": "WAL",  // Write-Ahead Logging 模式
            "cache_size": "2000",   // 缓存大小
            "synchronous": "NORMAL" // 可选：平衡性能与安全
        ]
        let option: NSPersistentStoreDescription = .init()
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
            if let error = error {
                print("Core Data load error: \(error)")
            }
            semaphore.signal()
        }
        semaphore.wait()
        return container
    }()
}

extension BookHelper {
    
    /// newBackgroundContext
    /// - Returns: NSManagedObjectContext
    internal static func newBackgroundContext() -> NSManagedObjectContext {
        let context: NSManagedObjectContext = .init(concurrencyType: .privateQueueConcurrencyType)
        context.parent = BookHelper.viewContext
        context.automaticallyMergesChangesFromParent = true
        context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        return context
    }
}

#endif
