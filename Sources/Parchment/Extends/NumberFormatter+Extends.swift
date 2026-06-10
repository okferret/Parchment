//
//  NumberFormatter+Extends.swift
//  Parchment
//
//  Created by okferret on 2026/6/4.
//

#if canImport(Foundation)
import Foundation

extension NumberFormatter {
    
    /// NumberFormatter
    internal static let `default`: NumberFormatter = {
        let _formatter: NumberFormatter = .init()
        _formatter.locale = .autoupdatingCurrent //.init(identifier: "zh_CN")
        _formatter.minimumFractionDigits = 1
        _formatter.maximumFractionDigits = 2
        _formatter.numberStyle = .percent
        return _formatter
    }()
}

extension CompatibleWrapper where Base: NumberFormatter {
    
    /// string from newValue
    /// - Parameters:
    ///   - newValue: NSNumber
    ///   - local: Locale
    ///   - minimumFractionDigits: Int
    ///   - maximumFractionDigits: Int
    ///   - numberStyle: NumberFormatter.Style
    /// - Returns: String
    internal func string(from newValue: NSNumber,
                         local: Locale = .autoupdatingCurrent,
                         minimumFractionDigits: Int = 0,
                         maximumFractionDigits: Int = 2,
                         numberStyle: NumberFormatter.Style = .percent) -> String {
        base.locale = local
        base.minimumFractionDigits = minimumFractionDigits
        base.maximumFractionDigits = maximumFractionDigits
        base.numberStyle = numberStyle
        return base.string(from: newValue) ?? ""
    }
    
    /// string from newValue
    /// - Parameters:
    ///   - newValue: Float
    ///   - local: Locale
    ///   - minimumFractionDigits: Int
    ///   - maximumFractionDigits: Int
    ///   - numberStyle: NumberFormatter.Style
    /// - Returns: String
    internal func string(from newValue: Float,
                         local: Locale = .autoupdatingCurrent,
                         minimumFractionDigits: Int = 2,
                         maximumFractionDigits: Int = 2,
                         numberStyle: NumberFormatter.Style = .percent) -> String {
        return base.hub.string(from: .init(value: newValue),
                               local: local,
                               minimumFractionDigits: minimumFractionDigits,
                               maximumFractionDigits: maximumFractionDigits,
                               numberStyle: numberStyle)
    }
    
    /// string from newValue
    /// - Parameters:
    ///   - newValue: CGFloat
    ///   - local: Locale
    ///   - minimumFractionDigits: Int
    ///   - maximumFractionDigits: Int
    ///   - numberStyle: NumberFormatter.Style
    /// - Returns: String
    internal func string(from newValue: CGFloat,
                         local: Locale = .autoupdatingCurrent,
                         minimumFractionDigits: Int = 2,
                         maximumFractionDigits: Int = 2,
                         numberStyle: NumberFormatter.Style = .percent) -> String {
        return base.hub.string(from: .init(value: newValue),
                               local: local,
                               minimumFractionDigits: minimumFractionDigits,
                               maximumFractionDigits: maximumFractionDigits,
                               numberStyle: numberStyle)
    }
    
    /// string from newValue
    /// - Parameters:
    ///   - newValue: Double
    ///   - local: Locale
    ///   - minimumFractionDigits: Int
    ///   - maximumFractionDigits: Int
    ///   - numberStyle: NumberFormatter.Style
    /// - Returns: String
    internal func string(from newValue: Double,
                         local: Locale = .autoupdatingCurrent,
                         minimumFractionDigits: Int = 2,
                         maximumFractionDigits: Int = 2,
                         numberStyle: NumberFormatter.Style = .percent) -> String {
        return base.hub.string(from: .init(value: newValue),
                               local: local,
                               minimumFractionDigits: minimumFractionDigits,
                               maximumFractionDigits: maximumFractionDigits,
                               numberStyle: numberStyle)
    }
    
    /// string from newValue
    /// - Parameters:
    ///   - newValue: Int
    ///   - local: Locale
    ///   - minimumFractionDigits: Int
    ///   - maximumFractionDigits: Int
    ///   - numberStyle: NumberFormatter.Style
    /// - Returns: String
    internal func string(from newValue: Int,
                         local: Locale = .autoupdatingCurrent,
                         minimumFractionDigits: Int = 2,
                         maximumFractionDigits: Int = 2,
                         numberStyle: NumberFormatter.Style = .percent) -> String {
        return base.hub.string(from: .init(value: newValue),
                               local: local,
                               minimumFractionDigits: minimumFractionDigits,
                               maximumFractionDigits: maximumFractionDigits,
                               numberStyle: numberStyle)
        
    }
}

#endif
