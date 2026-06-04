//
//  UISliderView.swift
//  Parchment
//
//  Created by okferret on 2026/6/3.
//

#if canImport(UIKit)

import UIKit

/// UISliderViewDelegate
protocol UISliderViewDelegate: AnyObject {
    
    /// thumbTextAt trackValue
    /// - Parameters:
    ///   - sliderView: UISliderView
    ///   - trackValue: Float
    /// - Returns: Optional<String>
    func sliderView(_ sliderView: UISliderView, thumbTextAt trackValue: Float) -> Optional<String>
    
    /// trackValueAction
    /// - Parameters:
    ///   - sliderView: UISliderView
    ///   - trackValue: Float
    func sliderView(_ sliderView: UISliderView, trackValueAction trackValue: Float)
    
    /// slideAction
    /// - Parameters:
    ///   - sliderView: UISliderView
    ///   - slideValue: Float
    func sliderView(_ sliderView: UISliderView, slideAction slideValue: Float)
}

extension UISliderViewDelegate {
    /// thumbTextAt
    internal func sliderView(_ sliderView: UISliderView, thumbTextAt trackValue: Float) -> Optional<String> { return .none }
    /// sliderValueAction
    internal func sliderView(_ sliderView: UISliderView, slideAction sliderValue: Float) {}
}

/// UISliderView
class UISliderView: UISlider {
    
    //  MARK: - 公开属性
    
    /// Array<Float>
    internal var trackValues: Array<Float> = []
    
    /// Bool
    internal var isTrackValues: Bool = true
    
    /// Optional<UISliderViewDelegate>
    internal weak var delegate: Optional<UISliderViewDelegate> = .none
    
    /// Optional<UIColor>
    internal override var maximumTrackTintColor: Optional<UIColor> {
        get { maxTrackView.backgroundColor }
        set { maxTrackView.backgroundColor = newValue }
    }
    
    /// Optional<UIColor>
    internal override var minimumTrackTintColor: Optional<UIColor> {
        get { minTrackView.backgroundColor }
        set { minTrackView.backgroundColor = newValue }
    }
    
    /// Optional<String>
    internal var minimumValueText: Optional<String> {
        get { minimumValueLabel.text }
        set {
            minimumValueLabel.text = newValue
            minimumValueLabel.isHidden = (newValue == .none || newValue?.isEmpty == true || minimumValueImage != .none)
        }
    }
    
    /// Optional<String>
    internal var maximumValueText: Optional<String> {
        get { maximumValueLabel.text }
        set {
            maximumValueLabel.text = newValue
            maximumValueLabel.isHidden = (newValue == .none || newValue?.isEmpty == true || minimumValueImage != .none)
        }
    }
    
    /// UIColor
    internal var minimumValueTextColor: UIColor {
        get { minimumValueLabel.textColor }
        set { minimumValueLabel.textColor = newValue }
    }
    
    /// UIColor
    internal var maximumValueTextColor: UIColor {
        get { maximumValueLabel.textColor }
        set { maximumValueLabel.textColor = newValue }
    }
    
    /// UIColor
    internal var thumbTextColor: UIColor {
        get { thumbTextLabel.textColor }
        set { thumbTextLabel.textColor = newValue }
    }
    
    /// UIFont
    internal var minimumValueTextFont: UIFont {
        get { minimumValueLabel.font }
        set { minimumValueLabel.font = newValue }
    }
    
    /// UIFont
    internal var maximumValueTextFont: UIFont {
        get { maximumValueLabel.font }
        set { maximumValueLabel.font = newValue }
    }
    
    /// UIFont
    internal var thumbTextFont: UIFont {
        get { thumbTextLabel.font }
        set { thumbTextLabel.font = newValue }
    }
    
    /// Optional<UIImage>
    internal override var minimumValueImage: Optional<UIImage> {
        get { minimumValueImageView.image }
        set {
            minimumValueImageView.image = newValue
            minimumValueImageView.sizeToFit()
            minimumValueImageView.isHidden = newValue == .none
            minimumValueLabel.isHidden = newValue != .none
        }
    }
    
