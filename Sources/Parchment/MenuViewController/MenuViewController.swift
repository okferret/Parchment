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
        case chapter
        case progress
        case other
    }
}

/// MenuViewController
class MenuViewController: UINavigationController {
    
    //  MARK: - 公开属性
    
    //  MARK: - 私有属性
    
    /// URL
    private let fileURL: URL
    /// Configuration
    private let configuration: Configuration
    
    //  MARK: - 生命周期
    
    /// 构造函数
    /// - Parameters:
    ///   - fileURL: URL
    ///   - configuration: Configuration
    internal init(forWhat fileURL: URL, configuration: Configuration) {
        self.fileURL = fileURL
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

    /// 展示菜单
    /// - Parameter menuType: MenuType
    internal func showMenuWith(_ menuType: MenuType) {
        let controller: UIViewController
        switch menuType {
        case .chapter:
            controller = ChapterViewController(forWhat: fileURL, configuration: configuration)
        case .progress:
            controller = ProgressViewController(forWhat: fileURL, configuration: configuration)
        case .other:
            controller = OtherViewController(forWhat: fileURL, configuration: configuration)
        }
        
        if viewControllers.count > 1 {
            let newArray: Array<UIViewController> = [viewControllers[0], controller]
            setViewControllers(newArray, animated: true)
        } else {
            pushViewController(controller, animated: true)
        }
    }
    
    /// 隐藏菜单
    /// - Parameters:
    internal func hideMenu() {
        guard viewControllers.count > 1 else { return }
        self.popViewController(animated: true)
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
        case .push: return MenuTransitionAnimator(transitionType: .push)
        case .pop:  return MenuTransitionAnimator(transitionType: .pop)
        default:
            return .none
        }
    }
}

#endif
