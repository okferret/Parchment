//
//  Configuration.swift
//  Parchment
//
//  Created by okferret on 2026/6/3.
//

#if canImport(UIKit)
import UIKit

/// UserDefaultsID
fileprivate let UserDefaultsID: String = "Parchment-Configuration-UserDefaults"

/// UserDefaultsKey
fileprivate struct UserDefaultsKey: RawRepresentable {
    internal typealias RawValue = String
    internal let rawValue: String
    internal init(rawValue: String) {
        self.rawValue = rawValue
    }
    internal static var transitionStyle: UserDefaultsKey { .init(rawValue: "Parchment-Configuration-UserDefaults-Key-transitionStyle") }
    internal static var navigationOrientation: UserDefaultsKey { .init(rawValue: "Parchment-Configuration-UserDefaults-Key-navigationOrientation") }
    internal static var themeID: UserDefaultsKey { .init(rawValue: "Parchment-Configuration-UserDefaults-Key-themeID") }
    internal static var brightness: UserDefaultsKey { .init(rawValue: "Parchment-Configuration-UserDefaults-Key-brightness") }
    internal static var font: UserDefaultsKey { .init(rawValue: "Parchment-Configuration-UserDefaults-Key-font") }
}

/// Configuration
/// Configuration
final public class Configuration: NSObject {
    private(set) var transitionStyle: TransitionStyle = .pageCurl
    private(set) var navigationOrientation: NavigationOrientation = .horizontal
    private(set) var theme: Theme = .paleMint
    private(set) var brightness: CGFloat = 0.5
    private(set) var font: UIFont = .pingfangSC(ofSize: 16.0)
    internal var textAttributes: Dictionary<NSAttributedString.Key, Any> {
        let paragraphStyle: NSMutableParagraphStyle = .init()
        paragraphStyle.firstLineHeadIndent = "汉字".hub.width(with: font)
        return [.font: font, .foregroundColor: theme.primaryText, .paragraphStyle: paragraphStyle]
    }
    /// UserDefaults
    private lazy var userDefaults: UserDefaults = {
        let _obj: UserDefaults
        if let obj: UserDefaults = .init(suiteName: UserDefaultsID) {
            _obj = obj
        } else {
            _obj = .init()
            _obj.addSuite(named: UserDefaultsID)
        }
        return _obj
    }()
    
    /// 构造函数
    internal override init() {
        super.init()
        if let transitionStyle: TransitionStyle = .init(rawValue: userDefaults.integer(forKey: UserDefaultsKey.transitionStyle.rawValue)) {
            self.transitionStyle = transitionStyle
        } else {
            self.transitionStyle = .pageCurl
        }
        if let navigationOrientation: NavigationOrientation = .init(rawValue: userDefaults.integer(forKey: UserDefaultsKey.navigationOrientation.rawValue)) {
            self.navigationOrientation = navigationOrientation
        } else {
            self.navigationOrientation = .horizontal
        }
        let themeID: Theme.UniqueID = .init(rawValue: userDefaults.integer(forKey: UserDefaultsKey.themeID.rawValue))
        if let theme = Theme.allCases.first(where: { $0.uniqueID == themeID }) {
            self.theme = theme
        } else {
            self.theme = .paleMint
        }
        if let newValue = userDefaults.object(forKey: UserDefaultsKey.brightness.rawValue) as? CGFloat {
            self.brightness = newValue
        } else {
            self.brightness = UIApplication.shared.hub.brightness
        }
        if let fontText: String = userDefaults.string(forKey: UserDefaultsKey.font.rawValue) {
            let cmpts: Array<String> = fontText.components(separatedBy: "<|>")
            if cmpts.count == 2, let nameText = cmpts.first, let sizeText = cmpts.last {
                let fontSize = CGFloat((sizeText as NSString).floatValue)
                self.font = .init(name: nameText, size: fontSize) ?? .pingfangSC(ofSize: 16.0)
            } else {
                self.font = .pingfangSC(ofSize: 16.0)
            }
        } else {
            self.font = .pingfangSC(ofSize: 16.0)
        }
    }
    
    /// changeWith newValue
    /// - Parameter newValue: TransitionStyle
    internal func changeWith(_ newValue: TransitionStyle) {
        guard transitionStyle != newValue else { return }
        transitionStyle = newValue
        userDefaults.set(newValue.rawValue, forKey: UserDefaultsKey.transitionStyle.rawValue)
        userDefaults.synchronize()
    }
    