    /// Optional<UIImage>
    internal override var maximumValueImage: Optional<UIImage> {
        get { maximumValueImagView.image }
        set {
            maximumValueImagView.image = newValue
            maximumValueImagView.sizeToFit()
            maximumValueImagView.isHidden = newValue == .none
            maximumValueLabel.isHidden = newValue != .none
        }
    }
    
    //  MARK: - 私有属性
    
    /// UIImageView
    private lazy var minimumValueImageView: UIImageView = {
        let _imgView: UIImageView = .init(frame: .zero)
        _imgView.translatesAutoresizingMaskIntoConstraints = false
        _imgView.isHidden = true
        return _imgView
    }()
    
    /// UIImageView
    private lazy var maximumValueImagView: UIImageView = {
        let _imgView: UIImageView = .init(frame: .zero)
        _imgView.translatesAutoresizingMaskIntoConstraints = false
        _imgView.isHidden = true
        return _imgView
    }()
    
    /// UILabel
    private lazy var minimumValueLabel: UILabel = {
        let _label: UILabel = .init(frame: .zero)
        _label.font = .systemFont(ofSize: 14.0)
        _label.textColor = .systemGray
        _label.translatesAutoresizingMaskIntoConstraints = false
        _label.textAlignment = .left
        _label.isHidden = true
        return _label
    }()
    
    /// UILabel
    private lazy var maximumValueLabel: UILabel = {
        let _label: UILabel = .init(frame: .zero)
        _label.font = .systemFont(ofSize: 14.0)
        _label.textColor = .systemGray
        _label.translatesAutoresizingMaskIntoConstraints = false
        _label.textAlignment = .right
        _label.isHidden = true
        return _label
    }()
    
    /// track label
    private lazy var thumbTextLabel: UILabel = {
        let _label: UILabel = .init(frame: .zero)
        _label.font = .systemFont(ofSize: 14.0, weight: .medium)
        _label.textColor = .systemGray
        _label.translatesAutoresizingMaskIntoConstraints = false
        _label.textAlignment = .center
        _label.isHidden = true
        return _label
    }()
  
    /// min track view
    private lazy var minTrackView: UIView = {
        let _trackView: UIView = .init(frame: .zero)
        _trackView.translatesAutoresizingMaskIntoConstraints = false
        return _trackView
    }()
    
    /// max track view
    private lazy var maxTrackView: UIView = {
        let _trackView: UIView = .init(frame: .zero)
        _trackView.translatesAutoresizingMaskIntoConstraints = false
        return _trackView
    }()
    
    //  MARK: - 生命周期
    
    /// 构造函数
    /// - Parameter frame: CGRect
    internal override init(frame: CGRect) {
        super.init(frame: frame)
        super.minimumTrackTintColor = .clear
        super.maximumTrackTintColor = .clear
        super.setMaximumTrackImage(.init(), for: .normal)
        super.setMinimumTrackImage(.init(), for: .normal)
        super.backgroundColor = .clear
        self.isContinuous = false
        // 初始化
        initialize()
        // add target
        addTarget(self, action: #selector(trackActionHandler(_:)), for: .valueChanged)
    }
    
    /// 构造函数
    /// - Parameter coder: NSCoder
    internal required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// touchesBegan
    /// - Parameters:
    ///   - touches: Set<UITouch>
    ///   - event: UIEvent
    internal override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard let touch: UITouch = touches.first else { return }
        let location: CGPoint = touch.location(in: self)
        let newValue: Float = Float((location.x / bounds.width)) * (maximumValue - minimumValue) + minimumValue
        if trackValues.isEmpty == true {
            if value != newValue {
                self.value = newValue
                sendActions(for: .valueChanged)
            }
        } else {
            if let trackValue: Float = trackValues.min(by: { abs($0 - newValue) < abs($1 - newValue) }), value != trackValue {
                self.value = trackValue
                sendActions(for: .valueChanged)
            } else {
                self.value = trackValues.min() ?? 0.0
                sendActions(for: .valueChanged)
            }
        }
    }

