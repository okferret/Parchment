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
        _loadingView.color = .white
        return _loadingView
    }()
    
    private lazy var indexLabel: UILabel = {
        let _label: UILabel = .init(frame: .zero)
        _label.font = .systemFont(ofSize: 12.0, weight: .medium)
        _label.textColor = configuration.theme.secondaryText
        _label.textAlignment = .right
        _label.translatesAutoresizingMaskIntoConstraints = false
        return _label
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
    
    /// Optional<UIPageViewController>
    private var pageViewController: Optional<UIPageViewController> {
        return topViewController as? UIPageViewController
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
        // 添加通知：监听系统亮度变化，同步回配置
        // NotificationCenter.default.addObserver(self, selector: #selector(notificationHandler(_:)), name: UIScreen.brightnessDidChangeNotification, object: .none)
        brightness = keyWindow?.screen.brightness ?? 0.5
        keyWindow?.screen.brightness = configuration.brightness
        // 解析数据
        parseWith(fileURL)
    }

    deinit {
        print(#function, "=>", (#file as NSString).lastPathComponent)
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
        
        view.insertSubview(indexLabel, belowSubview: toolbar)
        NSLayoutConstraint.activate([
            indexLabel.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16.0),
            indexLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -16.0)
        ])
    }
    
    /// 解析书籍
    /// - Parameters:
    ///   - fileURL: URL
    ///   - useCached: Bool
    ///   - priority: TaskPriority
    private func parseWith(_ fileURL: URL, useCached: Bool = true, priority: TaskPriority = .userInitiated) {
        // @MainActor：UI 操作（loadingView/menuController/gotoPage/present）在主线程执行；
        // 真正的耗时解析由 BookHelper.parseWith 内部 Task(priority:) 切换到后台，await 期间不阻塞主线程。
        Task<Void, Error>(priority: priority) { @MainActor in
            guard let keyWindow = UIApplication.shared.hub.keyWindow else { return }
            let safeAreaInsets: UIEdgeInsets = BookHelper.safeAreaInsets
            let safeArea: CGSize = keyWindow.bounds.inset(by: safeAreaInsets).size
            loadingView.hub.startAnimating()
            do {
                let newWant: BookEntity.Want = try await BookHelper.parseWith(fileURL,
                                                                              safeArea: safeArea,
                                                                              textAttributes: configuration.textAttributes,
                                                                              useCached: useCached)
                if bookWant == .none {
                    bookWant = newWant
                } else {
                    bookWant?.remakeWith(newWant)
                }
                menuController.reloadWith(newWant)
                if let pageWant: PageEntity.Want = bookWant?.pageAt(.none) {
                    gotoPageWith(pageWant, direction: .forward, animated: false, completionHandler: .none)
                }
            } catch {
                let controller: UIAlertController = .init(title: "操作提醒", message: error.localizedDescription, preferredStyle: .alert)
                controller.addAction(.init(title: "关闭", style: .default, handler: { _ in
                    self.dismiss(animated: true, completion: .none)
                }))
                present(controller, animated: true, completion: .none)
            }
            loadingView.hub.stopAnimating()
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
            
        case bookmarkItem where sender.hub.state == .normal: // 添加书签
            guard let pageViewController = pageViewController,
                  let first = pageViewController.viewControllers?.first as? ContentViewController,
                  let pageWant = first.pageWant
            else { return }
            Task(priority: .userInitiated) {
                let context: NSManagedObjectContext = BookHelper.newBackgroundContext()
                try context.hub.performAndWait { context in
                    let freq: NSFetchRequest<MarkEntity> = MarkEntity.fetchRequest()
                    freq.predicate = .init(format: "book == %@ AND offset == %lld", pageWant.book, pageWant.offset)
                    let objs: Array<MarkEntity> = try context.fetch(freq)
                    guard objs.isEmpty == true else { return }
                    let obj: MarkEntity = .init(context: context)
                    obj.book = try context.hub.fetchAny(for: pageWant.book)
                    obj.offset = pageWant.offset
                    obj.length = pageWant.length
                    obj.createdAt = .init()
                    // pageWant.text 为按需读取文件的计算属性，取一次到局部变量
                    let pageText: String = pageWant.text
                    obj.sketchText = String(pageText.prefix(100)).components(separatedBy: .newlines).joined()
                    try context.hub.saveAndWait()
                }
                // UI 更新切回主线程
                await MainActor.run {
                    bookmarkItem.hub.state = .selected
                    bookmarkItem.tintColor = configuration.theme.stressTint
                }
            }
            
        case bookmarkItem where sender.hub.state == .selected: // 移除书签
            guard let pageViewController = pageViewController,
                  let first = pageViewController.viewControllers?.first as? ContentViewController,
                  let pageWant = first.pageWant
            else { return }
            Task(priority: .userInitiated) {
                let context: NSManagedObjectContext = BookHelper.newBackgroundContext()
                try context.hub.performAndWait { context in
                    let freq: NSFetchRequest<MarkEntity> = MarkEntity.fetchRequest()
                    freq.predicate = .init(format: "book == %@ AND offset == %lld", pageWant.book, pageWant.offset)
                    let objs: Array<MarkEntity> = try context.fetch(freq)
                    objs.forEach { context.delete($0) }
                    try context.hub.saveAndWait()
                }
                // UI 更新切回主线程
                await MainActor.run {
                    bookmarkItem.hub.state = .normal
                    bookmarkItem.tintColor = configuration.theme.primaryTint
                }
            }
         
        case chapterItem where sender.hub.state == .normal:
            Set(bottomItemArray).subtracting([chapterItem]).forEach { $0.hub.state = .normal; $0.tintColor = configuration.theme.primaryTint }
            chapterItem.tintColor = configuration.theme.stressTint
            chapterItem.hub.state = .selected
            menuController.showMenuWith(.segmented)
            setNavigationBarHidden(true, animated: true)
            
        case chapterItem where sender.hub.state == .selected:
            chapterItem.tintColor = configuration.theme.primaryTint
            chapterItem.hub.state = .normal
            menuController.hideMenu()
            setNavigationBarHidden(false, animated: true)
            
        case progressItem where sender.hub.state == .normal:
            Set(bottomItemArray).subtracting([progressItem]).forEach { $0.hub.state = .normal; $0.tintColor = configuration.theme.primaryTint }
            progressItem.tintColor = configuration.theme.stressTint
            progressItem.hub.state = .selected
            menuController.showMenuWith(.progress)
            setNavigationBarHidden(false, animated: true)
            
        case progressItem where sender.hub.state == .selected:
            progressItem.tintColor = configuration.theme.primaryTint
            progressItem.hub.state = .normal
            menuController.hideMenu()
            setNavigationBarHidden(false, animated: true)
        
        case otherItem where sender.hub.state == .normal:
            Set(bottomItemArray).subtracting([otherItem]).forEach { $0.hub.state = .normal; $0.tintColor = configuration.theme.primaryTint }
            otherItem.tintColor = configuration.theme.stressTint
            otherItem.hub.state = .selected
            menuController.showMenuWith(.other)
            setNavigationBarHidden(false, animated: true)
            
        case otherItem where sender.hub.state == .selected:
            otherItem.tintColor = configuration.theme.primaryTint
            otherItem.hub.state = .normal
            menuController.hideMenu()
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
                    
                case _ where leftArea.contains(location) == true && pageViewController?.transitionStyle == .scroll:
                    if let bookWant = bookWant {
                        backwardWith(bookWant)
                    }
                    
                case _ where rightArea.contains(location) == true && pageViewController?.transitionStyle == .scroll:
                    if let bookWant = bookWant{
                        forwardWith(bookWant)
                    }
                default: break
                }
            }
        }
    }
    
    /// gotoPageWith
    /// - Parameters:
    ///   - pageWant: PageEntity.Want
    ///   - direction: NavigationDirection
    ///   - animated: Bool
    ///   - completionHandler: @escaping () -> Void
    private func gotoPageWith(_ pageWant: PageEntity.Want, direction: NavigationDirection, animated: Bool, completionHandler: Optional<() -> Void>) {
        guard let pageViewController = pageViewController else { return }
        let controller: ContentViewController = .init()
        controller.reloadWith(pageWant, configuration: configuration)
        let previousViewControllers: Array<UIViewController> = pageViewController.viewControllers ?? []
        pageViewController.setViewControllers([controller], direction: direction, animated: animated) {[weak pageViewController] finished in
            defer { completionHandler?() }
            guard let pageViewController = pageViewController else { return }
            pageViewController.delegate?.pageViewController?(pageViewController,  didFinishAnimating: true,
                                                             previousViewControllers: previousViewControllers, transitionCompleted: true)
        }
    }
    
    /// 下一页
    /// - Parameters:
    ///   - bookWant: BookEntity.Want
    ///   - pageViewController: UIPageViewController
    private func forwardWith(_ bookWant: BookEntity.Want) {
        let newIndex: Int64 = bookWant.currentIndex + 1
        if let newWant: PageEntity.Want = bookWant.pageAt(newIndex) {
            tapGesture.isEnabled = false
            gotoPageWith(newWant, direction: .forward, animated: true) {[weak tapGesture] in
                tapGesture?.isEnabled = true
            }
        }
    }
    
    /// 上一页
    /// - Parameters:
    ///   - bookWant: BookEntity.Want
    ///   - pageViewController: UIPageViewController
    private func backwardWith(_ bookWant: BookEntity.Want) {
        let newIndex: Int64 = bookWant.currentIndex - 1
        if let newWant: PageEntity.Want = bookWant.pageAt(newIndex) {
            tapGesture.isEnabled = false
            gotoPageWith(newWant, direction: .reverse, animated: true) {[weak tapGesture] in
                tapGesture?.isEnabled = true
            }
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
        guard let pageViewController = pageViewController, pageViewController.transitionStyle != transitionStyle else { return }
        let controller: UIPageViewController = .init(transitionStyle: transitionStyle,
                                                     navigationOrientation: pageViewController.navigationOrientation,
                                                     options: [.interPageSpacing: 0.0, .spineLocation: SpineLocation.min.rawValue])
        controller.setViewControllers(pageViewController.viewControllers, direction: .forward, animated: false)
        controller.navigationItem.leftBarButtonItem = closeItem
        controller.navigationItem.rightBarButtonItem = bookmarkItem
        controller.navigationItem.title = fileURL.deletingPathExtension().lastPathComponent
        controller.toolbarItems = barItemArray
        controller.delegate = self
        controller.dataSource = self
        controller.view.backgroundColor = .clear
        setViewControllers([controller], animated: false)
    }
    
    /// notificationHandler
    /// - Parameter sender: Notification
    @objc private func notificationHandler(_ sender: Notification) {
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
                                   didFinishAnimating finished: Bool,
                                   previousViewControllers: [UIViewController],
                                   transitionCompleted completed: Bool) {
        guard completed == true,
              let first = pageViewController.viewControllers?.first as? ContentViewController,
              let pageWant = first.pageWant,
              let bookWant = bookWant
        else { return }
        // 更新进度
        bookWant.currentIndex(pageWant.index)
        Task(priority: .userInitiated) {
            // 更新进度
            let context: NSManagedObjectContext = BookHelper.newBackgroundContext()
            try context.hub.performAndWait { context in
                let obj: BookEntity = try context.hub.fetchAny(for: pageWant.book)
                obj.currentIndex = pageWant.index
                try context.hub.saveAndWait()
            }
            // 查询数据库
            let marked: Bool = try context.hub.performAndWait { context in
                let freq: NSFetchRequest<MarkEntity> = MarkEntity.fetchRequest()
                freq.predicate = .init(format: "book == %@ AND offset >= %lld AND offset < %lld", pageWant.book, pageWant.offset, pageWant.offset + pageWant.length)
                return try context.count(for: freq) > 0
            }
            // UI 更新切回主线程
            await MainActor.run {
                if marked == true {
                    bookmarkItem.hub.state = .selected
                    bookmarkItem.tintColor = configuration.theme.stressTint
                } else {
                    bookmarkItem.hub.state = .normal
                    bookmarkItem.tintColor = configuration.theme.primaryTint
                }
            }
        }
        // 更新角标
        indexLabel.text = "\(pageWant.index + 1)/\(bookWant.totalUnitCount)"
        // 发送通知
        NotificationCenter.default.post(name: BookHelper.progressNotification, object: .none, userInfo: [
            "bookWant": bookWant, "currentIndex": bookWant.currentIndex, "totalUnitCount": bookWant.totalUnitCount
        ])
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
        let controller: ContentViewController = .init()
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
        let controller: ContentViewController = .init()
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
        gotoOffsetWith(newWant.book, offset: newWant.offset, in: controller)
    }
    
    /// bookmarkActionWith
    /// - Parameters:
    ///   - controller: MenuViewController
    ///   - newWant: MarkEntity.Want
    internal func controller(_ controller: MenuViewController, bookmarkActionWith newWant: MarkEntity.Want) {
        gotoOffsetWith(newWant.book, offset: newWant.offset, in: controller)
    }
    
    /// 跳转到指定字节偏移所在的页（章节/书签共用）
    /// - Parameters:
    ///   - book: 书籍 NSManagedObjectID
    ///   - offset: 目标字节偏移
    ///   - controller: MenuViewController，跳转后隐藏其菜单
    private func gotoOffsetWith(_ book: NSManagedObjectID, offset: Int64, in controller: MenuViewController) {
        Task(priority: .userInitiated) {
            let context: NSManagedObjectContext = BookHelper.newBackgroundContext()
            let pageWant: Optional<PageEntity.Want> = try context.hub.performAndWait { context in
                let freq: NSFetchRequest<PageEntity> = PageEntity.fetchRequest()
                freq.sortDescriptors = [.init(key: #keyPath(PageEntity.offset), ascending: false)]
                freq.fetchLimit = 1
                freq.predicate = .init(format: "book == %@ AND offset <= %lld", book, offset)
                return try context.fetch(freq).first?.hub.want
            }
            if let pageWant = pageWant,
               let first = pageViewController?.viewControllers?.first as? ContentViewController, pageWant.objectID != first.pageWant?.objectID {
                gotoPageWith(pageWant, direction: .forward, animated: false, completionHandler: .none)
            }
            await controller.hideMenu()
            hideBarAction()
        }
    }
    
    /// backwardActionWith
    /// - Parameters:
    ///   - controller: MenuViewController
    ///   - sender: UIButton
    internal func controller(_ controller: MenuViewController, backwardActionWith sender: UIButton) {
        if let bookWant = bookWant {
            backwardWith(bookWant)
        }
    }
    
    /// forwardActionWith
    /// - Parameters:
    ///   - controller: MenuViewController
    ///   - sender: UIButton
    internal func controller(_ controller: MenuViewController, forwardActionWith sender: UIButton) {
        if let bookWant = bookWant {
            forwardWith(bookWant)
        }
    }
    
    /// progressActionWith
    /// - Parameters:
    ///   - controller: MenuViewController
    ///   - value: Float
    internal func controller(_ controller: MenuViewController, progressActionWith value: Float) {
        guard let bookWant = bookWant, bookWant.totalUnitCount > 0 else { return }
        // 钳制 index 到 [0, totalUnitCount - 1]，避免浮点误差或 totalUnitCount 异常时越界
        let rawIndex: Int64 = Int64(Float(bookWant.totalUnitCount - 1) * value)
        let index: Int64 = min(max(0, rawIndex), bookWant.totalUnitCount - 1)
        if let newWant: PageEntity.Want = bookWant.pageAt(index) {
            gotoPageWith(newWant, direction: .forward, animated: false, completionHandler: .none)
        }
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
        // 分页
        parseWith(fileURL, useCached: false)
        // 同步其他书籍
        Task(priority: .userInitiated) {
            let relativeUID: String = BookHelper.relativeUID(for: fileURL)
            let context: NSManagedObjectContext = BookHelper.newBackgroundContext()
            try context.hub.performAndWait { context in
                let freq: NSFetchRequest<BookEntity> = BookEntity.fetchRequest()
                freq.predicate = .init(format: "relativeUID != %@", relativeUID)
                try context.fetch(freq).forEach { $0.isReady = false }
                try context.hub.saveAndWait()
            }
        }
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
        (bottomItemArray + [bookmarkItem]).forEach {
            switch $0.hub.state {
            case .normal:   $0.tintColor = theme.primaryTint
            case .selected: $0.tintColor = theme.stressTint
            default: break
            }
        }
        pageViewController?.viewControllers?.forEach { $0.traitCollectionDidChange(.current) }
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
