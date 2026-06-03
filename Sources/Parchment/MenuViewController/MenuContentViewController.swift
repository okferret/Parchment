//
//  MenuContentViewController.swift
//  Parchment
//
//  Created by okferret on 2026/6/3.
//

#if canImport(UIKit)

import UIKit

/// MenuContentViewController
protocol MenuContentViewController: UIViewController {
    
    /// UIView
    var contentView: UIView { get }
}

#endif
