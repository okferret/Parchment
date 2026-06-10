//
//  ChapterViewController.swift
//  Parchment
//
//  Created by okferret on 2026/6/5.
//
#if canImport(UIKit)

import UIKit
import CoreData

/// ChapterViewControllerDelegate
protocol ChapterViewControllerDelegate: AnyObject {
    
    /// selectedActionWith
    /// - Parameters:
    ///   - controller: ChapterViewController
    ///   - newWant: ChapterEntity.Want
    func controller(_ controller: ChapterViewController, selectedActionWith newWant: ChapterEntity.Want)
}

class ChapterViewController: UIViewController {
    
    //  MARK: - 公开属性
    
    /// Optional<ChapterViewControllerDelegate>
    internal weak var delegate: Optional<ChapterViewControllerDelegate> = .none
    
    //  MARK: - 私有属性
    
    /// 列表视图
    private lazy var tableView: UITableView = {
        let _tableView: UITableView = .init(frame: .zero, style: .plain)
        _tableView.backgroundView = BackgroundView(frame: view.bounds)
        (_tableView.backgroundView as! BackgroundView).backgroundImage = .module(named: "ic_empty")
        (_tableView.backgroundView as! BackgroundView).backgroundImageTint = configuration.theme.placeholderTint
        (_tableView.backgroundView as! BackgroundView).text = "暂无内容"
        (_tableView.backgroundView as! BackgroundView).textFont = .systemFont(ofSize: 14.0)
        (_tableView.backgroundView as! BackgroundView).textColor = configuration.theme.placeholderText
        _tableView.translatesAutoresizingMaskIntoConstraints = false
        _tableView.backgroundColor = .clear
        _tableView.register(ChapterViewCell.self, forCellReuseIdentifier: ChapterViewCell.reusedID)
        _tableView.rowHeight = 52.0
        _tableView.separatorColor = configuration.theme.separatorTint
        _tableView.separatorInset = .init(top: 0.0, left: 16.0, bottom: 0.0, right: 16.0)
        _tableView.separatorStyle = .singleLine
        _tableView.delegate = self
        return _tableView
    }()
    
    /// UITableViewDiffableDataSource<Int, ChapterEntity.Want>
    private lazy var dataSource: UITableViewDiffableDataSource<String, ChapterEntity.Want> = .init(tableView: tableView) {[weak self] tableView, indexPath, itemIdentifier in
        let cell: ChapterViewCell = tableView.dequeueReusableCell(withIdentifier: ChapterViewCell.reusedID, for: indexPath) as! ChapterViewCell
        cell.theme = self?.configuration.theme
        cell.newWant = itemIdentifier
        cell.isCurrentted = self?.chapterWant?.objectID == itemIdentifier.objectID
        return cell
    }
    
    /// frc: NSFetchedResultsController<ChapterEntity>
    private lazy var frc: NSFetchedResultsController<ChapterEntity> = {
        let _freq: NSFetchRequest<ChapterEntity> = ChapterEntity.fetchRequest()
        _freq.predicate = .init(format: "book == %@", bookWant.objectID)
        _freq.sortDescriptors = [.init(key: #keyPath(ChapterEntity.offset), ascending: true)]
        let _frc: NSFetchedResultsController<ChapterEntity> = .init(fetchRequest: _freq,
                                                                    managedObjectContext: BookHelper.viewContext,
                                                                    sectionNameKeyPath: .none, cacheName: .none)
        _frc.delegate = self
        return _frc
    }()
    
    /// BookEntity.Want
    private let bookWant: BookEntity.Want
    
    /// Configuration
    private let configuration: Configuration
    
    /// Optional<ChapterEntity.Want>
    private let chapterWant: Optional<ChapterEntity.Want>
    
    //  MARK: - 生命周期
    
    /// 构造函数
    /// - Parameters:
    ///   - bookWant: BookEntity.Want
    ///   - configuration: Configuration
    internal init(forWhat bookWant: BookEntity.Want, configuration: Configuration) {
        self.bookWant = bookWant
        self.configuration = configuration
        self.chapterWant = bookWant.chapterAt(.none)
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
        // next
        Task(priority: .userInitiated) {
            try frc.performFetch()
        }
    }
    
    /// traitCollectionDidChange
    /// - Parameter previousTraitCollection: UITraitCollection
    internal override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        view.backgroundColor = configuration.theme.barTint
        tableView.separatorColor = configuration.theme.separatorTint
    }
}

extension ChapterViewController {
    
    /// 初始化
    private func initialize() {
        view.backgroundColor = configuration.theme.barTint
        
        // 布局
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
            tableView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
}

//  MARK: - NSFetchedResultsControllerDelegate
extension ChapterViewController: NSFetchedResultsControllerDelegate, UITableViewDelegate {
    
    /// didChangeContentWith
    /// - Parameters:
    ///   - controller: NSFetchedResultsController<any NSFetchRequestResult>
    ///   - snapshot: NSDiffableDataSourceSnapshotReference
    internal func controller(_ controller: NSFetchedResultsController<any NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        let before = snapshot as NSDiffableDataSourceSnapshot<String, NSManagedObjectID>
        var now: NSDiffableDataSourceSnapshot<String, ChapterEntity.Want> = .init()
        now.appendSections(before.sectionIdentifiers)
        now.sectionIdentifiers.forEach { sectionIdentifier in
            let itemIdentifiers = before.itemIdentifiers(inSection: sectionIdentifier).compactMap { objectID in
                if let obj = try? controller.managedObjectContext.existingObject(with: objectID) as? ChapterEntity {
                    return obj.hub.want
                } else {
                    return .none
                }
            }
            now.appendItems(itemIdentifiers, toSection: sectionIdentifier)
        }
        dataSource.apply(now, animatingDifferences: false)
        tableView.backgroundView?.isHidden = now.itemIdentifiers.isEmpty == false
        if let itemIdentifier = now.itemIdentifiers.first(where: { chapterWant?.objectID == $0.objectID }),
           let indexPath: IndexPath = dataSource.indexPath(for: itemIdentifier) {
            tableView.scrollToRow(at: indexPath, at: .middle, animated: false)
        }
    }
    
    /// didSelectRowAt
    /// - Parameters:
    ///   - tableView: UITableView
    ///   - indexPath: IndexPath
    internal func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        if let itemIdentifier = dataSource.itemIdentifier(for: indexPath), let delegate = delegate {
            delegate.controller(self, selectedActionWith: itemIdentifier)
        }
    }
}

#endif
