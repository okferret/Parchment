//
//  MenuViewController.swift
//  Parchment
//
//  Created by okferret on 2026/6/3.
//

#if canImport(UIKit)

import UIKit

extension MenuViewController {
    
    /// MenuType
    enum MenuType {
        case segmented
        case progress
        case other
    }
}

protocol MenuViewControllerDelegate: UINavigationControllerDelegate {
    func controller(_ controller: MenuViewController, chapterActionWith newWant: ChapterEntity.Want)
    func controller(_ controller: MenuViewController, backwardActionWith sender: UIButton)
    func controller(_ controller: MenuViewController, forewardActionWith sender: UIButton)
    func controller(_ controller: MenuViewController, progressActionWtih value: Float)
    func controller(_ controller: MenuViewController, brightnessActionWith brightness: CGFloat)
    func controller(_ controller: MenuViewController, fontActionWith uiFont: UIFont)
    func controller(_ controller: MenuViewController, themeActionWith theme: Theme)
    func controller(_ controller: MenuViewController, transitionActionWith transitionStyle: TransitionStyle)
}

/// MenuViewController
class MenuViewController: UINavigationController {
    
    //  MARK: - 公开属性
    
    /// Optional<MenuViewControllerDelegate>
    internal weak var menuDelegate: Optional<MenuViewControllerDelegate> = .none
    
    //  MARK: - 私有属性
    
    ///  BookEntity.Want
    private var bookWant: Optional<BookEntity.Want>
    /// Configuration
    private let configuration: Configuration
    
    //  MARK: - 生命周期
    
    /// 构造函数
    /// - Parameters:
    ///   - bookWant: Optional<BookEntity.Want>
    ///   - configuration: Configuration
    internal init(forWhat bookWant: Optional<BookEntity.Want>, configuration: Configuration) {
        self.bookWant = bookWant
        self.configuration = configuration
        super.init(rootViewController: UIViewController())
        self.isToolbarHidden = true
        self.isNavigationBarHidden = true
        self.delegate = self
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
        view.backgroundColor = .black.withAlphaComponent(0.15)
    }
    
    /// reloadWith
    /// - Parameter bookWant: BookEntity.Want
    internal func reloadWith(_ bookWant: BookEntity.Want) {
        guard bookWant !== self.bookWant else { return }
        self.bookWant = bookWant
    }

    /// 展示菜单
    /// - Parameter menuType: MenuType
    internal func showMenuWith(_ menuType: MenuType, completionHandler: Optional<() -> Void> = .none) {
        switch menuType {
        case .segmented:
            if let bookWant: BookEntity.Want = bookWant {
                let controller: SegmentedViewController = .init(forWhat: bookWant, configuration: configuration)
                controller.delegate = self
                showWith(controller, completionHandler: completionHandler)
            }
        case .progress:
            if let bookWant: BookEntity.Want = bookWant {
                let controller: ProgressViewController = .init(forWhat: bookWant, configuration: configuration)
                controller.delegate = self
                showWith(controller, completionHandler: completionHandler)
            }
        case .other:
            if let bookWant: BookEntity.Want = bookWant {
                let controller: ConfigureViewController = .init(forWhat: bookWant, configuration: configuration)
                controller.delegate = self
                showWith(controller, completionHandler: completionHandler)
            }
        }
    }
    
    /// showMenuWith
    /// - Parameter menuType: MenuType
    internal func showMenuWith(_ menuType: MenuType) async {
        await withCheckedContinuation { continuation in
            hideMenu { continuation.resume() }
        }
    }
    
    /// showWith
    /// - Parameters:
    ///   - controller: UIViewController
    ///   - completionHandler: Optional<() -> Void>
    private func showWith(_ controller: UIViewController, completionHandler: Optional<() -> Void> = .none) {
        if viewControllers.count > 1 {
            let newArray: Array<UIViewController> = [viewControllers[0], controller]
            setViewControllers(newArray, animated: true)
        } else {
            pushViewController(controller, animated: true)
        }
        transitionCoordinator?.animate(alongsideTransition: .none) { _ in
            completionHandler?()
        }
    }
    
