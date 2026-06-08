//
//  BookmarkViewController.swift
//  Parchment
//
//  Created by okferret on 2026/6/5.
//
#if canImport(UIKit)
import UIKit

class BookmarkViewController: UIViewController {
    
    //  MARK: - 私有属性
    
    /// 列表视图
    private lazy var tableView: UITableView = {
        let _tableView: UITableView = .init(frame: .zero, style: .plain)
        _tableView.backgroundView = BackgroundView(frame: view.bounds)
        (_tableView.backgroundView as! BackgroundView).backgroundImage = .module(named: "ic_empty")
        (_tableView.backgroundView as! BackgroundView).backgroundImageTint = configuration.theme.placeholderTint
        (_tableView.backgroundView as! BackgroundView).text = "暂无内容"
        (_tableView.backgroundView as! BackgroundView).textFont = .systemFont(ofSize: 14.0)
        (_tableView.backgroundView as! BackgroundView).textColor = configuration.theme.placeholderText
        _tableView.translatesAutoresizingMaskIntoConstraints = false
        _tableView.backgroundColor = .clear
        return _tableView
    }()
    
    /// BookEntity.Want
    private let bookWant: BookEntity.Want
    
    /// Configuration
    private let configuration: Configuration
    
    //  MARK: - 生命周期
    
    /// 构造函数
    /// - Parameters:
    ///   - bookWant: BookEntity.Want
    ///   - configuration: Configuration
    internal init(forWhat bookWant: BookEntity.Want, configuration: Configuration) {
        self.bookWant = bookWant
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
        view.backgroundColor = configuration.theme.barTint
    }
}

extension BookmarkViewController {
    
    /// 初始化
    private func initialize() {
        view.backgroundColor = configuration.theme.barTint
        
        // 布局
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
            tableView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
}
#endif
