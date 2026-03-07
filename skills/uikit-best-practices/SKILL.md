---
name: uikit-best-practices
description: UIKit development best practices. Use this skill whenever the user mentions UIKit, UIViewController, Auto Layout, UITableView, UICollectionView, or needs guidance on iOS UI implementation using UIKit with Swift.
---

# UIKit 最佳实践

本技能提供使用 UIKit 实现 iOS 功能的标准工作流程和最佳实践（Swift 实现）。

## 核心原则

1. **遵循 Apple 官方指南** - 优先参考 [Apple Developer Documentation](https://developer.apple.com/documentation)
2. **ViewController 职责单一** - 每个 ViewController 只负责一个功能模块
3. **生命周期意识** - 正确管理 `viewDidLoad`, `viewWillAppear`, `viewDidAppear` 等生命周期
4. **内存管理** - 使用 ARC，注意循环引用
5. **线程安全** - UI 操作必须在主线程，耗时操作在后台线程

---

## 实现流程

### 阶段 1: 需求分析

在写代码之前，明确以下内容：

1. **功能边界** - 这个功能做什么，不做什么
2. **用户流程** - 用户如何与功能交互
3. **数据流** - 数据来源、存储位置、同步方式
4. **依赖关系** - 需要哪些现有模块的支持

### 阶段 2: 架构设计

#### 推荐架构模式

**MVVM（推荐）**:
```
View (UIView/UIViewController)
    ↓
ViewModel (业务逻辑、数据转换)
    ↓
Model (数据模型)
```

**MVC（Apple 传统）**:
```
View ←→ Controller ←→ Model
```

#### 文件组织结构

```
Features/
└── FeatureName/
    ├── FeatureNameViewController.swift
    ├── FeatureNameViewModel.swift (如使用 MVVM)
    ├── Views/
    │   ├── CustomView1.swift
    │   └── CustomView2.swift
    ├── Models/
    │   └── FeatureModel.swift
    └── Cells/ (如有 TableView/CollectionView)
        └── FeatureCell.swift
```

### 阶段 3: 代码实现

#### 1. ViewController 模板

```swift
import UIKit

final class FeatureViewController: UIViewController {

    // MARK: - UI Components
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textAlignment = .center
        return label
    }()

    private let actionButton: UIButton = {
        let button = UIButton(configuration: .filled())
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("操作", for: .normal)
        return button
    }()

    // MARK: - Properties
    private var viewModel: FeatureViewModel?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupActions()
        bindViewModel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 每次出现时需要刷新的逻辑
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // 动画、埋点等需要在出现后执行的逻辑
    }

    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        navigationItem.title = "功能名称"

        view.addSubview(titleLabel)
        view.addSubview(actionButton)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            actionButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            actionButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            actionButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            actionButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    private func setupActions() {
        actionButton.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
    }

    @objc private func actionButtonTapped() {
        viewModel?.handleAction()
    }

    // MARK: - ViewModel Binding
    private func bindViewModel() {
        viewModel?.onUpdate = { [weak self] in
            self?.updateUI()
        }
    }

    private func updateUI() {
        // 根据 ViewModel 数据更新 UI
    }
}
```

#### 2. ViewModel 模板（如使用 MVVM）

```swift
import Foundation

@MainActor
final class FeatureViewModel: ObservableObject {

    // MARK: - Published Properties
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // MARK: - Dependencies
    private let service: FeatureServiceProtocol

    // MARK: - Callbacks
    var onUpdate: (() -> Void)?

    // MARK: - Initialization
    init(service: FeatureServiceProtocol = FeatureService()) {
        self.service = service
    }

    // MARK: - Business Logic
    func handleAction() async {
        isLoading = true
        await MainActor.run { onUpdate?() }

        do {
            try await service.fetchData()
            isLoading = false
            await MainActor.run { onUpdate?() }
        } catch {
            errorMessage = error.localizedDescription
            await MainActor.run { onUpdate?() }
        }
    }
}
```

#### 3. 自定义 View 模板

```swift
import UIKit

final class CustomView: UIView {

    // MARK: - UI Components
    private let contentView = UIView()

    // MARK: - Properties
    var onValueChange: ((String) -> Void)?

    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    // MARK: - Setup
    private func setupView() {
        addSubview(contentView)
        setupConstraints()
        configureStyle()
    }

    private func setupConstraints() {
        contentView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func configureStyle() {
        backgroundColor = .systemGray6
        layer.cornerRadius = 12
    }

    // MARK: - Public Methods
    func configure(with data: String) {
        // 配置视图内容
    }

    // MARK: - Override
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        configureStyle()
    }
}
```

---

## 关键注意事项

### 生命周期管理

| 方法 | 调用时机 | 适用场景 |
|------|----------|----------|
| `viewDidLoad` | 视图加载后仅一次 | 初始化 UI、添加子视图、设置约束 |
| `viewWillAppear` | 每次视图出现前 | 刷新数据、更新导航栏状态 |
| `viewDidAppear` | 每次视图出现后 | 启动动画、埋点上报 |
| `viewWillDisappear` | 视图消失前 | 保存状态、停止定时器 |
| `viewDidDisappear` | 视图消失后 | 清理资源、取消网络请求 |
| `deinit` | 对象销毁时 | 最终清理（通常不需要） |

### 内存管理最佳实践

```swift
// ✅ 正确：使用 [weak self] 避免循环引用
button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)

// ✅ 正确：闭包中的弱引用
viewModel.onUpdate = { [weak self] in
    self?.updateUI()
}

// ✅ 正确：Timer 使用弱引用
Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
    self?.tick()
}

// ❌ 错误：循环引用
viewModel.onUpdate = {
    self.updateUI()  // 可能导致循环引用
}
```

### 线程安全

```swift
// ✅ 正确：UI 更新在主线程
DispatchQueue.main.async {
    self.label.text = "Updated"
}

// ✅ 正确：耗时操作在后台
Task {
    let data = try await service.fetchData()
    await MainActor.run {
        self.updateUI(with: data)
    }
}

// ❌ 错误：在后台线程更新 UI
Task {
    let data = try await service.fetchData()
    self.label.text = data  // 危险！
}
```

---

## UIKit 组件最佳实践

### UITableView

```swift
// ✅ 正确：使用 diffable data source (iOS 13+)
class UserListViewController: UIViewController {

    private var dataSource: UITableViewDiffableDataSource<Int, User>!
    private var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
    }

    private func setupTableView() {
        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.register(UserCell.self, forCellReuseIdentifier: "UserCell")
        view.addSubview(tableView)

        dataSource = UITableViewDiffableDataSource<Int, User>(
            tableView: tableView
        ) { [weak self] tableView, indexPath, user in
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: "UserCell",
                for: indexPath
            ) as? UserCell else {
                fatalError("Unable to dequeue UserCell")
            }
            cell.configure(with: user)
            return cell
        }

        applySnapshot(users: [])
    }

    private func applySnapshot(users: [User], animatingDifferences: Bool = true) {
        var snapshot = NSDiffableDataSourceSnapshot<Int, User>()
        snapshot.appendSections([0])
        snapshot.appendItems(users)
        dataSource.apply(snapshot, animatingDifferences: animatingDifferences)
    }
}

// Cell 实现
class UserCell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        // 设置约束...
    }

    func configure(with user: User) {
        textLabel?.text = user.name
        detailTextLabel?.text = user.email
    }
}
```

### UICollectionView

```swift
// ✅ 正确：使用 Compositional Layout (iOS 13+)
class PhotoGridViewController: UIViewController {

    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Int, Photo>!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
    }

    private func setupCollectionView() {
        let layout = createLayout()
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.register(PhotoCell.self, forCellWithReuseIdentifier: "PhotoCell")
        collectionView.delegate = self
        view.addSubview(collectionView)

        dataSource = UICollectionViewDiffableDataSource<Int, Photo>(
            collectionView: collectionView
        ) { collectionView, indexPath, photo in
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "PhotoCell",
                for: indexPath
            ) as? PhotoCell else {
                fatalError("Unable to dequeue PhotoCell")
            }
            cell.configure(with: photo)
            return cell
        }
    }

    private func createLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(0.5),
            heightDimension: .fractionalHeight(1.0)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSCollectionLayoutEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(200)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSCollectionLayoutEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)

        return UICollectionViewCompositionalLayout(section: section)
    }
}
```

### Auto Layout

```swift
// ✅ 正确：使用 NSLayoutConstraint.activate
NSLayoutConstraint.activate([
    titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
    titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
    titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
])

// ✅ 正确：使用 layoutMarginsGuide
NSLayoutConstraint.activate([
    stackView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
    stackView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
    stackView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor)
])

// ✅ 正确：使用 anchor 链式调用（iOS 11+）
titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16).isActive = true

// ❌ 错误：使用 string 形式的约束（性能差、难调试）
view.addConstraints(NSLayoutConstraint.constraints(
    withVisualFormat: "H:|-16-[title]-16-|",
    options: [],
    metrics: nil,
    views: ["title": titleLabel]
))
```

---

## 检查清单

在提交代码前，请确认：

- [ ] ViewController 职责单一，没有过多代码
- [ ] UI 代码与业务逻辑分离（使用 ViewModel）
- [ ] 所有约束正确设置（无 Ambiguous/Conflicting）
- [ ] 适配了 Dark Mode（使用系统颜色）
- [ ] 处理了空状态和错误状态
- [ ] 网络请求在后台线程，UI 更新在主线程
- [ ] 移除了所有 print 和调试代码
- [ ] 添加了必要的注释
- [ ] 使用了 diffable data source（TableView/CollectionView）

---

## 参考资源

- [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [UIKit Documentation](https://developer.apple.com/documentation/uikit)
- [Swift Coding Conventions](https://swift.org/documentation/api-design-guidelines/)
