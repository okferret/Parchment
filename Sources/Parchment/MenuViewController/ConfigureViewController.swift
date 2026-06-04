//
//  ConfigureViewController.swift
//  Parchment
//
//  Created by okferret on 2026/6/3.
//

#if canImport(UIKit)

import UIKit

/// ConfigureViewControllerDelegate
protocol ConfigureViewControllerDelegate: AnyObject {
    
    /// brightnessActionWith
    /// - Parameters:
    ///   - controller: ConfigureViewController
    ///   - brightness: Float
    func controller(_ controller: ConfigureViewController, brightnessActionWith brightness: CGFloat)
    
    /// fontActionWith
    /// - Parameters:
    ///   - controller: ConfigureViewController
    ///   - value: Float
    func controller(_ controller: ConfigureViewController, fontActionWith value: Float)
    
    /// themeActionWith
    /// - Parameters:
    ///   - controller: ConfigureViewController
    ///   - theme: Theme
    func controller(_ controller: ConfigureViewController, themeActionWith theme: Theme)
    
    /// transitionActionWith
    /// - Parameters:
    ///   - controller: ConfigureViewController
    ///   - transitionStyle: TransitionStyle
    func controller(_ controller: ConfigureViewController, transitionActionWith transitionStyle: TransitionStyle)
}

/// ConfigureViewController
class ConfigureViewController: UIViewController, MenuContentViewController {
    
    //  MARK: - 公开属性
    
    /// Optional<ConfigureViewControllerDelegate>
    internal weak var delegate: Optional<ConfigureViewControllerDelegate> = .none
    
    //  MARK: - 私有属性
    
    /// UIView
    private(set) lazy var contentView: UIView = {
        let _contentView: UIView = .init(frame: .zero)
        _contentView.backgroundColor = configuration.theme.barTint
        _contentView.translatesAutoresizingMaskIntoConstraints = false
        return _contentView
    }()
    
    /// 亮度
    private lazy var brightLabel: UILabel = {
        let _label: UILabel = .init(frame: .zero)
        _label.font = .systemFont(ofSize: 14.0)
        _label.textAlignment = .left
        _label.textColor = configuration.theme.primaryTint
        _label.text = "亮度"
        _label.setContentHuggingPriority(.required, for: .horizontal)
        _label.setContentCompressionResistancePriority(.required, for: .horizontal)
        _label.translatesAutoresizingMaskIntoConstraints = false
        return _label
    }()
    
    /// 亮度
    private lazy var brightView: UISliderView = {
        let _sliderView: UISliderView = .init(frame: .zero)
        _sliderView.isContinuous = false
        _sliderView.layer.cornerRadius = 14.0
        _sliderView.layer.masksToBounds = true
        _sliderView.translatesAutoresizingMaskIntoConstraints = false
        _sliderView.heightAnchor.constraint(equalToConstant: 28.0).isActive = true
        _sliderView.backgroundColor = .clear
        _sliderView.minimumTrackTintColor = .clear
        _sliderView.maximumTrackTintColor = configuration.theme.background
        _sliderView.thumbTextColor = configuration.theme.primaryTint
        _sliderView.thumbTextFont = .systemFont(ofSize: 14.0, weight: .medium)
        _sliderView.thumbTintColor = configuration.theme.thumbTintColor
        _sliderView.translatesAutoresizingMaskIntoConstraints = false
        _sliderView.minimumValue = 0.0
        _sliderView.maximumValue = 1.0
        //_sliderView.trackValues = Array(0...10).map { Float($0) / 10.0 }
        _sliderView.delegate = self
        _sliderView.value = Float(configuration.brightness)
        return _sliderView
    }()
    
    /// 字体
    private lazy var fontLabel: UILabel = {
        let _label: UILabel = .init(frame: .zero)
        _label.font = .systemFont(ofSize: 14.0)
        _label.textAlignment = .left
        _label.textColor = configuration.theme.primaryTint
        _label.text = "字体"
        _label.setContentHuggingPriority(.required, for: .horizontal)
        _label.setContentCompressionResistancePriority(.required, for: .horizontal)
        _label.translatesAutoresizingMaskIntoConstraints = false
        return _label
    }()
    
