//
//  UISegmentedView.swift
//  Parchment
//
//  Created by okferret on 2026/6/5.
//

#if canImport(UIKit)

import UIKit

/// UISegmentedView
class UISegmentedView: UISegmentedControl {
    
    //  MARK: - 公开属性
    
    /// Optional<UIColor>
    internal var segmentTintColor: Optional<UIColor> = .white {
        didSet { setNeedsLayout() }
    }

    /// 构造函数
    /// - Parameter items: [Any]
    internal override init(items: [Any]?) {
        super.init(items: items)
        self.selectedSegmentTintColor = .clear
        self.setDividerImage(.init(), forLeftSegmentState: .normal, rightSegmentState: .normal, barMetrics: .default)
        self.setDividerImage(.init(), forLeftSegmentState: .normal, rightSegmentState: .normal, barMetrics: .compact)
        self.setDividerImage(.init(), forLeftSegmentState: .normal, rightSegmentState: .normal, barMetrics: .defaultPrompt)
        self.setDividerImage(.init(), forLeftSegmentState: .normal, rightSegmentState: .normal, barMetrics: .compactPrompt)
    }
    
    /// 构造函数
    /// - Parameter coder: NSCoder
    internal required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// layoutSubviews
    internal override func layoutSubviews() {
        super.layoutSubviews()
        for subview in subviews where subview is UIImageView && subview.subviews.isEmpty == true {
            if let newView = subview.viewWithTag(1001) {
                newView.layer.cornerRadius = newView.bounds.height * 0.5
                newView.layer.masksToBounds = true
                newView.backgroundColor = segmentTintColor
            } else {
                let newView: UIView = .init(frame: subview.bounds.insetBy(dx: 5.0, dy: 5.0))
                newView.tag = 1001
                newView.layer.cornerRadius = newView.bounds.height * 0.5
                newView.layer.masksToBounds = true
                newView.backgroundColor = segmentTintColor
                subview.addSubview(newView)
            }
        }
        layer.cornerRadius = bounds.height * 0.5
        layer.masksToBounds = true
    }
}

#endif
