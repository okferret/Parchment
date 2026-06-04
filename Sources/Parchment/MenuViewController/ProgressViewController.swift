//
//  ProgressViewController.swift
//  Parchment
//
//  Created by okferret on 2026/6/3.
//

#if canImport(UIKit)

import UIKit

/// ProgressViewControllerDelegate
protocol ProgressViewControllerDelegate: AnyObject {
    
    /// backwardActionWith
    /// - Parameters:
    ///   - controller: ProgressViewController
    ///   - sender: UIButton
    func controller(_ controller: ProgressViewController, backwardActionWith sender: UIButton)
    
    /// forewardActionWith
    /// - Parameters:
    ///   - controller: ProgressViewController
    ///   - sender: UIButton
    func controller(_ controller: ProgressViewController, forewardActionWith sender: UIButton)
    
    /// progressActionWtih
    /// - Parameters:
    ///   - controller: ProgressViewController
    ///   - value: Float
    func controller(_ controller: ProgressViewController, progressActionWtih value: Float)
}

class ProgressViewController: UIViewController, MenuContentViewController {
    
    //  MARK: - 公开属性
    
    /// Optional<ProgressViewControllerDelegate>
    internal weak var delegate: Optional<ProgressViewControllerDelegate> = .none
    
    //  MARK: - 私有属性
    
    /// UIView
    private(set) lazy var contentView: UIView = {
        let _contentView: UIView = .init(frame: .zero)
        _contentView.backgroundColor = configuration.theme.barTint
        _contentView.translatesAutoresizingMaskIntoConstraints = false
        return _contentView
    }()
    
    /// 进度
    private lazy var progressLabel: UILabel = {
        let _label: UILabel = .init(frame: .zero)
        _label.font = .systemFont(ofSize: 15.0)
        _label.textColor = configuration.theme.primaryTint
        _label.textAlignment = .center
        _label.text = "阅读进度：0.0%"
        _label.translatesAutoresizingMaskIntoConstraints = false
        return _label
    }()
    
    /// left button
    private lazy var leftButton: UIButton = {
        let _button: UIButton = .init(type: .custom)
        _button.setImage(.module(named: "ic_book_backward")?.withTintColor(configuration.theme.primaryTint), for: .normal)
        _button.setImage(.module(named: "ic_book_backward")?.withTintColor(configuration.theme.stressTint), for: .highlighted)
        _button.imageView?.contentMode = .scaleAspectFit
        _button.translatesAutoresizingMaskIntoConstraints = false
        _button.widthAnchor.constraint(equalToConstant: 20.0).isActive = true
        return _button
    }()
    
    /// right button
    private lazy var rightButton: UIButton = {
        let _button: UIButton = .init(type: .custom)
        _button.setImage(.module(named: "ic_book_foreward")?.withTintColor(configuration.theme.primaryTint), for: .normal)
        _button.setImage(.module(named: "ic_book_foreward")?.withTintColor(configuration.theme.stressTint), for: .highlighted)
        _button.imageView?.tintColor = configuration.theme.primaryTint
        _button.imageView?.contentMode = .scaleAspectFit
        _button.translatesAutoresizingMaskIntoConstraints = false
        _button.widthAnchor.constraint(equalToConstant: 20.0).isActive = true
        return _button
    }()
    
    /// UISlider
    private(set) lazy var sliderView: UISliderView = {
        let _sliderView: UISliderView = .init(frame: .zero)
        _sliderView.isContinuous = false
        _sliderView.layer.cornerRadius = 14.0
        _sliderView.layer.masksToBounds = true
        _sliderView.translatesAutoresizingMaskIntoConstraints = false
        _sliderView.heightAnchor.constraint(equalToConstant: 28.0).isActive = true
        _sliderView.backgroundColor = .clear
        _sliderView.minimumTrackTintColor = .clear
        _sliderView.maximumTrackTintColor = configuration.theme.background
        _sliderView.thumbTintColor = configuration.theme.thumbTintColor
        _sliderView.minimumValue = 0.0
        _sliderView.maximumValue = 1.0
        _sliderView.trackValues = Array(0...100).map { Float($0) / 100 }
        _sliderView.isTrackValues = false
        _sliderView.delegate = self
        return _sliderView
    }()
    