    /// changeWith newValue
    /// - Parameter newValue: NavigationOrientation
    internal func changeWith(_ newValue: NavigationOrientation) {
        guard navigationOrientation != newValue else { return }
        navigationOrientation = newValue
        userDefaults.set(newValue.rawValue, forKey: UserDefaultsKey.navigationOrientation.rawValue)
        userDefaults.synchronize()
    }
     
    /// changeWith newValue
    /// - Parameter newValue: Theme
    internal func changeWith(_ newValue: Theme) {
        guard theme != newValue else { return }
        theme = newValue
        userDefaults.set(newValue.uniqueID.rawValue, forKey: UserDefaultsKey.themeID.rawValue)
        userDefaults.synchronize()
    }
    
    /// changeWith
    /// - Parameter newValue: CGFloat
    internal func changeWith(_ newValue: CGFloat) {
        guard brightness != newValue else { return }
        brightness = newValue
        userDefaults.set(newValue, forKey: UserDefaultsKey.brightness.rawValue)
        userDefaults.synchronize()
    }
    
    /// changeWith
    /// - Parameter newValue: UIFont
    internal func changeWith(_ newValue: UIFont) {
        guard font.fontName != newValue.fontName || font.pointSize != newValue.pointSize else { return }
        let fontText: String = "\(newValue.fontName)<|>\(newValue.pointSize)"
        userDefaults.set(fontText, forKey: UserDefaultsKey.font.rawValue)
        userDefaults.synchronize()
    }
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
    
    /// URL
    public static let dirURL: URL = {
        let dirURL: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let newURL: URL
        if #available(iOS 16.0, *) {
            newURL = dirURL.appending(path: "Parchment/Books", directoryHint: .isDirectory)
        } else {
            newURL = dirURL.appendingPathComponent("Parchment/Books", isDirectory: true)
        }
        var isDir: ObjCBool = .init(false)
        if FileManager.default.fileExists(atPath: newURL.path, isDirectory: &isDir) == true && isDir.boolValue == false {
            return newURL
        } else {
            try? FileManager.default.removeItem(at: newURL)
            try? FileManager.default.createDirectory(at: newURL, withIntermediateDirectories: true)
            return newURL
        }
    }()
}

/// Theme
struct Theme: Hashable {
    internal let uniqueID: Theme.UniqueID
    internal let background: UIColor
    internal let barTint: UIColor
    internal let stressTint: UIColor
    internal let markedTint: UIColor
    internal let primaryTint: UIColor
    internal let primaryText: UIColor
    internal let secondaryText: UIColor
    internal let separatorTint: UIColor
    internal let indicator: UIColor
    internal let segmentBackground: UIColor
    internal let segmentTint: UIColor
    internal let thumbTintColor: UIColor
    internal let placeholderTint: UIColor
    internal let placeholderText: UIColor
    internal let normalImage: Optional<UIImage>
    internal let selectedImage: Optional<UIImage>
    
    /// hash
    /// - Parameter hasher: Hasher
    internal func hash(into hasher: inout Hasher) {
        hasher.combine(uniqueID)
    }
}

extension Theme: CaseIterable {
    
    /// ID
    struct UniqueID: RawRepresentable, Hashable {
        internal typealias RawValue = Int
        internal let rawValue: Int
        internal init(rawValue: Int) {
            self.rawValue = rawValue
        }
        
        internal static var paleMint: UniqueID { .init(rawValue: 1 << 1) }
        internal static var powderBlue: UniqueID { .init(rawValue: 1 << 2) }
        internal static var oatmeal: UniqueID { .init(rawValue: 1 << 3) }
        internal static var offWhite: UniqueID { .init(rawValue: 1 << 4) }
        internal static var jetBlack: UniqueID { .init(rawValue: 1 << 5) }
    }
    
    /// [Colors]
    internal static var allCases: [Theme] {
        return [.paleMint, .powderBlue, .oatmeal, .offWhite, .jetBlack]
    }
    
    
    /// 淡薄荷绿
    internal static var paleMint: Theme {
        return .init(uniqueID:          .paleMint,
                     background:        .hex("#D5E3D3"),
                     barTint:           .hex("#E6EFE5"),
                     stressTint:        .hex("#54904F"),
                     markedTint:         .hex("#54904E"),
                     primaryTint:       .hex("#333333"),
                     primaryText:       .hex("#333333"),
                     secondaryText:     .hex("#666666"),
                     separatorTint:     .hex("#CAD7C8"),
                     indicator:         .hex("#BFCBBD"),
                     segmentBackground: .hex("#CAD7C8"),
                     segmentTint:       .hex("#E6EFE5"),
                     thumbTintColor:    .hex("#E6EFE5"),
                     placeholderTint:   .hex("#CAD7C8"),
                     placeholderText:   .hex("#999999"),
                     normalImage:       .none,
                     selectedImage:     .module(named: "ic_theme_selected")?.withTintColor(.hex("#54904F")))
    }
    
