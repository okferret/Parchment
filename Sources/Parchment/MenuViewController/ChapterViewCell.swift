//
//  ChapterViewCell.swift
//  Parchment
//
//  Created by okferret on 2026/6/4.
//

#if canImport(UIKit)

import UIKit

/// ChapterViewCell
class ChapterViewCell: UITableViewCell {
    //  MARK: - 公开属性
    
    /// ChapterTableViewCell
    internal static var reusedID: String { "ChapterViewCell" }
    
    /// Optional<Theme>
    internal var theme: Optional<Theme> = .none
    /// Optional<ChapterEntity.Want>
    internal var newWant: Optional<ChapterEntity.Want> = .none {
        didSet { reloadWith(newWant) }
    }
    
    //  MARK: - 私有属性
    
    /// UILabel
    private lazy var titleLabel: UILabel = {
        let _label: UILabel = .init(frame: .zero)
        _label.font = .pingfangSC(ofSize: 14.0)
        _label.textAlignment = .left
        _label.translatesAutoresizingMaskIntoConstraints = false
        return _label
    }()
    
    /// 当前读到
    private lazy var markedLabel: UILabel = {
        let _label: UILabel = .init(frame: .zero)
        _label.font = .pingfangSC(ofSize: 14.0)
        _label.text = "当前读到"
        _label.textAlignment = .right
        _label.translatesAutoresizingMaskIntoConstraints = false
        _label.setContentHuggingPriority(.required, for: .horizontal)
        _label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return _label
    }()
    
    /// 标记
    private lazy var markedView: UIImageView = {
        let _img: Optional<UIImage> = .module(named: "ic_mark")
        let _imgView: UIImageView = .init(image: _img)
        _imgView.contentMode = .scaleAspectFit
        _imgView.translatesAutoresizingMaskIntoConstraints = false
        return _imgView
    }()
    
    //  MARK: - 生命周期
    
    /// 构造函数
    /// - Parameters:
    ///   - style: UITableViewCell.CellStyle
    ///   - reuseIdentifier: String
    internal override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        // 初始化
        initialize()
    }
    
    /// 构造函数
    /// - Parameter coder: NSCoder
    internal required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

extension ChapterViewCell {
    
    /// 初始化
    private func initialize() {
        backgroundColor = .clear
        // 添加约束
        contentView.addSubview(markedLabel)
        NSLayoutConstraint.activate([
            markedLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -16.0),
            markedLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])
        
        contentView.addSubview(markedView)
        NSLayoutConstraint.activate([
            markedView.rightAnchor.constraint(equalTo: markedLabel.leftAnchor, constant: -5.0),
            markedView.centerYAnchor.constraint(equalTo: markedLabel.centerYAnchor),
            markedView.widthAnchor.constraint(equalToConstant: 20.0),
            markedView.heightAnchor.constraint(equalToConstant: 20.0),
        ])
        
        contentView.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16.0),
            titleLabel.rightAnchor.constraint(lessThanOrEqualTo: markedView.leftAnchor, constant: -16.0),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])
    }
    
    /// reloadWith
    /// - Parameter newWant: Optional<ChapterEntity.Want>
    private func reloadWith(_ newWant: Optional<ChapterEntity.Want>) {
        guard let newWant = newWant else { return }
        titleLabel.text = newWant.title
        print("chapter title =>", newWant.title)
        titleLabel.textColor = theme?.primaryTint
        markedLabel.text = "当前读到"
        markedLabel.textColor = theme?.markedTint
        markedView.tintColor = theme?.markedTint
    }
}

#endif
