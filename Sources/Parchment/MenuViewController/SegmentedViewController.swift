//
//  SegmentedViewController.swift
//  Parchment
//
//  Created by okferret on 2026/6/5.
//

#if canImport(UIKit)

import UIKit

/// SegmentedViewController
class SegmentedViewController: UIViewController, MenuContentController {
    
    //  MARK: - 私有属性
    
    /// UIView
    private(set) lazy var contentView: UIView = {
        let _contentView: UIView = .init(frame: .zero)
        _contentView.translatesAutoresizingMaskIntoConstraints = false
        _contentView.backgroundColor = configuration.theme.barTint
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
    private lazy var segmentedView: UISegmentedView = {
        let _segmentedView: UISegmentedView = .init(items: ["章节", "书签"])
        _segmentedView.translatesAutoresizingMaskIntoConstraints = false
        _segmentedView.backgroundColor = configuration.theme.segmentBackground
        _segmentedView.segmentTintColor = configuration.theme.segmentTint
        _segmentedView.selectedSegmentIndex = 0
        _segmentedView.setTitleTextAttributes([.foregroundColor: configuration.theme.primaryTint, .font: UIFont.systemFont(ofSize: 15.0, weight: .medium)], for: .selected)
        _segmentedView.setTitleTextAttributes([.foregroundColor: configuration.theme.primaryTint, .font: UIFont.systemFont(ofSize: 15.0, weight: .regular)], for: .normal)
        _segmentedView.addTarget(self, action: #selector(segmentActionHandler(_:)), for: .valueChanged)
        return _segmentedView
    }()
    
    /// 章节
    private lazy var chapter: ChapterViewController = {
        let _controller: ChapterViewController = .init(forWhat: bookWant, configuration: configuration)
        _controller.view.translatesAutoresizingMaskIntoConstraints = false
        return _controller
    }()

    /// 书签
    private lazy var bookmark: BookmarkViewController = {
        let _controller: BookmarkViewController = .init(forWhat: bookWant, configuration: configuration)
        _controller.view.isHidden = true
        _controller.view.translatesAutoresizingMaskIntoConstraints = false
        return _controller
    }()
    
    
    
    /// BookEntity.Want
    private let bookWant: BookEntity.Want
    
    /// Configuration
    private let configuration: Configuration
    
    //  MARK: - 生命周期
    
    /// 构造函数
    /// - Parameters:
    ///   - bookWant: BookEntity.Want
    ///   - configuation: Configuration
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
        contentView.backgroundColor = configuration.theme.barTint
        indicateView.backgroundColor = configuration.theme.indicator
        segmentedView.backgroundColor = configuration.theme.segmentBackground
        segmentedView.segmentTintColor = configuration.theme.segmentTint
        segmentedView.selectedSegmentIndex = 0
        segmentedView.setTitleTextAttributes([.foregroundColor: configuration.theme.primaryTint, .font: UIFont.systemFont(ofSize: 15.0, weight: .medium)], for: .selected)
        segmentedView.setTitleTextAttributes([.foregroundColor: configuration.theme.primaryTint, .font: UIFont.systemFont(ofSize: 15.0, weight: .regular)], for: .normal)
    }
}

extension SegmentedViewController {
    
    /// 初始化
    private func initialize() {
        view.backgroundColor = .clear
        
        // 布局
        view.addSubview(contentView)
        NSLayoutConstraint.activate([
            contentView.leftAnchor.constraint(equalTo: view.leftAnchor),
            contentView.rightAnchor.constraint(equalTo: view.rightAnchor),
            contentView.topAnchor.constraint(equalTo: view.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        
        contentView.addSubview(indicateView)
        NSLayoutConstraint.activate([
            indicateView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            indicateView.topAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.topAnchor),
            indicateView.widthAnchor.constraint(equalToConstant: 36.0),
            indicateView.heightAnchor.constraint(equalToConstant: 4.0),
        ])
        
        contentView.addSubview(segmentedView)
        NSLayoutConstraint.activate([
            segmentedView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16.0),
            segmentedView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -16.0),
            segmentedView.topAnchor.constraint(equalTo: indicateView.bottomAnchor, constant: 20.0),
            segmentedView.heightAnchor.constraint(equalToConstant: 36.0)
        ])
        
        chapter.willMove(toParent: self)
        addChild(chapter)
        chapter.didMove(toParent: self)
        chapter.view.willMove(toSuperview: contentView)
        contentView.addSubview(chapter.view)
        chapter.view.didMoveToSuperview()
        
        NSLayoutConstraint.activate([
            chapter.view.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            chapter.view.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            chapter.view.bottomAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.bottomAnchor),
            chapter.view.topAnchor.constraint(equalTo: segmentedView.bottomAnchor, constant: 14.0)
        ])
        
        bookmark.willMove(toParent: self)
        addChild(bookmark)
        bookmark.didMove(toParent: self)
        bookmark.view.willMove(toSuperview: contentView)
        contentView.addSubview(bookmark.view)
        bookmark.view.didMoveToWindow()
        NSLayoutConstraint.activate([
            bookmark.view.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            bookmark.view.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            bookmark.view.bottomAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.bottomAnchor),
            bookmark.view.topAnchor.constraint(equalTo: segmentedView.bottomAnchor, constant: 14.0)
        ])
        
    }
    
    /// segmentActionHandler
    /// - Parameter sender: UISegmentedView
    @objc private func segmentActionHandler(_ sender: UISegmentedView) {
        if sender.selectedSegmentIndex == 0 {
            bookmark.beginAppearanceTransition(false, animated: true)
            chapter.beginAppearanceTransition(true, animated: true)
            UIView.transition(from: bookmark.view, to: chapter.view, duration: 0.25, options: [.showHideTransitionViews, .curveEaseInOut]) { _ in
                self.chapter.view.isHidden = false
                self.bookmark.view.isHidden = true
                self.chapter.endAppearanceTransition()
                self.bookmark.endAppearanceTransition()
            }
        } else {
            chapter.beginAppearanceTransition(false, animated: true)
            bookmark.beginAppearanceTransition(true, animated: true)
            UIView.transition(from: chapter.view, to: bookmark.view, duration: 0.25, options: [.showHideTransitionViews, .curveEaseInOut]) { _ in
                self.chapter.view.isHidden = true
                self.bookmark.view.isHidden = false
                self.chapter.endAppearanceTransition()
                self.bookmark.endAppearanceTransition()
            }
        }
    }
}


#endif
