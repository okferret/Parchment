//
//  ParchmentViewController.swift
//  Parchment
//
//  Created by okferret on 2026/6/3.
//

#if canImport(UIKit)

import UIKit
import CoreData

/// ParchmentViewController
final public class ParchmentViewController: UINavigationController {
    
    //  MARK: - 私有属性
    
    /// 关闭按钮
    private lazy var closeItem: UIBarButtonItem = {
        let _img: Optional<UIImage> = .module(named: "ic_book_close")
        let _item: UIBarButtonItem = .init(image: _img, style: .plain, target: self, action: #selector(itemActionHandler(_:)))
        _item.tintColor = configuration.theme.primaryTint
        return _item
    }()
    
    /// 书签
    private lazy var bookmarkItem: UIBarButtonItem = {
        let _img: Optional<UIImage> = .module(named: "ic_book_mark")
        let _item: UIBarButtonItem = .init(image: _img, style: .plain, target: self, action: #selector(itemActionHandler(_:)))
        _item.tintColor = configuration.theme.primaryTint
        return _item
    }()
    
    /// 章节
    private lazy var chapterItem: UIBarButtonItem = {
        let _img: Optional<UIImage> = .module(named: "ic_book_chapter")
        let _item: UIBarButtonItem = .init(image: _img, style: .plain, target: self, action: #selector(itemActionHandler(_:)))
        _item.tintColor = configuration.theme.primaryTint
        _item.hub.state = .normal
        return _item
    }()
    
    /// 进度
    private lazy var progressItem: UIBarButtonItem = {
        let _img: Optional<UIImage> = .module(named: "ic_book_progress")
        let _item: UIBarButtonItem = .init(image: _img, style: .plain, target: self, action: #selector(itemActionHandler(_:)))
        _item.tintColor = configuration.theme.primaryTint
        _item.hub.state = .normal
        return _item
    }()
    
    /// 其他
    private lazy var otherItem: UIBarButtonItem = {
        let _img: Optional<UIImage> = .module(named: "ic_book_other")
        let _item: UIBarButtonItem = .init(image: _img, style: .plain, target: self, action: #selector(itemActionHandler(_:)))
        _item.tintColor = configuration.theme.primaryTint
        _item.hub.state = .normal
        return _item
    }()
    
    /// Array<UIBarButtonItem>
    private lazy var barItemArray: Array<UIBarButtonItem> = {
        return [.flexible(), chapterItem, .flexible(), .flexible(), progressItem, .flexible(), .flexible(), otherItem, .flexible()]
    }()
    
    /// Array<UIBarButtonItem>
    private var bottomItemArray: Array<UIBarButtonItem> {
        return [chapterItem, progressItem, otherItem]
    }
    
    /// 点击手势
    private lazy var tapGesture: UITapGestureRecognizer = {
        let _tapGesture: UITapGestureRecognizer = .init(target: self, action: #selector(tapActionHandler(_:)))
        _tapGesture.numberOfTapsRequired = 1
        _tapGesture.numberOfTouchesRequired = 1
        _tapGesture.cancelsTouchesInView = false
        return _tapGesture
    }()
    
    /// 菜单控制器
    private lazy var menuController: MenuViewController = {
        let _controller: MenuViewController = .init(forWhat: .none, configuration: configuration)
        _controller.view.backgroundColor = .black.withAlphaComponent(0.15)
        _controller.additionalSafeAreaInsets = .init(top: 0.0, left: 0.0, bottom: toolbar.bounds.height, right: 0.0)
        _controller.menuDelegate = self
        _controller.view.translatesAutoresizingMaskIntoConstraints = false
        return _controller
    }()
    
    /// 指示器
    private lazy var loadingView: UIActivityIndicatorView = {
        let _loadingView: UIActivityIndicatorView = .init(style: .medium)
        _loadingView.hidesWhenStopped = true
        _loadingView.translatesAutoresizingMaskIntoConstraints = false
        return _loadingView
    }()
    
    /// Optional<BookEntity.Want>
    private var bookWant: Optional<BookEntity.Want> = .none
    
    /// 文件存储位置
    private let fileURL: URL
    /// 配置信息
    private let configuration: Configuration
    
    /// 记录系统亮度
    private var brightness: CGFloat = 0.5
    
    /// Optional<UIWindow>
    private var keyWindow: Optional<UIWindow> {
        return (view.window ?? UIApplication.shared.hub.keyWindow)
    }
  
    //  MARK: - 生命周期
    
    /// 构造函数
    /// - Parameters:
    ///   - fileURL: 文件存储位置
    ///   - configuration: Configuration
    public init(forWhat fileURL: URL, configuration: Configuration = .current()) {
        self.fileURL = fileURL
        self.configuration = configuration
        super.init(nibName: .none, bundle: .none)
        self.modalPresentationStyle = .fullScreen
        self.isNavigationBarHidden = true
        self.isToolbarHidden = true
        let barButtonItemAppearance: UIBarButtonItemAppearance = .init()
        barButtonItemAppearance.normal.titleTextAttributes = [.foregroundColor: configuration.theme.primaryTint]
        self.navigationBar.hub.configureWithOpaqueBackground()
        self.navigationBar.hub.backgroundColor(configuration.theme.barTint)
        self.navigationBar.hub.buttonAppearance(barButtonItemAppearance)
        self.navigationBar.hub.titleTextAttributes([.foregroundColor: configuration.theme.primaryTint])
        self.navigationBar.hub.shadowColor(.clear)
        self.toolbar.hub.configureWithOpaqueBackground()
        self.toolbar.hub.backgroundColor(configuration.theme.barTint)
        self.toolbar.hub.buttonAppearance(barButtonItemAppearance)
        self.toolbar.hub.shadowColor(.clear)
        self.isNavigationBarHidden = false
        self.isToolbarHidden = false
        let controller: UIPageViewController = .init(transitionStyle: configuration.transitionStyle,
                                                     navigationOrientation: configuration.navigationOrientation,
                                                     options: [.interPageSpacing: 0.0, .spineLocation: SpineLocation.min.rawValue])
        controller.navigationItem.leftBarButtonItem = closeItem
        controller.navigationItem.rightBarButtonItem = bookmarkItem
        controller.navigationItem.title = fileURL.deletingPathExtension().lastPathComponent
        controller.toolbarItems = barItemArray
        controller.delegate = self
        controller.dataSource = self
        controller.setViewControllers([ContentViewController()], direction: .forward, animated: false)
        controller.view.backgroundColor = .clear
        self.setViewControllers([controller], animated: false)
    }
    
    /// 构造函数
    /// - Parameter aDecoder: NSCoder
    internal required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// viewDidLoad
    public override func viewDidLoad() {
        super.viewDidLoad()
        // 初始化
        initialize()
        // 添加通知
        // NotificationCenter.default.addObserver(self, selector: #selector(notificaitonHandler(_:)), name: UIScreen.brightnessDidChangeNotification, object: .none)
        brightness = keyWindow?.screen.brightness ?? 0.5
        keyWindow?.screen.brightness = configuration.brightness
        // 解析数据
        parseWith(fileURL)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
#if DEBUG
        print(#function, "=>", (#file as NSString).lastPathComponent)
#endif
    }
}

extension ParchmentViewController {
    
    /// 初始化
    private func initialize() {
        view.backgroundColor = configuration.theme.background
        view.addGestureRecognizer(tapGesture)
        addChild(menuController)
        // 添加布局
        view.insertSubview(menuController.view, belowSubview: navigationBar)
        NSLayoutConstraint.activate([
            menuController.view.leftAnchor.constraint(equalTo: view.leftAnchor),
            menuController.view.rightAnchor.constraint(equalTo: view.rightAnchor),
            menuController.view.topAnchor.constraint(equalTo: view.topAnchor),
            menuController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        view.addSubview(loadingView)
        NSLayoutConstraint.activate([
            loadingView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }
    
    /// parseWith
    /// - Parameter fileURL: URL
    private func parseWith(_ fileURL: URL) {
        guard let keyWindow = UIApplication.shared.hub.keyWindow else { return }
        let safeAreaInsets: UIEdgeInsets = BookHelper.safeAreaInsets
        let safeArea: CGSize = keyWindow.bounds.inset(by: safeAreaInsets).size
        Task(priority: .userInitiated) {
            do {     
                let newWant: BookEntity.Want = try await BookHelper.shared.parseWith(fileURL, safeArea: safeArea, textAttributes: configuration.textAttributes)
                self.bookWant = newWant
                menuController.reloadWith(newWant)
                if let topViewController = topViewController as? UIPageViewController, let pageWant: PageEntity.Want = newWant.pageAt(.none) {
                    let controller: ContentViewController = .init()
                    controller.additionalSafeAreaInsets = .init(top: 0.0, left: safeAreaInsets.left, bottom: 0.0, right: safeAreaInsets.right)
                    controller.reloadWith(pageWant, configuration: configuration)
                    topViewController.setViewControllers([controller], direction: .forward, animated: false)
                }
            } catch {
                let controller: UIAlertController = .init(title: "操作提醒", message: error.localizedDescription, preferredStyle: .alert)
                controller.addAction(.init(title: "关闭", style: .default, handler: { _ in
                    self.dismiss(animated: true, completion: .none)
                }))
                present(controller, animated: true, completion: .none)
            }
            loadingView.stopAnimating()
        }
    }
    
    /// itemActionHandler
    /// - Parameter sender: UIBarButtonItem
    @objc private func itemActionHandler(_ sender: UIBarButtonItem) {
        switch sender {
        case closeItem:
            // 还原亮度
            keyWindow?.screen.brightness = brightness
            dismiss(animated: true, completion: .none)
            
        case bookmarkItem:
            break
        case chapterItem where sender.hub.state == .normal:
            Set(bottomItemArray).subtracting([chapterItem]).forEach { $0.hub.state = .normal; $0.tintColor = configuration.theme.primaryTint }
            chapterItem.tintColor = configuration.theme.stressTint
            chapterItem.hub.state = .selected
            menuController.showMenuWith(.segmented)
            // tapGesture.isEnabled = false
            setNavigationBarHidden(true, animated: true)
            
        case chapterItem where sender.hub.state == .selected:
            chapterItem.tintColor = configuration.theme.primaryTint
            chapterItem.hub.state = .normal
            menuController.hideMenu()
            // tapGesture.isEnabled = true
            setNavigationBarHidden(false, animated: true)
            
        case progressItem where sender.hub.state == .normal:
            Set(bottomItemArray).subtracting([progressItem]).forEach { $0.hub.state = .normal; $0.tintColor = configuration.theme.primaryTint }
            progressItem.tintColor = configuration.theme.stressTint
            progressItem.hub.state = .selected
            menuController.showMenuWith(.progress)
            // tapGesture.isEnabled = false
            setNavigationBarHidden(false, animated: true)
            
        case progressItem where sender.hub.state == .selected:
            progressItem.tintColor = configuration.theme.primaryTint
            progressItem.hub.state = .normal
            menuController.hideMenu()
            // tapGesture.isEnabled = true
            setNavigationBarHidden(false, animated: true)
        
        case otherItem where sender.hub.state == .normal:
            Set(bottomItemArray).subtracting([otherItem]).forEach { $0.hub.state = .normal; $0.tintColor = configuration.theme.primaryTint }
            otherItem.tintColor = configuration.theme.stressTint
            otherItem.hub.state = .selected
            menuController.showMenuWith(.other)
            // tapGesture.isEnabled = false
            setNavigationBarHidden(false, animated: true)
            
        case otherItem where sender.hub.state == .selected:
            otherItem.tintColor = configuration.theme.primaryTint
            otherItem.hub.state = .normal
            menuController.hideMenu()
            // tapGesture.isEnabled = true
            setNavigationBarHidden(false, animated: true)
            
        default: break
        }
    }
    
    /// tapActionHandler
    /// - Parameter sender: UITapGestureRecognizer
    @objc private func tapActionHandler(_ sender: UITapGestureRecognizer) {
        // 过滤
        let location = sender.location(in: view)
        guard location.y > navigationBar.frame.maxY && location.y < toolbar.frame.minY else { return }
        if isToolbarHidden == false || isNavigationBarHidden == false {
            if let topViewController = menuController.topViewController as? MenuContentController {
                guard topViewController.contentView.frame.contains(location) == false else { return }
                hideBarAction()
            } else {
                hideBarAction()
            }
        } else {
            if let topViewController = menuController.topViewController as? MenuContentController {
                guard topViewController.contentView.frame.contains(location) == false else { return }
                hideBarAction()
            } else {
                // 分区域
                let leftArea: CGRect = .init(x: 0.0, y: 0.0, width: floor(view.bounds.width * 0.33), height: view.bounds.height)
                let rightArea: CGRect = .init(x: view.bounds.width - leftArea.width, y: 0.0, width: leftArea.width, height: view.bounds.height)
                let midArea: CGRect = .init(x: leftArea.maxX, y: 0.0, width: rightArea.minX - leftArea.maxX, height: view.bounds.height)
                // 根据区域划分功能
                switch location {
                case _ where midArea.contains(location) == true && (isToolbarHidden == true || isNavigationBarHidden == true):
                    showBarAction()
                    
                case _ where leftArea.contains(location) == true:
                    if let bookWant = bookWant, let topViewController = topViewController as? UIPageViewController {
                        backwardWith(bookWant, pageViewController: topViewController)
                    }
                    
                case _ where rightArea.contains(location) == true:
                    if let bookWant = bookWant, let topViewController = topViewController as? UIPageViewController {
                        forewardWith(bookWant, pageViewController: topViewController)
                    }
                default: break
                }
            }
        }
    }
    
    /// 下一页
    /// - Parameters:
    ///   - bookWant: BookEntity.Want
    ///   - pageViewController: UIPageViewController
    private func forewardWith(_ bookWant: BookEntity.Want, pageViewController: UIPageViewController) {
        switch pageViewController.transitionStyle {
        case .scroll:
            let newIndex: Int64 = bookWant.currentIndex + 1
            if let newWant: PageEntity.Want = bookWant.pageAt(newIndex) {
                let controller: ContentViewController = .init()
                controller.reloadWith(newWant, configuration: configuration)
                let previousViewControllers: Array<UIViewController> = pageViewController.viewControllers ?? []
                tapGesture.isEnabled = false
                pageViewController.setViewControllers([controller], direction: .forward, animated: true) {[weak pageViewController, weak tapGesture] finished in
                    defer { tapGesture?.isEnabled = true }
                    guard let pageViewController = pageViewController, finished == true else { return }
                    pageViewController.delegate?.pageViewController?(pageViewController,
                                                                     didFinishAnimating: true,
                                                                     previousViewControllers: previousViewControllers,
                                                                     transitionCompleted: true)
                }
            }
            
        default: break
        }
    }
    
    /// 上一页
    /// - Parameters:
    ///   - bookWant: BookEntity.Want
    ///   - pageViewController: UIPageViewController
    private func backwardWith(_ bookWant: BookEntity.Want, pageViewController: UIPageViewController) {
        switch pageViewController.transitionStyle {
        case .scroll:
            let newIndex: Int64 = bookWant.currentIndex - 1
            if let newWant: PageEntity.Want = bookWant.pageAt(newIndex) {
                let controller: ContentViewController = .init()
                controller.reloadWith(newWant, configuration: configuration)
                let previousViewControllers: Array<UIViewController> = pageViewController.viewControllers ?? []
                tapGesture.isEnabled = false
                pageViewController.setViewControllers([controller], direction: .reverse, animated: true) {[weak pageViewController, weak tapGesture] finished in
                    defer { tapGesture?.isEnabled = true }
                    guard let pageViewController = pageViewController, finished == true else { return }
                    pageViewController.delegate?.pageViewController?(pageViewController,
                                                                     didFinishAnimating: true,
                                                                     previousViewControllers: previousViewControllers,
                                                                     transitionCompleted: true)
                }
            }
            
        default: break
        }
    }
    
    /// showBarAction
    private func showBarAction() {
        setToolbarHidden(false, animated: true)
        setNavigationBarHidden(false, animated: true)
        menuController.view.isHidden = false
        UIView.animate(withDuration: 0.25) {
            self.menuController.view.alpha = 1.0
        }
    }
    
    /// hideBarAction
    private func hideBarAction() {
        setToolbarHidden(true, animated: true)
        setNavigationBarHidden(true, animated: true)
        menuController.hideMenu()
        UIView.animate(withDuration: 0.25) {
            self.menuController.view.alpha = 0.0
        } completion: { _ in
            self.menuController.hideMenu()
            self.menuController.view.isHidden = true
            self.bottomItemArray.forEach { $0.hub.state = .normal; $0.tintColor = self.configuration.theme.primaryTint }
        }
    }
    
    /// changeTransitionStyle
    /// - Parameter transitionStyle: TransitionStyle
    private func changeTransitionStyle(_ transitionStyle: TransitionStyle) {
        guard let topViewController = topViewController as? UIPageViewController, topViewController.transitionStyle != transitionStyle else { return }
        let controller: UIPageViewController = .init(transitionStyle: transitionStyle,
                                                     navigationOrientation: topViewController.navigationOrientation,
                                                     options: [.interPageSpacing: 0.0, .spineLocation: SpineLocation.min.rawValue])
        controller.setViewControllers(topViewController.viewControllers, direction: .forward, animated: false)
        controller.navigationItem.leftBarButtonItem = closeItem
        controller.navigationItem.rightBarButtonItem = bookmarkItem
        controller.navigationItem.title = fileURL.deletingPathExtension().lastPathComponent
        controller.toolbarItems = barItemArray
        controller.delegate = self
        controller.dataSource = self
        controller.view.backgroundColor = .clear
        setViewControllers([controller], animated: false)
    }
    
    /// notificaitonHandler
    /// - Parameter sender: Notification
    @objc private func notificaitonHandler(_ sender: Notification) {
        switch sender.name {
        case UIScreen.brightnessDidChangeNotification:
            guard let screen = sender.object as? UIScreen else { return }
            controller(menuController, brightnessActionWith: screen.brightness)
        default: break
        }
    }
}

//  MARK: - UIPageViewControllerDelegate, UIPageViewControllerDataSource
extension ParchmentViewController: UIPageViewControllerDelegate, UIPageViewControllerDataSource {
    
    /// didFinishAnimating
    /// - Parameters:
    ///   - pageViewController: UIPageViewController
    ///   - finished: Bool
    ///   - previousViewControllers: [UIViewController]
    ///   - completed: Bool
    public func pageViewController(_ pageViewController: UIPageViewController,
                                   didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        // 更新进度
        if completed == true, let first = pageViewController.viewControllers?.first as? ContentViewController, let pageWant = first.pageWant {
            bookWant?.currentIndex(pageWant.index)
            Task(priority: .userInitiated) {
                let context: NSManagedObjectContext = BookHelper.newBackgroundContext()
                try context.hub.performAndWait { context in
                    let obj: BookEntity = try context.hub.fetchAny(for: pageWant.book)
                    obj.currentIndex = pageWant.index
                    try context.hub.saveAndWait()
                }
            }
        }
    }
    
    /// viewControllerBefore
    /// - Parameters:
    ///   - pageViewController: UIPageViewController
    ///   - viewController: UIPageViewController
    /// - Returns: UIViewController
    public func pageViewController(_ pageViewController: UIPageViewController,
                                   viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let viewController = viewController as? ContentViewController,
              let pageWant: PageEntity.Want = viewController.pageWant
        else { return .none }
        let newIndex: Int64 = pageWant.index - 1
        guard let newWant: PageEntity.Want = bookWant?.pageAt(newIndex) else { return .none }
        let safeAreaInsets: UIEdgeInsets = BookHelper.safeAreaInsets
        let controller: ContentViewController = .init()
        controller.additionalSafeAreaInsets = .init(top: 0.0, left: safeAreaInsets.left, bottom: 0.0, right: safeAreaInsets.right)
        controller.reloadWith(newWant, configuration: configuration)
        return controller
    }
    
    /// viewControllerAfter
    /// - Parameters:
    ///   - pageViewController: UIPageViewController
    ///   - viewController: UIPageViewController
    /// - Returns: UIPageViewController
    public func pageViewController(_ pageViewController: UIPageViewController,
                                   viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewController = viewController as? ContentViewController,
              let bookWant = bookWant,
              let pageWant: PageEntity.Want = viewController.pageWant
        else { return .none }
        let newIndex: Int64 = pageWant.index + 1
        guard let newWant: PageEntity.Want = bookWant.pageAt(newIndex) else { return .none }
        let safeAreaInsets: UIEdgeInsets = BookHelper.safeAreaInsets
        let controller: ContentViewController = .init()
        controller.additionalSafeAreaInsets = .init(top: 0.0, left: safeAreaInsets.left, bottom: 0.0, right: safeAreaInsets.right)
        controller.reloadWith(newWant, configuration: configuration)
        return controller
    }
    
    /// pageViewControllerSupportedInterfaceOrientations
    /// - Parameter pageViewController: UIPageViewController
    /// - Returns: UIInterfaceOrientationMask
    public func pageViewControllerSupportedInterfaceOrientations(_ pageViewController: UIPageViewController) -> UIInterfaceOrientationMask {
        return [.portrait, .portraitUpsideDown]
    }
    
    /// pageViewControllerPreferredInterfaceOrientationForPresentation
    /// - Parameter pageViewController: UIPageViewController
    /// - Returns: UIInterfaceOrientation
    public func pageViewControllerPreferredInterfaceOrientationForPresentation(_ pageViewController: UIPageViewController) -> UIInterfaceOrientation {
        return .portrait
    }
    
}

//  MARK: - MenuViewControllerDelegate
extension ParchmentViewController: MenuViewControllerDelegate {
    
    /// chapterActionWith
    /// - Parameters:
    ///   - controller: MenuViewController
    ///   - newWant: ChapterEntity.Want
    internal func controller(_ controller: MenuViewController, chapterActionWith newWant: ChapterEntity.Want) {
        Task(priority: .high) {
            await controller.hideMenu()
            hideBarAction()
        }
    }
    
    internal func controller(_ controller: MenuViewController, backwardActionWith sender: UIButton) {
        
    }
    
    internal func controller(_ controller: MenuViewController, forewardActionWith sender: UIButton) {
        
    }
    
    internal func controller(_ controller: MenuViewController, progressActionWtih value: Float) {
        
    }
    
    /// brightnessActionWith
    /// - Parameters:
    ///   - controller: MenuViewController
    ///   - brightness: Float
    internal func controller(_ controller: MenuViewController, brightnessActionWith brightness: CGFloat) {
        guard configuration.brightness != brightness else { return }
        configuration.changeWith(brightness)
        view.window?.screen.brightness = brightness
    }
    
    /// fontActionWith
    /// - Parameters:
    ///   - controller: MenuViewController
    ///   - uiFont: UIFont
    internal func controller(_ controller: MenuViewController, fontActionWith uiFont: UIFont) {
        guard configuration.font.fontName != uiFont.fontName || configuration.font.pointSize != uiFont.pointSize else { return }
        configuration.changeWith(uiFont)
    }
    
    /// themeActionWith
    /// - Parameters:
    ///   - controller: MenuViewController
    ///   - theme: Theme
    internal func controller(_ controller: MenuViewController, themeActionWith theme: Theme) {
        guard configuration.theme != theme else { return }
        configuration.changeWith(theme)
        
        let barButtonItemAppearance: UIBarButtonItemAppearance = .init()
        barButtonItemAppearance.normal.titleTextAttributes = [.foregroundColor: theme.primaryTint]
        navigationBar.hub.backgroundColor(theme.barTint)
        navigationBar.hub.buttonAppearance(barButtonItemAppearance)
        navigationBar.hub.titleTextAttributes([.foregroundColor: theme.primaryTint])
        navigationBar.hub.shadowColor(.clear)
        // navigationBar.tintColor = theme.primaryTint
        toolbar.hub.configureWithOpaqueBackground()
        toolbar.hub.backgroundColor(theme.barTint)
        toolbar.hub.buttonAppearance(barButtonItemAppearance)
        toolbar.hub.shadowColor(.clear)
        // toolbar.tintColor = theme.primaryTint
        view.backgroundColor = theme.background
        closeItem.tintColor = theme.primaryTint
        bookmarkItem.tintColor = theme.primaryTint
        bottomItemArray.forEach {
            switch $0.hub.state {
            case .normal:   $0.tintColor = theme.primaryTint
            case .selected: $0.tintColor = theme.stressTint
            default: break
            }
        }
        if let topViewController = topViewController as? UIPageViewController {
            topViewController.viewControllers?.forEach { $0.traitCollectionDidChange(.current) }
        }
        menuController.viewControllers.forEach { $0.traitCollectionDidChange(.current) }
    }
    
    /// transitionActionWith
    /// - Parameters:
    ///   - controller: MenuViewController
    ///   - transitionStyle: TransitionStyle
    internal func controller(_ controller: MenuViewController, transitionActionWith transitionStyle: TransitionStyle) {
        guard configuration.transitionStyle != transitionStyle else { return }
        configuration.changeWith(transitionStyle)
        changeTransitionStyle(transitionStyle)
    }
}

#endif
