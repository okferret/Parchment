// The Swift Programming Language
// https://docs.swift.org/swift-book
#if canImport(UIKit)

import UIKit

/// UIPageViewController.TransitionStyle
public typealias TransitionStyle = UIPageViewController.TransitionStyle
/// UIPageViewController.NavigationOrientation
public typealias NavigationOrientation = UIPageViewController.NavigationOrientation
/// UIPageViewController.NavigationDirection
public typealias NavigationDirection = UIPageViewController.NavigationDirection
/// UIPageViewController.SpineLocation
public typealias SpineLocation = UIPageViewController.SpineLocation
/// UIPageViewController.OptionsKey
public typealias OptionsKey = UIPageViewController.OptionsKey

extension TransitionStyle: @retroactive CaseIterable, @retroactive CustomStringConvertible {
    
    /// [UIPageViewController.TransitionStyle]
    public static var allCases: [UIPageViewController.TransitionStyle] {
        return [.pageCurl, .scroll]
    }
    
    /// String
    public var description: String {
        switch self {
        case .pageCurl: return "仿真翻页"
        case .scroll:   return "左右平移"
        default:        return ""
        }
    }
}


#endif


