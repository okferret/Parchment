//
//  MenuTransitionAnimator.swift
//  Parchment
//
//  Created by okferret on 2026/6/3.
//

#if canImport(UIKit)

import UIKit

/// MenuTransitionAnimator
class MenuTransitionAnimator: NSObject , UIViewControllerAnimatedTransitioning {
    
    /// TransitionType
    enum TransitionType {
        case push
        case pop
    }
    
    /// TransitionType
    private let transitionType: TransitionType
    
    /// TimeInterval
    private let duration: TimeInterval
    
    /// 构造函数
    /// - Parameters:
    ///   - transitionType: TransitionType
    ///   - duration: TimeInterval
    internal init(transitionType: TransitionType, duration: TimeInterval = 0.25) {
        self.transitionType = transitionType
        self.duration = duration
        super.init()
    }
    
    /// transitionDuration
    /// - Parameter transitionContext: UIViewControllerContextTransitioning
    /// - Returns: TimeInterval
    internal func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }
    
    /// animateTransition
    /// - Parameter transitionContext: UIViewControllerContextTransitioning
    internal func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromVC = transitionContext.viewController(forKey: .from),
              let toVC = transitionContext.viewController(forKey: .to)
        else {
            transitionContext.completeTransition(false)
            return
        }
        
        let containerView = transitionContext.containerView
        let toFrame = transitionContext.finalFrame(for: toVC)
        
        switch transitionType {
        case .push:
            guard let toVC = toVC as? MenuContentViewController else {
                transitionContext.completeTransition(false)
                return
            }
            // Push: 从屏幕底部外进入
            toVC.view.frame = toFrame
            toVC.view.layoutIfNeeded()
            containerView.addSubview(toVC.view)
            let newFrame: CGRect = toVC.contentView.frame
            toVC.contentView.frame = newFrame.offsetBy(dx: 0.0, dy: newFrame.height)
            
            UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseOut], animations: {
                toVC.contentView.frame = newFrame
                if let fromVC = fromVC as? MenuContentViewController {
                    fromVC.contentView.frame.origin.y = newFrame.minY
                }
            }) { finished in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
            
        case .pop:
            // Pop: 向屏幕底部退出
            guard let fromVC = fromVC as? MenuContentViewController else {
                transitionContext.completeTransition(false)
                return
            }
            let newFrame: CGRect = fromVC.contentView.frame
            containerView.insertSubview(toVC.view, belowSubview: fromVC.view)
            UIView.animate(withDuration: duration,  delay: 0, options: [.curveEaseIn], animations: {
                fromVC.contentView.frame = newFrame.offsetBy(dx: 0, dy: newFrame.height)
            }) { finished in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        }
    }
}


#endif
