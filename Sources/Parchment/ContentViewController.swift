//
//  ContentViewController.swift
//  Parchment
//
//  Created by okferret on 2026/6/3.
//

#if canImport(UIKit)

import UIKit

/// ContentViewController
class ContentViewController: UIViewController {
    
    //  MARK: - 私有属性
    
    /// UIView
    private lazy var contentView: ContentView = {
        let _contentView: ContentView = .init(frame: .zero)
        _contentView.backgroundColor = .clear
        _contentView.translatesAutoresizingMaskIntoConstraints = false
        return _contentView
    }()
    
    /// PageEntity.Want
    private(set) var pageWant: Optional<PageEntity.Want> = .none
    /// Configuration
    private(set) var configuration: Configuration = .default()
    
    //  MARK: - 生命周期

    /// viewDidLoad
    internal override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        // 初始化
        initialize()
    }
    
    /// traitCollectionDidChange
    /// - Parameter previousTraitCollection: UITraitCollection
    internal override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        // next
        view.backgroundColor = configuration.theme.background
        if let attributedText = contentView.attributedText {
            let newText: NSMutableAttributedString = .init(attributedString: attributedText)
            newText.addAttribute(.foregroundColor, value: configuration.theme.primaryText, range: .init(newText.string.startIndex..., in: newText.string))
            contentView.attributedText = newText
        }
    }
    
}

extension ContentViewController {
    
    /// 初始化
    private func initialize() {
        let safeAreaInsets: UIEdgeInsets = BookHelper.safeAreaInsets
        view.backgroundColor = configuration.theme.background
        view.addSubview(contentView)
        NSLayoutConstraint.activate([
            contentView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: safeAreaInsets.left),
            contentView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -safeAreaInsets.right),
            contentView.topAnchor.constraint(equalTo: view.topAnchor, constant: safeAreaInsets.top),
            contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -safeAreaInsets.bottom)
        ])
    }
    
    /// reloadWith
    /// - Parameters:
    ///   - pageWant: Optional<PageEntity.Want>
    ///   - configuration: Configuration
    internal func reloadWith(_ pageWant: Optional<PageEntity.Want>, configuration: Configuration) {
        self.pageWant = pageWant
        self.configuration = configuration
        if let pageWant = pageWant {
            if pageWant.isTruncated == true {
                let newText: NSMutableAttributedString = .init(string: pageWant.text, attributes: configuration.textAttributes)
                if let lineText: String = pageWant.text.components(separatedBy: .newlines).first {
                    let range: NSRange = .init(lineText.startIndex..., in: lineText)
                    newText.removeAttribute(.paragraphStyle, range: range)
                    if let paragraphStyle: NSMutableParagraphStyle = configuration.paragraphStyle.hub.mutableCopy() {
                        paragraphStyle.firstLineHeadIndent = 0.0
                        newText.addAttribute(.paragraphStyle, value: pageWant, range: range)
                    }
                }
                self.contentView.attributedText = newText
            } else {
                
                self.contentView.attributedText = .init(string: pageWant.text, attributes: configuration.textAttributes)
            }
  
        } else {
            self.contentView.attributedText = .none
        }
    }
}

/// ContentView
fileprivate class ContentView: UIView {
    
    /// Optional<NSAttributedString>
    internal var attributedText: Optional<NSAttributedString> = .none {
        didSet { setNeedsDisplay() }
    }
  
    /// draw
    /// - Parameter rect: CGRect
    internal override func draw(_ rect: CGRect) {
        guard let attributedText = attributedText else { return }
        // 获取当前图形上下文
        guard let context = UIGraphicsGetCurrentContext() else { return }
        // 翻转坐标系（Core Text 使用左下角为原点）
        context.saveGState()
        context.textMatrix = .identity
        context.translateBy(x: 0, y: bounds.height)
        context.scaleBy(x: 1.0, y: -1.0)
        // 创建 CTFramesetter
        let framesetter = CTFramesetterCreateWithAttributedString(attributedText)
        // 创建路径
        let path = CGMutablePath()
        path.addRect(bounds)
        // 创建 CTFrame
        let frame = CTFramesetterCreateFrame(framesetter, CFRange(location: 0, length: 0), path, nil)
        // 绘制
        CTFrameDraw(frame, context)
        context.restoreGState()
    }
}


#endif
