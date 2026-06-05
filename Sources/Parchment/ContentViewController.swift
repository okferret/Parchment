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
    
    /// UIView
    private lazy var contentView: UIView = {
        let _contentView: UIView = .init(frame: .zero)
        _contentView.backgroundColor = .random
        _contentView.translatesAutoresizingMaskIntoConstraints = false
        return _contentView
    }()
    
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
    
    /// traitCollectionDidChange
    /// - Parameter previousTraitCollection: UITraitCollection
    internal override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        // next
        view.backgroundColor = configuration.theme.background
    }
    
}

extension ContentViewController {
    
    /// 初始化
    private func initialize() {
        view.backgroundColor = configuration.theme.background
        
        view.addSubview(contentView)
        NSLayoutConstraint.activate([
            contentView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
            contentView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
            contentView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
}

#endif
