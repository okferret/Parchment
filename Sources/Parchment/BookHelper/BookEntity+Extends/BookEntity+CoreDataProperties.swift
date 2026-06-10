//
//  BookEntity+CoreDataProperties.swift
//  Parchment
//
//  Created by okferret on 2026/6/8.
//
//

public import Foundation
public import CoreData


public typealias BookEntityCoreDataPropertiesSet = NSSet

extension BookEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BookEntity> {
        return NSFetchRequest<BookEntity>(entityName: "BookEntity")
    }

    @NSManaged public var relativeUID: String
    @NSManaged public var relativePath: String
    @NSManaged public var filename: String
    @NSManaged public var encoding: Int64
    @NSManaged public var chapters: Set<ChapterEntity>
    @NSManaged public var marks: Set<MarkEntity>
    @NSManaged public var pages: Set<PageEntity>
    @NSManaged public var completedUnitCount: Int64
    @NSManaged public var totalUnitCount: Int64
    @NSManaged public var isReady: Bool

}

// MARK: Generated accessors for chapters
extension BookEntity {

    @objc(addChaptersObject:)
    @NSManaged public func addToChapters(_ value: ChapterEntity)

    @objc(removeChaptersObject:)
    @NSManaged public func removeFromChapters(_ value: ChapterEntity)

    @objc(addChapters:)
    @NSManaged public func addToChapters(_ values: NSSet)

    @objc(removeChapters:)
    @NSManaged public func removeFromChapters(_ values: NSSet)

}

// MARK: Generated accessors for marks
extension BookEntity {

    @objc(addMarksObject:)
    @NSManaged public func addToMarks(_ value: MarkEntity)

    @objc(removeMarksObject:)
    @NSManaged public func removeFromMarks(_ value: MarkEntity)

    @objc(addMarks:)
    @NSManaged public func addToMarks(_ values: NSSet)

    @objc(removeMarks:)
    @NSManaged public func removeFromMarks(_ values: NSSet)

}

// MARK: Generated accessors for pages
extension BookEntity {

    @objc(addPagesObject:)
    @NSManaged public func addToPages(_ value: PageEntity)

    @objc(removePagesObject:)
    @NSManaged public func removeFromPages(_ value: PageEntity)

    @objc(addPages:)
    @NSManaged public func addToPages(_ values: NSSet)

    @objc(removePages:)
    @NSManaged public func removeFromPages(_ values: NSSet)

}
