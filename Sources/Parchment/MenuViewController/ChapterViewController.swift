//
//  ChapterViewController.swift
//  Parchment
//
//  Created by okferret on 2026/6/3.
//

#if canImport(UIKit)
import UIKit

/// ChapterViewController
class ChapterViewController: UIViewController, MenuContentViewController {
    
    //  MARK: - 私有属性
    
    /// 文件存储位置
    private let fileURL: URL
    /// Configuration
    private let configuration: Configuration
    
    /// UIView
    private(set) lazy var contentView: UIView = {
        let _contentView: UIView = .init(frame: .zero)
        _contentView.backgroundColor = configuration.theme.background
        _contentView.translatesAutoresizingMaskIntoConstraints = false
        return _contentView
    }()
    
    // 指示器
    private lazy var indicateView: UIView = {
        let _indicateView: UIView = .init(frame: .zero)
        _indicateView.backgroundColor = configuration.theme.indicator
        _indicateView.layer.cornerRadius = 2.0
        _indicateView.translatesAutoresizingMaskIntoConstraints = false
        return _indicateView
    }()
    
    /// UISegmentedControl
    private lazy var segementedView: UISegmentedControl = {
        let _segementedView: UISegmentedControl = .init(items: ["目录", "书签"])
        _segementedView.translatesAutoresizingMaskIntoConstraints = false
        _segementedView.backgroundColor = configuration.theme.segmentBackground
        _segementedView.selectedSegmentTintColor = configuration.theme.segmentTint
        _segementedView.selectedSegmentIndex = 0
        _segementedView.setTitleTextAttributes([.foregroundColor: configuration.theme.primaryTint, .font: UIFont.systemFont(ofSize: 15.0, weight: .medium)], for: .selected)
        _segementedView.setTitleTextAttributes([.foregroundColor: configuration.theme.primaryTint, .font: UIFont.systemFont(ofSize: 15.0, weight: .regular)], for: .normal)
        return _segementedView
    }()
    
    /// BackgroundView
    private lazy var backgroundView: BackgroundView = {
        let _backgroundView: BackgroundView = .init(frame: .zero)
        _backgroundView.backgroundImage = .module(named: "ic_empty")?.withRenderingMode(.alwaysTemplate)
        _backgroundView.backgroundImageTint = configuration.theme.placeholderTint
        _backgroundView.text = "暂无内容"
        _backgroundView.textFont = .systemFont(ofSize: 14.0)
        _backgroundView.textColor = configuration.theme.placeholderText
        _backgroundView.spacing = 12.0
        //_backgroundView.offset = .init(horizontal: 0.0, vertical: -100.0)
        return _backgroundView
    }()
    
    /// UITableView
    private lazy var tableView: UITableView = {
        let _tableView: UITableView = .init(frame: .zero, style: .plain)
        _tableView.translatesAutoresizingMaskIntoConstraints = false
        _tableView.contentInsetAdjustmentBehavior = .never
        _tableView.backgroundColor = configuration.theme.background
        _tableView.backgroundView = backgroundView
        return _tableView
    }()
    
    
    //  MARK: - 生命周期
    
    /// g构造函数
    /// - Parameters:
    ///   - fileURL: URL
    ///   - configuration: Configuration
    internal init(forWhat fileURL: URL, configuration: Configuration) {
        self.fileURL = fileURL
        self.configuration = configuration
        super.init(nibName: .none, bundle: .none)
        self.modalPresentationStyle = .currentContext
        self.modalPresentationCapturesStatusBarAppearance = true
        //self.transitioningDelegate = transition
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
        contentView.backgroundColor = configuration.theme.background
        indicateView.backgroundColor = configuration.theme.indicator
        segementedView.backgroundColor = configuration.theme.segmentBackground
        segementedView.selectedSegmentTintColor = configuration.theme.segmentTint
        segementedView.setTitleTextAttributes([.foregroundColor: configuration.theme.primaryTint, .font: UIFont.systemFont(ofSize: 15.0, weight: .medium)], for: .selected)
        segementedView.setTitleTextAttributes([.foregroundColor: configuration.theme.primaryTint, .font: UIFont.systemFont(ofSize: 15.0, weight: .regular)], for: .normal)
        tableView.backgroundColor = configuration.theme.background
        backgroundView.backgroundImageTint = configuration.theme.placeholderTint
        backgroundView.textColor = configuration.theme.placeholderText
    }
    
}

extension ChapterViewController {
    
    /// 初始化
    private func initialize() {
        view.backgroundColor = .clear
        
        view.addSubview(contentView)
        NSLayoutConstraint.activate([
            contentView.leftAnchor.constraint(equalTo: view.leftAnchor),
            contentView.rightAnchor.constraint(equalTo: view.rightAnchor),
            contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            contentView.topAnchor.constraint(equalTo: view.topAnchor)
        ])
        
        contentView.addSubview(indicateView)
        NSLayoutConstraint.activate([
            indicateView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            indicateView.topAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.topAnchor),
            indicateView.widthAnchor.constraint(equalToConstant: 36.0),
            indicateView.heightAnchor.constraint(equalToConstant: 4.0)
        ])
        
        contentView.addSubview(segementedView)
        NSLayoutConstraint.activate([
            segementedView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16.0),
            segementedView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -16.0),
            segementedView.heightAnchor.constraint(equalToConstant: 36.0),
            segementedView.topAnchor.constraint(equalTo: indicateView.bottomAnchor, constant: 20.0)
        ])
        
        contentView.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            tableView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            tableView.topAnchor.constraint(equalTo: segementedView.bottomAnchor),
            tableView.bottomAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
}

#endif
