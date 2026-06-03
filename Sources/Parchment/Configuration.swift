//
//  Configuration.swift
//  Parchment
//
//  Created by okferret on 2026/6/3.
//

#if canImport(UIKit)
import UIKit

/// Configuration
final public class Configuration {
    private(set) var transitionStyle: TransitionStyle = .pageCurl
    private(set) var navigationOrientation: NavigationOrientation = .horizontal
    private(set) var options: Dictionary<OptionsKey, Any> = [.spineLocation: SpineLocation.min.rawValue, .interPageSpacing: 0.0]
    private(set) var colors: Colors = .paleMint
}

extension Configuration {
    
    /// 获取默认配置信息
    /// - Returns: Configuration
    public static func `default`() -> Configuration {
        return .init()
    }
    
    /// 获取当前配置信息
    /// - Returns: Configuration
    public static func current() -> Configuration {
        return .init()
    }
}

/// Colors
struct Colors {
    internal let uid: String
    internal let background: UIColor
    internal let barTint: UIColor
    internal let stressTint: UIColor
    internal let primaryTint: UIColor
    internal let primaryText: UIColor
}

extension Colors {
    
    /// 淡薄荷绿
    internal static var paleMint: Colors {
        return .init(uid:           "paleMint",
                     background:    .hex("#D5E3D3"),
                     barTint:       .hex("#E6EFE5"),
                     stressTint:    .hex("#54904F"),
                     primaryTint:   .hex("#333333"),
                     primaryText:   .hex("#333333"))
    }
    
    /// 浅灰蓝
    internal static var powderBlue: Colors {
        return .init(uid:           "powderBlue",
                     background:    .hex("#CED8E2"),
                     barTint:       .hex("#E0EBF7"),
                     stressTint:    .hex("#567CA2"),
                     primaryTint:   .hex("#333333"),
                     primaryText:   .hex("#333333"))
    }
    
    /// 米白色
    internal static var offWhite: Colors {
        return .init(uid:           "offWhite",
                     background:    .hex("#F6F6F6"),
                     barTint:       .hex("#FEFEFE"),
                     stressTint:    .hex("#3D82F2"),
                     primaryTint:   .hex("#333333"),
                     primaryText:   .hex("#333333"))
    }
    
    /// 燕麦色
    internal static var oatmeal: Colors {
        return .init(uid:           "oatmeal",
                     background:    .hex("#F7F0E6"),
                     barTint:       .hex("#FFFCF8"),
                     stressTint:    .hex("#C59F69"),
                     primaryTint:   .hex("#333333"),
                     primaryText:   .hex("#333333"))
    }
    
    /// 曜石黑
    internal static var jetBlack: Colors {
        return .init(uid:           "jetBlack",
                     background:    .hex("#11111"),
                     barTint:       .hex("#222222"),
                     stressTint:    .hex("#3D82F2"),
                     primaryTint:   .hex("#CCCCCC"),
                     primaryText:   .hex("#CCCCCC"))
    }
}

#endif