    /// 字体
    private lazy var fontView: UISliderView = {
        let _sliderView: UISliderView = .init(frame: .zero)
        _sliderView.isContinuous = false
        _sliderView.layer.cornerRadius = 14.0
        _sliderView.layer.masksToBounds = true
        _sliderView.translatesAutoresizingMaskIntoConstraints = false
        _sliderView.heightAnchor.constraint(equalToConstant: 28.0).isActive = true
        _sliderView.backgroundColor = .clear
        _sliderView.minimumTrackTintColor = .clear
        _sliderView.maximumTrackTintColor = configuration.theme.background
        _sliderView.minimumValueText = "A-"
        _sliderView.maximumValueText = "A+"
        _sliderView.minimumValueTextFont = .systemFont(ofSize: 14.0)
        _sliderView.maximumValueTextFont = .systemFont(ofSize: 14.0)
        _sliderView.minimumValueTextColor = configuration.theme.primaryTint
        _sliderView.maximumValueTextColor = configuration.theme.primaryTint
        _sliderView.thumbTextColor = configuration.theme.primaryTint
        _sliderView.thumbTextFont = .systemFont(ofSize: 14.0, weight: .medium)
        _sliderView.thumbTintColor = configuration.theme.thumbTintColor
        _sliderView.minimumValue = 16.0
        _sliderView.maximumValue = 40.0
        _sliderView.trackValues = Array(16...40).map { Float($0)}
        _sliderView.translatesAutoresizingMaskIntoConstraints = false
        _sliderView.value = Float(configuration.font.pointSize)
        _sliderView.delegate = self
        return _sliderView
    }()
    
    /// 背景
    private lazy var themeLabel: UILabel = {
        let _label: UILabel = .init(frame: .zero)
        _label.font = .systemFont(ofSize: 14.0)
        _label.textAlignment = .left
        _label.textColor = configuration.theme.primaryTint
        _label.text = "背景"
        _label.setContentHuggingPriority(.required, for: .horizontal)
        _label.setContentCompressionResistancePriority(.required, for: .horizontal)
        _label.translatesAutoresizingMaskIntoConstraints = false
        return _label
    }()
    
