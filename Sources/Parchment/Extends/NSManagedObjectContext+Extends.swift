//
//  NSManagedObjectContext+Extends.swift
//  Parchment
//
//  Created by okferret on 2026/6/5.
//

#if canImport(CoreData)
import CoreData

extension NSManagedObjectContext: Compatible {}
extension CompatibleWrapper where Base: NSManagedObjectContext {
    
    /// performAndWait
    /// - Parameter block: (_ context: NSManagedObjectContext) throws -> T
    /// - Returns: T
    internal func performAndWait<T>(_ block: (_ context: NSManagedObjectContext) throws -> T) throws -> T {
        if #available(iOS 15.0, *) {
            return try base.performAndWait {[weak base] in
                if let base = base {
                    return try block(base)
                } else {
                    throw PAError.customWith("Current context has been destroyed...")
                }
            }
        } else {
            var newValue: Optional<T> = .none
            var newError: Optional<Error> = .none
            base.performAndWait {[weak base] in
                guard let base = base else { return }
                do {
                    newValue = try block(base)
                } catch {
                    newError = error
                }
            }
            if let newValue = newValue {
                return newValue
            } else {
                throw newError ?? PAError.unknown
            }
        }
    }
    
    /// obtainPermanentIDs
    /// - Parameter objects: Array<NSManagedObject>
    internal func obtainPermanentIDs(for objects: Array<NSManagedObject>) throws {
        return try base.obtainPermanentIDs(for: objects.filter(\.objectID.isTemporaryID))
    }
    
    /// obtainPermanentIDs
    /// - Parameter objects: Set<NSManagedObject>
    internal func obtainPermanentIDs(for objects: Set<NSManagedObject>) throws {
        return try base.obtainPermanentIDs(for: objects.filter(\.objectID.isTemporaryID))
    }
    
    /// 逐级保存
    internal func saveAndWait() throws {
        guard base.hasChanges == true else { return }
        try base.save()
        if let ctx = base.parent {
            try ctx.hub.performAndWait { ctx in
                try ctx.hub.saveAndWait()
            }
        }
    }
    
    /// NSMergePolicy
    internal var mergePolicy: NSMergePolicy {
        get { base.mergePolicy as! NSMergePolicy }
        set { base.mergePolicy = newValue }
    }
}

extension CompatibleWrapper where Base: NSManagedObjectContext {
    
    /// 获取管理对象
    /// - Parameter objectID: 管理对象ID
    /// - Returns: 范型对象
    internal func object<T>(for objectID: NSManagedObjectID) throws -> T where T: NSManagedObject {
        if let obj: T = try base.existingObject(with: objectID) as? T {
            return obj
        } else {
            throw PAError.customWith("Can not convert object to \(T.self)")
        }
    }
    
    /// 获取单一管理对象
    /// - Parameter freq: NSFetchRequest<T>
    /// - Parameter returnsObjectsAsFaults: 是否将对象的所有属性都已加载到内存
    /// - Returns: 范型对象
    ///
    internal func fetchAny<T>(for freq: NSFetchRequest<T>, returnsObjectsAsFaults: Bool = false) throws -> T where T: NSManagedObject {
        freq.fetchLimit = 1
        freq.resultType = .managedObjectResultType
        freq.returnsObjectsAsFaults = returnsObjectsAsFaults
        let elements: Array<T> = try base.fetch(freq)
        if let first = elements.first {
            return first
        } else {
            throw PAError.customWith("Can not  fetch any object of \(T.self)")
        }
    }
    
    /// 查询数据是否存在
    /// - Parameter freq:  NSFetchRequest<T>
    /// - Returns: Bool
    internal func containsWith<T>(_ freq: NSFetchRequest<T>) -> Bool where T: NSManagedObject {
        do {
            let count: Int = try base.count(for: freq)
            return count > 0
        } catch {
            return false
        }
    }
    
    /// 获取单一管理对象
    /// - Parameters:
    ///   - objectID: NSManagedObjectID
    ///   - returnsObjectsAsFaults: Bool
    /// - Returns: Bool
    internal func fetchAny<T>(for objectID: NSManagedObjectID, returnsObjectsAsFaults: Bool = false) throws -> T where T: NSManagedObject {
        let freq: NSFetchRequest<T> = T.fetchRequest() as! NSFetchRequest<T>
        freq.predicate = .init(format: "SELF == %@", objectID)
        freq.resultType = .managedObjectResultType
        freq.returnsObjectsAsFaults = returnsObjectsAsFaults
        return try fetchAny(for: freq, returnsObjectsAsFaults: returnsObjectsAsFaults)
    }
    
    /// delete
    /// - Parameter objs: Array<NSManagedObject>
    internal func delete(_ objs: Array<NSManagedObject>) {
        objs.forEach { base.delete($0) }
    }
    
    /// delete
    /// - Parameter obj: NSManagedObject...
    internal func delete(_ obj: NSManagedObject...) {
        obj.forEach { base.delete($0) }
    }
    
}

#endif
