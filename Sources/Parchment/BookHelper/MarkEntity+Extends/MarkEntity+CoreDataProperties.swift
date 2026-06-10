//
//  MarkEntity+CoreDataProperties.swift
//  Parchment
//
//  Created by okferret on 2026/6/8.
//
//

public import Foundation
public import CoreData


public typealias MarkEntityCoreDataPropertiesSet = NSSet

extension MarkEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MarkEntity> {
        return NSFetchRequest<MarkEntity>(entityName: "MarkEntity")
    }

    @NSManaged public var length: Int64
    @NSManaged public var offset: Int64
    @NSManaged public var sketchText: String
    @NSManaged public var createdAt: Date
    @NSManaged public var book: BookEntity

}