    /// 背景
    private lazy var themeView: UIStackView = {
        let _buttons: Array<UIButton> = Theme.allCases.map { theme in
            let button: UIButton = .init(type: .custom)
            button.backgroundColor = theme.background
            button.setImage(theme.normalImage, for: .normal)
            button.setImage(theme.selectedImage, for: .selected)
            button.tag = theme.uniqueID.rawValue
            button.translatesAutoresizingMaskIntoConstraints = false
            button.widthAnchor.constraint(equalToConstant: 32.0).isActive = true
            button.heightAnchor.constraint(equalToConstant: 32.0).isActive = true
            button.isUserInteractionEnabled = true
            button.layer.cornerRadius = 16.0
            button.layer.masksToBounds = true
            button.layer.borderWidth = 2.0
            button.layer.borderColor = .clear
            button.addTarget(self, action: #selector(themeActionHandler(_:)), for: .touchUpInside)
            if configuration.theme.uniqueID == theme.uniqueID {
                button.isSelected = true
                button.isUserInteractionEnabled = false
                button.layer.borderColor = theme.stressTint.cgColor
            }
            return button
        }
        let _stackView: UIStackView = .init(arrangedSubviews: _buttons)
        _stackView.axis = .horizontal
        _stackView.alignment = .fill
        _stackView.distribution = .equalSpacing
        _stackView.translatesAutoresizingMaskIntoConstraints = false
        return _stackView
    }()
    
    /// 翻页方式
    private lazy var transitionLabel: UILabel = {
        let _label: UILabel = .init(frame: .zero)
        _label.font = .systemFont(ofSize: 14.0)
        _label.textAlignment = .left
        _label.textColor = configuration.theme.primaryTint
        _label.text = "翻页"
        _label.setContentHuggingPriority(.required, for: .horizontal)
        _label.setContentCompressionResistancePriority(.required, for: .horizontal)
        _label.translatesAutoresizingMaskIntoConstraints = false
        return _label
    }()
    
    /// 翻页方式
    private lazy var transitionView: UIStackView = {
        let _buttons: Array<UIButton> = TransitionStyle.allCases.map { style in
            let button: UIButton = .init(type: .custom)
            button.tag = style.rawValue
            button.setTitle(style.description, for: .normal)
            button.setTitleColor(configuration.theme.primaryTint, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 15.0)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.widthAnchor.constraint(equalToConstant: 92.0).isActive = true
            button.heightAnchor.constraint(equalToConstant: 32.0).isActive = true
            button.layer.cornerRadius = 16.0
            button.layer.masksToBounds = true
            button.layer.borderWidth = 1.0
            button.layer.borderColor = configuration.transitionStyle == style ? configuration.theme.primaryTint.cgColor : configuration.theme.background.cgColor
            button.isUserInteractionEnabled = configuration.transitionStyle != style
            button.isSelected = configuration.transitionStyle == style
            button.addTarget(self, action: #selector(transitionActionHandler(_:)), for: .touchUpInside)
            return button
        }
        let _stackView: UIStackView = .init(arrangedSubviews: _buttons)
        _stackView.spacing = 20.0
        _stackView.axis = .horizontal
        _stackView.alignment = .fill
        _stackView.distribution = .equalSpacing
        _stackView.translatesAutoresizingMaskIntoConstraints = false
        return _stackView
    }()
    
    /// 文件存储位置
    private let fileURL: URL
    /// Configuration
    private let configuration: Configuration
    
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
        // 注册通知
        NotificationCenter.default.addObserver(self, selector: #selector(notificationHandler(_:)), name: UIScreen.brightnessDidChangeNotification, object: .none)
    }
    
    /// traitCollectionDidChange
    /// - Parameter previousTraitCollection: UITraitCollection
    internal override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        let theme = configuration.theme
        contentView.backgroundColor = theme.barTint
        
        brightLabel.textColor = theme.primaryTint
        brightView.maximumTrackTintColor = theme.background
        brightView.thumbTextColor = theme.primaryTint
        brightView.thumbTintColor = theme.thumbTintColor
        brightView.value = Float(configuration.brightness)
        
        fontLabel.textColor = theme.primaryTint
        fontView.backgroundColor = .clear
        fontView.minimumTrackTintColor = .clear
        fontView.maximumTrackTintColor = theme.background
        fontView.minimumValueTextColor = theme.primaryTint
        fontView.maximumValueTextColor = theme.primaryTint
        fontView.thumbTextColor = theme.primaryTint
        fontView.thumbTintColor = theme.thumbTintColor
        
        themeLabel.textColor = theme.primaryTint

        transitionLabel.textColor = theme.primaryTint
        transitionView.arrangedSubviews.compactMap { $0 as? UIButton }.forEach {
            $0.layer.borderColor = $0.isSelected == true ? theme.stressTint.cgColor : theme.background.cgColor
            $0.setTitleColor(theme.primaryTint, for: .normal)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension ConfigureViewController {
    
    /// 初始化
    private func initialize() {
        view.backgroundColor = .clear
        
        view.addSubview(contentView)
        NSLayoutConstraint.activate([
            contentView.leftAnchor.constraint(equalTo: view.leftAnchor),
            contentView.rightAnchor.constraint(equalTo: view.rightAnchor),
            contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            contentView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -262.0)
        ])
        
        contentView.addSubview(brightLabel)
        contentView.addSubview(brightView)
        NSLayoutConstraint.activate([
            brightLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16.0),
            brightLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 32.0),
            brightView.centerYAnchor.constraint(equalTo: brightLabel.centerYAnchor),
            brightView.leftAnchor.constraint(equalTo: brightLabel.rightAnchor, constant: 12.0),
            brightView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -16.0),
        ])
        
        contentView.addSubview(fontLabel)
        contentView.addSubview(fontView)
        NSLayoutConstraint.activate([
            fontLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16.0),
            fontLabel.topAnchor.constraint(equalTo: brightLabel.bottomAnchor, constant: 40.0),
            fontView.centerYAnchor.constraint(equalTo: fontLabel.centerYAnchor),
            fontView.leftAnchor.constraint(equalTo: fontLabel.rightAnchor, constant: 12.0),
            fontView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -16.0),
        ])
        
        contentView.addSubview(themeLabel)
        contentView.addSubview(themeView)
        NSLayoutConstraint.activate([
            themeLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16.0),
            themeLabel.topAnchor.constraint(equalTo: fontLabel.bottomAnchor, constant: 40.0),
            themeView.centerYAnchor.constraint(equalTo: themeLabel.centerYAnchor),
            themeView.leftAnchor.constraint(equalTo: themeLabel.rightAnchor, constant: 12.0),
            themeView.rightAnchor.constraint(lessThanOrEqualTo: contentView.rightAnchor, constant: -16.0),
            themeView.heightAnchor.constraint(equalToConstant: 32.0),
            themeView.widthAnchor.constraint(equalToConstant: 272.0),
        ])
        
        contentView.addSubview(transitionLabel)
        contentView.addSubview(transitionView)
        NSLayoutConstraint.activate([
            transitionLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16.0),
            transitionLabel.topAnchor.constraint(equalTo: themeLabel.bottomAnchor, constant: 40.0),
            transitionView.centerYAnchor.constraint(equalTo: transitionLabel.centerYAnchor),
            transitionView.leftAnchor.constraint(equalTo: transitionLabel.rightAnchor, constant: 12.0),
            transitionView.rightAnchor.constraint(lessThanOrEqualTo: contentView.rightAnchor, constant: -16.0),
            transitionView.heightAnchor.constraint(equalToConstant: 32.0),
            transitionView.widthAnchor.constraint(equalToConstant: 204.0),
        ])
    }
    
    /// themeActionHandler
    /// - Parameter sender: UIButton
    @objc private func themeActionHandler(_ sender: UIButton) {
        let buttons: Array<UIButton> = themeView.arrangedSubviews.compactMap { $0 as? UIButton }
        guard let theme: Theme = Theme.allCases.first(where: { $0.uniqueID.rawValue == sender.tag }) else { return }
        // 更新UI
        Set(buttons).subtracting([sender]).forEach {
            $0.layer.borderColor = .clear
            $0.isSelected = false
            $0.isUserInteractionEnabled = true
        }
        sender.layer.borderColor = theme.stressTint.cgColor
        sender.isSelected = true
        sender.isUserInteractionEnabled = false
        // 更新主题
        delegate?.controller(self, themeActionWith: theme)
    }
    
    /// 翻页方式
    /// - Parameter sender: UIButton
    @objc private func transitionActionHandler(_ sender: UIButton) {
        let buttons: Array<UIButton> = transitionView.arrangedSubviews.compactMap { $0 as? UIButton }
        guard let style: TransitionStyle = .init(rawValue: sender.tag) else { return }
        Set(buttons).subtracting([sender]).forEach {
            $0.layer.borderColor = configuration.theme.background.cgColor
            $0.isUserInteractionEnabled = true
            $0.isSelected = false
        }
        sender.layer.borderColor = configuration.theme.primaryTint.cgColor
        sender.isUserInteractionEnabled = false
        sender.isSelected = true
        // 更新翻页方式
        delegate?.controller(self, transitionActionWith: style)
    }
    
    /// notificationHandler
    /// - Parameter sender: Notification
    @objc private func notificationHandler(_ sender: Notification) {
        switch sender.name {
        case UIScreen.brightnessDidChangeNotification:
            guard let screen: UIScreen = sender.object as? UIScreen else { return }
            let newValue: Float = Float(screen.brightness)
            brightView.value = newValue
            brightView.delegate?.sliderView(brightView, trackValueAction: newValue)
        default: break
        }
    }
}

//  MARK: - UISliderViewDelegate
extension ConfigureViewController: @preconcurrency UISliderViewDelegate {
    
    /// trackValueAction
    /// - Parameters:
    ///   - sliderView: UISliderView
    ///   - trackValue: Float
    internal func sliderView(_ sliderView: UISliderView, trackValueAction trackValue: Float) {
        switch sliderView {
        case brightView:
            delegate?.controller(self, brightnessActionWith: CGFloat(trackValue))
        case fontView:
            delegate?.controller(self, fontActionWith: trackValue)
        default: break
        }
    }
    
    /// thumbTextAt
    /// - Parameters:
    ///   - sliderView: UISliderView
    ///   - trackValue: Float
    /// - Returns:  Optional<String>
    internal func sliderView(_ sliderView: UISliderView, thumbTextAt trackValue: Float) -> Optional<String> {
        switch sliderView {
        case brightView:    return "\(Int(trackValue * 100))"
        case fontView:      return "\(Int(trackValue))"
        default:            return .none
        }
    }
}

#endif
