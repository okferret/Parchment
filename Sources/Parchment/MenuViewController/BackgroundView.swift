//
//  BackgroundView.swift
//  Parchment
//
//  Created by okferret on 2026/6/4.
//

#if canImport(UIKit)

import UIKit

/// BackgroundView
class BackgroundView: UIView {

    //  MARK: - 公开属性
    
    /// Optional<UIImage>
    internal var backgroundImage: Optional<UIImage> {
        get { imageView.image }
        set { imageView.image = newValue }
    }
    
    /// UIColor
    internal var backgroundImageTint: UIColor {
        get { imageView.tintColor }
        set { imageView.tintColor = newValue }
    }
    
    /// Optional<String>
    internal var text: Optional<String> {
        get { textLabel.text }
        set { textLabel.text = newValue }
    }
    
    /// UIColor
    internal var textColor: UIColor {
        get { textLabel.textColor }
        set { textLabel.textColor = newValue }
    }
    
    /// UIFont
    internal var textFont: UIFont {
        get { textLabel.font }
        set { textLabel.font = newValue }
    }
    
    /// CGFloat
    internal var spacing: CGFloat {
        get { stackView.spacing }
        set { stackView.spacing = newValue }
    }
    
    /// UIOffset
    internal var offset: UIOffset = .zero {
        didSet { setNeedsUpdateConstraints() }
    }
    
    //  MARK: - 私有属性
    
    /// UIImageView
    private lazy var imageView: UIImageView = {
        let _imageView: UIImageView = .init(frame: .zero)
        _imageView.contentMode = .scaleAspectFit
        _imageView.translatesAutoresizingMaskIntoConstraints = false
        _imageView.widthAnchor.constraint(equalToConstant: 180.0).isActive = true
        _imageView.heightAnchor.constraint(equalToConstant: 180.0).isActive = true 
        return _imageView
    }()
    
    /// UILabel
    private lazy var textLabel: UILabel = {
        let _label: UILabel = .init(frame: .zero)
        _label.font = .systemFont(ofSize: 14.0)
        _label.textColor = .lightGray
        return _label
    }()
    
    /// UIStackView
    private lazy var stackView: UIStackView = {
        let _stackView: UIStackView = .init(arrangedSubviews: [imageView, textLabel])
        _stackView.axis = .vertical
        _stackView.alignment = .center
        _stackView.spacing = 12.0
        _stackView.translatesAutoresizingMaskIntoConstraints = false
        return _stackView
    }()
    
    //  MARK: - 生命周期
    
    /// 构造函数
    /// - Parameter frame: CGRect
    internal override init(frame: CGRect) {
        super.init(frame: frame)
        // 初始化
        initialize()
    }
    
    /// 构造函数
    /// - Parameter coder: NSCoder
    internal required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// updateConstraints
    internal override func updateConstraints() {
        defer { super.updateConstraints() }
        if let centerXAnchor = constraints.first(where: { $0.hub.firstItem() === stackView && $0.firstAttribute == .centerX }) {
            centerXAnchor.constant = offset.horizontal
        }
        if let centerYAnchor = constraints.first(where: { $0.hub.firstItem() === stackView && $0.firstAttribute == .centerY }) {
            centerYAnchor.constant = offset.vertical
        }
    }
}

extension BackgroundView {
    
    /// 初始化
    private func initialize() {
        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: safeAreaLayoutGuide.centerXAnchor, constant: offset.horizontal),
            stackView.centerYAnchor.constraint(equalTo: safeAreaLayoutGuide.centerYAnchor, constant: offset.vertical)
        ])
    }
}

#endif