    /// 浅灰蓝
    internal static var powderBlue: Theme {
        return .init(uniqueID:          .powderBlue,
                     background:        .hex("#CED8E2"),
                     barTint:           .hex("#E0EBF7"),
                     stressTint:        .hex("#567CA2"),
                     markedTint:         .hex("#54904E"),
                     primaryTint:       .hex("#333333"),
                     primaryText:       .hex("#333333"),
                     secondaryText:     .hex("#666666"),
                     separatorTint:     .hex("#C3CCD6"),
                     indicator:         .hex("#B9C1CA"),
                     segmentBackground: .hex("#C3CCD6"),
                     segmentTint:       .hex("#E0EBF7"),
                     thumbTintColor:    .hex("#E0EBF7"),
                     placeholderTint:   .hex("#C3CCD6"),
                     placeholderText:   .hex("#999999"),
                     normalImage:       .none,
                     selectedImage:     .module(named: "ic_theme_selected")?.withTintColor(.hex("#567CA2")))
    }
    
    /// 米白色
    internal static var offWhite: Theme {
        return .init(uniqueID:          .offWhite,
                     background:        .hex("#F6F6F6"),
                     barTint:           .hex("#FEFEFE"),
                     stressTint:        .hex("#3D82F2"),
                     markedTint:         .hex("#54904E"),
                     primaryTint:       .hex("#333333"),
                     primaryText:       .hex("#333333"),
                     secondaryText:     .hex("#666666"),
                     separatorTint:     .hex("#E9E9E9"),
                     indicator:         .hex("#DCDCDC"),
                     segmentBackground: .hex("#E9E9E9"),
                     segmentTint:       .hex("#FFFFFF"),
                     thumbTintColor:    .hex("#FEFEFE"),
                     placeholderTint:   .hex("#E9E9E9"),
                     placeholderText:   .hex("#999999"),
                     normalImage:       .none,
                     selectedImage:     .module(named: "ic_theme_selected")?.withTintColor(.hex("#3D82F2")))
    }
    
    /// 燕麦色
    internal static var oatmeal: Theme {
        return .init(uniqueID:          .oatmeal,
                     background:        .hex("#F7F0E6"),
                     barTint:           .hex("#FFFCF8"),
                     stressTint:        .hex("#C59F69"),
                     markedTint:         .hex("#54904E"),
                     primaryTint:       .hex("#333333"),
                     primaryText:       .hex("#333333"),
                     secondaryText:     .hex("#666666"),
                     separatorTint:     .hex("#EAE3DA"),
                     indicator:         .hex("#DDD7CE"),
                     segmentBackground: .hex("#EAE3DA"),
                     segmentTint:       .hex("#FFFCF8"),
                     thumbTintColor:    .hex("#FBF7F2"),
                     placeholderTint:   .hex("#EAE3DA"),
                     placeholderText:   .hex("#999999"),
                     normalImage:       .none,
                     selectedImage:     .module(named: "ic_theme_selected")?.withTintColor(.hex("#C59F69")))
    }
    
    /// 曜石黑
    internal static var jetBlack: Theme {
        return .init(uniqueID:          .jetBlack,
                     background:        .hex("#11111"),
                     barTint:           .hex("#222222"),
                     stressTint:        .hex("#3D82F2"),
                     markedTint:         .hex("#54904E"),
                     primaryTint:       .hex("#CCCCCC"),
                     primaryText:       .hex("#CCCCCC"),
                     secondaryText:     .hex("#999999"),
                     separatorTint:     .hex("#333333"),
                     indicator:         .hex("#666666"),
                     segmentBackground: .hex("#333333"),
                     segmentTint:       .hex("#222222"),
                     thumbTintColor:    .hex("#333333"),
                     placeholderTint:   .hex("#333333"),
                     placeholderText:   .hex("#666666"),
                     normalImage:       .module(named: "ic_theme_moon")?.withTintColor(.hex("#CCCCCC")),
                     selectedImage:     .module(named: "ic_theme_moon")?.withTintColor(.hex("#CCCCCC")))
    }
}

#endif
