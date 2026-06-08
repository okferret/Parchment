//
//  PageEntity+CoreDataProperties.swift
//  Parchment
//
//  Created by okferret on 2026/6/8.
//
//

public import Foundation
public import CoreData


public typealias PageEntityCoreDataPropertiesSet = NSSet

extension PageEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PageEntity> {
        return NSFetchRequest<PageEntity>(entityName: "PageEntity")
    }

    @NSManaged public var length: Int64
    @NSManaged public var offset: Int64
    @NSManaged public var text: String
    @NSManaged public var book: BookEntity

}