    /// thumbRect forBounds
    /// - Parameters:
    ///   - bounds: CGRect
    ///   - rect: CGRect
    ///   - value: Float
    /// - Returns: CGRect
    internal override func thumbRect(forBounds bounds: CGRect, trackRect rect: CGRect, value: Float) -> CGRect {
        var thumbRect: CGRect = super.thumbRect(forBounds: bounds, trackRect: rect, value: value)
        if let widthAnchor = minTrackView.constraints.first(where: { $0.firstAttribute == .width }) {
            if value == 0.0 {
                widthAnchor.constant = 0.0
            } else if value == 1.0 {
                widthAnchor.constant = bounds.width
            } else {
                widthAnchor.constant = thumbRect.midX
            }
        }
        // 更新 文本
        if let thumbText: String = delegate?.sliderView(self, thumbTextAt: value), thumbText.isEmpty == false {
            thumbTextLabel.text = thumbText
            thumbTextLabel.isHidden = false
        } else {
            thumbTextLabel.text = .none
            thumbTextLabel.isHidden = true
        }
        thumbTextLabel.center = .init(x: thumbRect.midX, y: thumbRect.midY)
        // next
        delegate?.sliderView(self, slideAction: value)
        return thumbRect
    }
    
    /// didMoveToWindow
    internal override func didMoveToWindow() {
        super.didMoveToWindow()
        /// bringSubviewToFront
        bringSubviewToFront(thumbTextLabel)
    }
}

extension UISliderView {
    
    /// 初始化
    private func initialize() {
        insertSubview(maxTrackView, at: 0)
        NSLayoutConstraint.activate([
            maxTrackView.leftAnchor.constraint(equalTo: leftAnchor, constant: -2.0),
            maxTrackView.rightAnchor.constraint(equalTo: rightAnchor, constant: 2.0),
            maxTrackView.topAnchor.constraint(equalTo: topAnchor),
            maxTrackView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        
        insertSubview(minTrackView, aboveSubview: maxTrackView)
        NSLayoutConstraint.activate([
            minTrackView.leftAnchor.constraint(equalTo: leftAnchor, constant: -2.0),
            minTrackView.topAnchor.constraint(equalTo: topAnchor),
            minTrackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            minTrackView.widthAnchor.constraint(equalToConstant: 0.0),
        ])
        
        insertSubview(minimumValueLabel, aboveSubview: minTrackView)
        NSLayoutConstraint.activate([
            minimumValueLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 12.0),
            minimumValueLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        
        insertSubview(maximumValueLabel, aboveSubview: minTrackView)
        NSLayoutConstraint.activate([
            maximumValueLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -12.0),
            maximumValueLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        
        insertSubview(minimumValueImageView, aboveSubview: minimumValueLabel)
        NSLayoutConstraint.activate([
            minimumValueImageView.leftAnchor.constraint(equalTo: leftAnchor, constant: 12.0),
            minimumValueImageView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        
        insertSubview(maximumValueImagView, aboveSubview: maximumValueLabel)
        NSLayoutConstraint.activate([
            maximumValueImagView.rightAnchor.constraint(equalTo: rightAnchor, constant: -12.0),
            maximumValueImagView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        
        addSubview(thumbTextLabel)
        
    }
    
    /// trackActionHandler
    /// - Parameter sender: UISliderView
    @objc private func trackActionHandler(_ sender: UISliderView) {
        willChangeValue(forKey: #keyPath(UISliderView.value))
        defer { didChangeValue(forKey: #keyPath(UISliderView.value)) }
        // next
        if isTrackValues == true && trackValues.isEmpty == false {
            if trackValues.contains(sender.value) == true {
                delegate?.sliderView(self, trackValueAction: sender.value)
            } else {
                guard let trackValue = trackValues.min(by: { abs($0 - sender.value) < abs($1 - sender.value) }) else { return }
                sender.value = trackValue
                delegate?.sliderView(self, trackValueAction: trackValue)
            }
        } else {
            delegate?.sliderView(self, trackValueAction: sender.value)
        }
        #if DEBUG
        print((#file as NSString).lastPathComponent, "=>", #function, sender.value)
        #endif
    }
}

#endif
