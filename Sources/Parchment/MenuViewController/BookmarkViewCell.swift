//
//  BookmarkViewCell.swift
//  Parchment
//
//  Created by okferret on 2026/6/5.
//
#if canImport(UIKit)

import UIKit

class BookmarkViewCell: UITableViewCell {
    
    //  MARK: - 公开属性
    
    /// ChapterTableViewCell
    internal static var reusedID: String { "BookmarkViewCell" }
    
    /// Optional<Theme>
    internal var theme: Optional<Theme> = .none {
        didSet { reloadWith(markWant, theme: theme) }
    }
    
    /// Optional<MarkEntity.Want>
    internal var markWant: Optional<MarkEntity.Want> = .none {
        didSet { reloadWith(markWant, theme: theme) }
    }
    
    //  MARK: - 私有属性
    
    /// UILabel
    private lazy var titleLabel: UILabel = {
        let _label: UILabel = .init(frame: .zero)
        _label.textAlignment = .left
        _label.font = .systemFont(ofSize: 14.0)
        _label.numberOfLines = 2
        return _label
    }()
    
    /// UILabel
    private lazy var timeLabel: UILabel = {
        let _label: UILabel = .init(frame: .zero)
        _label.textAlignment = .left
        _label.font = .systemFont(ofSize: 13.0)
        return _label
    }()
    
    /// UIStackView
    private lazy var stackView: UIStackView = {
        let _stackView: UIStackView = .init(arrangedSubviews: [titleLabel, timeLabel])
        _stackView.axis = .vertical
        _stackView.alignment = .leading
        _stackView.spacing = 6.0
        _stackView.translatesAutoresizingMaskIntoConstraints = false
        return _stackView
    }()
    
    //  MARK: - 生命周期
    
    /// 构造函数
    /// - Parameters:
    ///   - style: UITableViewCell.CellStyle
    ///   - reuseIdentifier: String
    internal override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none
        
        // 布局
        contentView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16.0),
            stackView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -16.0),
            stackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
    /// 构造函数
    /// - Parameter coder: NSCoder
    internal required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// reloadWith
    /// - Parameter markWant: Optional<MarkEntity.Want>
    private func reloadWith(_ markWant: Optional<MarkEntity.Want>, theme: Optional<Theme>) {
        guard let markWant = markWant, let theme = theme else { return }
        titleLabel.text = markWant.sketchText
        titleLabel.textColor = theme.primaryText
        timeLabel.text = DateFormatter.shared.hub.format(markWant.createdAt, format: "yyyy/MM/dd")
        timeLabel.textColor = theme.secondaryText
    }
    
}

#endif
