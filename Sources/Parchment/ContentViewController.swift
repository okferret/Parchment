//
//  ContentViewController.swift
//  Parchment
//
//  Created by okferret on 2026/6/3.
//

#if canImport(UIKit)

import UIKit

/// ContentViewController
class ContentViewController: UIViewController {
    
    //  MARK: - 私有属性
    
    /// String
    private let newText: String
    
    /// Configuration
    private let configuration: Configuration
    
    //  MARK: - 生命周期
    
    /// 构造函数
    /// - Parameters:
    ///   - newText: String
    ///   - configuration: Configuration
    internal init(forWhat newText: String, configuration: Configuration) {
        self.newText = newText
        self.configuration = configuration
        super.init(nibName: .none, bundle: .none)
    }
    
    /// 构造函数
    /// - Parameter coder: NSCoder
    internal required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// viewDidLoad
    internal override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        // 初始化
        initialize()
    }
    
}

extension ContentViewController {
    
    /// 初始化
    private func initialize() {
        view.backgroundColor = configuration.colors.background
    }
}

#endif