    /// 隐藏菜单
    /// - Parameters:
    internal func hideMenu(_ completionHandler: Optional<() -> Void> = .none) {
        guard viewControllers.count > 1 else { return }
        self.popViewController(animated: true)
        transitionCoordinator?.animate(alongsideTransition: .none) { _ in
            completionHandler?()
        }
    }
    
    /// hideMenu
    internal func hideMenu() async {
        await withCheckedContinuation { continuation in
            hideMenu { continuation.resume() }
        }
    }
}

//  MARK: - UINavigationControllerDelegate
extension MenuViewController: UINavigationControllerDelegate {
    
    /// animationControllerFor
    /// - Parameters:
    ///   - navigationController: UINavigationController
    ///   - operation: UINavigationController.Operation
    ///   - fromVC: UIViewController
    ///   - toVC: UIViewController
    /// - Returns: UIViewControllerAnimatedTransitioning
    internal func navigationController(_ navigationController: UINavigationController,
                                       animationControllerFor operation: UINavigationController.Operation,
                                       from fromVC: UIViewController,
                                       to toVC: UIViewController) -> (any UIViewControllerAnimatedTransitioning)? {
        switch operation {
        case .push: return MenuTransitionAnimator(.push)
        case .pop:  return MenuTransitionAnimator(.pop)
        default:
            return .none
        }
    }
}

//  MARK: -  ProgressViewControllerDelegate, ConfigureViewControllerDelegate
extension MenuViewController: ProgressViewControllerDelegate, ConfigureViewControllerDelegate, SegmentedViewControllerDelegate {
    
    /// chapterActionWith
    /// - Parameters:
    ///   - controller: SegmentedViewController
    ///   - newWant: ChapterEntity.Want
    internal func controller(_ controller: SegmentedViewController, chapterActionWith newWant: ChapterEntity.Want) {
        menuDelegate?.controller(self, chapterActionWith: newWant)
    }
  
    /// backwardActionWith
    /// - Parameters:
    ///   - controller: ProgressViewController
    ///   - sender: UIButton
    internal func controller(_ controller: ProgressViewController, backwardActionWith sender: UIButton) {
        menuDelegate?.controller(self, backwardActionWith: sender)
    }
    
    /// forewardActionWith
    /// - Parameters:
    ///   - controller: ProgressViewController
    ///   - sender: UIButton
    internal func controller(_ controller: ProgressViewController, forewardActionWith sender: UIButton) {
        menuDelegate?.controller(self, forewardActionWith: sender)
    }
    
    /// progressActionWtih
    /// - Parameters:
    ///   - controller: ProgressViewController
    ///   - value: Float
    internal func controller(_ controller: ProgressViewController, progressActionWtih value: Float) {
        menuDelegate?.controller(self, progressActionWtih: value)
    }
    
    /// brightnessActionWith
    /// - Parameters:
    ///   - controller: ConfigureViewController
    ///   - brightness: CGFloat
    internal func controller(_ controller: ConfigureViewController, brightnessActionWith brightness: CGFloat) {
        menuDelegate?.controller(self, brightnessActionWith: brightness)
    }
    
    /// fontActionWith
    /// - Parameters:
    ///   - controller: ConfigureViewController
    ///   - value: Float
    internal func controller(_ controller: ConfigureViewController, fontActionWith value: Float) {
        menuDelegate?.controller(self, fontActionWith: .pingfangSC(ofSize: CGFloat(value)))
    }
    
    /// themeActionWith
    /// - Parameters:
    ///   - controller: ConfigureViewController
    ///   - theme: Theme
    internal func controller(_ controller: ConfigureViewController, themeActionWith theme: Theme) {
        menuDelegate?.controller(self, themeActionWith: theme)
    }
    
    /// transitionActionWith
    /// - Parameters:
    ///   - controller: ConfigureViewController
    ///   - transitionStyle: TransitionStyle
    internal func controller(_ controller: ConfigureViewController, transitionActionWith transitionStyle: TransitionStyle) {
        menuDelegate?.controller(self, transitionActionWith: transitionStyle)
    }
    
}

#endif