    /// 堆栈
    private lazy var stackView: UIStackView = {
        let _stackView: UIStackView = .init(arrangedSubviews: [leftButton, sliderView, rightButton])
        _stackView.axis = .horizontal
        _stackView.alignment = .fill
        _stackView.distribution = .fill
        _stackView.spacing = 12.0
        _stackView.translatesAutoresizingMaskIntoConstraints = false
        return _stackView
    }()
    
    /// Optional<NSKeyValueObservation>
    private var observation: Optional<NSKeyValueObservation> = .none
    
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
        // KVO
        observation = sliderView.observe(\.value, options: [.initial, .new], changeHandler: {[weak self] _, obs in
            guard let this = self, let newValue: Float = obs.newValue else { return }
            this.leftButton.isEnabled = newValue > 0.0
            this.rightButton.isEnabled = newValue < 1.0
            print("observation =>", obs.newValue)
        })
    }
    
    /// traitCollectionDidChange
    /// - Parameter previousTraitCollection: UITraitCollection
    internal override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        contentView.backgroundColor = configuration.theme.barTint
        progressLabel.textColor = configuration.theme.primaryTint
        leftButton.setImage(.module(named: "ic_book_backward")?.withTintColor(configuration.theme.primaryTint), for: .normal)
        leftButton.setImage(.module(named: "ic_book_backward")?.withTintColor(configuration.theme.stressTint), for: .highlighted)
        rightButton.setImage(.module(named: "ic_book_foreward")?.withTintColor(configuration.theme.primaryTint), for: .normal)
        rightButton.setImage(.module(named: "ic_book_foreward")?.withTintColor(configuration.theme.stressTint), for: .highlighted)
     
        sliderView.backgroundColor = .clear
        sliderView.minimumTrackTintColor = .clear
        sliderView.maximumTrackTintColor = configuration.theme.background
        sliderView.thumbTintColor = configuration.theme.thumbTintColor
    }
    
}

extension ProgressViewController {
    
    /// 初始化
    private func initialize() {
        view.backgroundColor = .clear
        
        view.addSubview(contentView)
        NSLayoutConstraint.activate([
            contentView.leftAnchor.constraint(equalTo: view.leftAnchor),
            contentView.rightAnchor.constraint(equalTo: view.rightAnchor),
            contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            contentView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -100.0)
        ])
        
        contentView.addSubview(progressLabel)
        NSLayoutConstraint.activate([
            progressLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            progressLabel.leftAnchor.constraint(greaterThanOrEqualTo: contentView.leftAnchor, constant: 16.0),
            progressLabel.rightAnchor.constraint(lessThanOrEqualTo: contentView.rightAnchor, constant: -16.0),
            progressLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12.0)
        ])
        
        contentView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 12.0),
            stackView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -12.0),
            stackView.heightAnchor.constraint(equalToConstant: 28.0),
            stackView.topAnchor.constraint(equalTo: progressLabel.bottomAnchor, constant: 18.0)
        ])
    }
    
    /// 点击事件
    /// - Parameter sender: UIButton
    @objc private func buttonActionHandler(_ sender: UIButton) {
        switch sender {
        case leftButton:
            delegate?.controller(self, backwardActionWith: sender)
        case rightButton:
            delegate?.controller(self, forewardActionWith: sender)
        default: break
        }
    }
}

//  MARK: - UISliderViewDelegate
extension ProgressViewController: @preconcurrency UISliderViewDelegate {
    
    /// trackValueAction
    /// - Parameters:
    ///   - sliderView: UISliderView
    ///   - trackValue: Float
    internal func sliderView(_ sliderView: UISliderView, trackValueAction trackValue: Float) {
        delegate?.controller(self, progressActionWtih: trackValue)
    }
    
    /// slideAction
    /// - Parameters:
    ///   - sliderView: UISliderView
    ///   - slideValue: Float
    internal func sliderView(_ sliderView: UISliderView, slideAction slideValue: Float) {
        progressLabel.text = "阅读进度：\(NumberFormatter.default.hub.string(from: slideValue, numberStyle: .percent))"
    }
    
}


#endif
