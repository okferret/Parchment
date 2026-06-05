//
//  MenuContentView.swift
//  Parchment
//
//  Created by okferret on 2026/6/3.
//

#if canImport(UIKit)

import UIKit

/// MenuContentController
protocol MenuContentController: UIViewController {
    
    /// UIView
    var contentView: UIView { get }
}

#endif
