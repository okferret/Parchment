//
//  BookmarkViewController.swift
//  Parchment
//
//  Created by okferret on 2026/6/5.
//
#if canImport(UIKit)
import UIKit
import CoreData

/// BookmarkViewControllerDelegate
protocol BookmarkViewControllerDelegate: AnyObject {
    
    /// selectActionWith
    /// - Parameters:
    ///   - controller: BookmarkViewController
    ///   - newWant: MarkEntity.Want
    func controller(_ controller: BookmarkViewController, selectedActionWith newWant: MarkEntity.Want)
}

class BookmarkViewController: UIViewController {
    
    //  MARK: - 公开属性
    
    /// Optional<BookmarkViewControllerDelegate>
    internal weak var delegate: Optional<BookmarkViewControllerDelegate> = .none
    
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
        _tableView.rowHeight = 80.0
        _tableView.register(BookmarkViewCell.self, forCellReuseIdentifier: BookmarkViewCell.reusedID)
        _tableView.separatorInset = .init(top: 0.0, left: 16.0, bottom: 0.0, right: 16.0)
        _tableView.separatorColor = configuration.theme.separatorTint
        _tableView.delegate = self
        return _tableView
    }()
    
    /// UITableViewDiffableDataSource<String, MarkEntity.Want>
    private lazy var dataSource: UITableViewDiffableDataSource<String, MarkEntity.Want> = .init(tableView: tableView) {[weak configuration] tableView, indexPath, itemIdentifier in
        let cell: BookmarkViewCell = tableView.dequeueReusableCell(withIdentifier: BookmarkViewCell.reusedID, for: indexPath) as! BookmarkViewCell
        cell.markWant = itemIdentifier
        cell.theme = configuration?.theme
        return cell
    }
    
    /// NSFetchedResultsController<MarkEntity>
    private lazy var frc: NSFetchedResultsController<MarkEntity> = {
        let _freq: NSFetchRequest<MarkEntity> = MarkEntity.fetchRequest()
        _freq.sortDescriptors = [.init(key: #keyPath(MarkEntity.createdAt), ascending: false)]
        _freq.predicate = .init(format: "book == %@", bookWant.objectID)
        let _frc: NSFetchedResultsController<MarkEntity> = .init(fetchRequest: _freq,
                                                                 managedObjectContext: BookHelper.viewContext,
                                                                 sectionNameKeyPath: .none,
                                                                 cacheName: .none)
        _frc.delegate = self
        return _frc
    }()
    
    /// BookEntity.Want
    private let bookWant: BookEntity.Want
    
    /// Configuration
    private let configuration: Configuration
    
    //  MARK: - 生命周期
    
    /// 构造函数
    /// - Parameters:
    ///   - bookWant: BookEntity.Want
    ///   - configuration: Configuration
    internal init(forWhat bookWant: BookEntity.Want, configuration: Configuration) {
        self.bookWant = bookWant
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
        // fetch
        Task(priority: .userInitiated) {
            try frc.performFetch()
        }
    }
    
    /// traitCollectionDidChange
    /// - Parameter previousTraitCollection: UITraitCollection
    internal override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        view.backgroundColor = configuration.theme.barTint
    }
}

extension BookmarkViewController {
    
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
extension BookmarkViewController: NSFetchedResultsControllerDelegate {
    
    /// didChangeContentWith
    /// - Parameters:
    ///   - controller: NSFetchedResultsController<any NSFetchRequestResult>
    ///   - snapshot: NSDiffableDataSourceSnapshotReference
    internal func controller(_ controller: NSFetchedResultsController<any NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        let snapshot = snapshot as NSDiffableDataSourceSnapshot<String, NSManagedObjectID>
        var now: NSDiffableDataSourceSnapshot<String, MarkEntity.Want> = .init()
        now.appendSections(snapshot.sectionIdentifiers)
        snapshot.sectionIdentifiers.forEach { sectionIdentifier in
            let elements: Array<MarkEntity.Want> = snapshot.itemIdentifiers(inSection: sectionIdentifier).compactMap { objectID in
                if let obj = try? controller.managedObjectContext.existingObject(with: objectID) as? MarkEntity {
                    return obj.hub.want
                } else {
                    return .none
                }
            }
            now.appendItems(elements, toSection: sectionIdentifier)
        }
        dataSource.apply(now, animatingDifferences: false)
        tableView.backgroundView?.isHidden = now.itemIdentifiers.isEmpty == false
    }
}

//  MARK: - UITableViewDelegate
extension BookmarkViewController: UITableViewDelegate {
    
    /// didSelectRowAt
    /// - Parameters:
    ///   - tableView: UITableView
    ///   - indexPath: IndexPath
    internal func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer { tableView.deselectRow(at: indexPath, animated: false) }
        guard let itemIdentifier = dataSource.itemIdentifier(for: indexPath) else { return }
        delegate?.controller(self, selectedActionWith: itemIdentifier)
    }
}

#endif
