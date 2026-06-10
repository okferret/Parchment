//
//  DateFormatter+Extends.swift
//  Parchment
//
//  Created by okferret on 2026/6/10.
//

import Foundation

extension DateFormatter {
    
    /// 获取单例对象
    internal static let shared: DateFormatter = .init()
}

extension DateFormatter: Compatible {}
extension CompatibleWrapper where Base: DateFormatter {
    
    
    /// 时间格式化
    /// - Parameters:
    ///   - date: 被格式化的日期
    ///   - format: 日期格式
    ///   - timeZone: 时区
    ///   - locale: 本地化
    /// - Returns: 格式化后的时间
    internal func format(_ date: Date, format: String, timeZone: Optional<TimeZone> = .none, locale: Optional<Locale> = .none) -> String {
        base.timeZone = timeZone
        base.locale = locale
        base.dateFormat = format
        return base.string(from: date)
    }
    
    /// 文本转Date
    /// - Parameters:
    ///   - text: String
    ///   - timeZone: Optional<TimeZone>
    ///   - locale: Optional<Locale>
    /// - Returns: Optional<Date>
    internal func date(from text: String, format: String, timeZone: Optional<TimeZone> = .none, locale: Optional<Locale> = .none) -> Optional<Date> {
        base.dateFormat = format
        base.timeZone = timeZone
        base.locale = locale
        return base.date(from: text)
    }
}
