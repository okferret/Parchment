//
//  ProgressViewController.swift
//  Parchment
//
//  Created by okferret on 2026/6/3.
//

#if canImport(UIKit)

import UIKit

class ProgressViewController: UIViewController, MenuContentViewController {
    
    //  MARK: - 私有属性
    
    /// UIView
    private(set) lazy var contentView: UIView = {
        let _contentView: UIView = .init(frame: .zero)
        _contentView.backgroundColor = configuration.colors.barTint
        _contentView.translatesAutoresizingMaskIntoConstraints = false
        return _contentView
    }()
    
    /// 文件存储位置
    private let fileURL: URL
    /// Configuration
    private let configuration: Configuration
    
    //  MARK: - 生命周期
    
    /// g构造函数
    /// - Parameters:
    ///   - fileURL: URL
    ///   - configuration: Configuration
    internal init(forWhat fileURL: URL, configuration: Configuration) {
        self.fileURL = fileURL
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

extension ProgressViewController {
    
    /// 初始化
    private func initialize() {
        view.backgroundColor = .clear
        
        view.addSubview(contentView)
        NSLayoutConstraint.activate([
            contentView.leftAnchor.constraint(equalTo: view.leftAnchor),
            contentView.rightAnchor.constraint(equalTo: view.rightAnchor),
            contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            contentView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -100.0)
        ])
    }
}
#endif
