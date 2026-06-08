//
//  ChapterEntity+CoreDataProperties.swift
//  Parchment
//
//  Created by okferret on 2026/6/8.
//
//

public import Foundation
public import CoreData


public typealias ChapterEntityCoreDataPropertiesSet = NSSet

extension ChapterEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ChapterEntity> {
        return NSFetchRequest<ChapterEntity>(entityName: "ChapterEntity")
    }

    @NSManaged public var length: Int64
    @NSManaged public var offset: Int64
    @NSManaged public var sketchText: String
    @NSManaged public var title: String
    @NSManaged public var book: BookEntity

}
