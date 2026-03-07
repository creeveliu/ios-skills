---
name: ios-architecture
description: iOS app architecture best practices. Use this skill whenever the user mentions project structure, MVVM, MVC, VIPER, dependency injection, modularization, app architecture patterns, or needs guidance on organizing iOS codebases for scalability and maintainability.
---

# iOS 应用架构最佳实践

本技能提供 iOS 应用架构设计的标准工作流程和最佳实践。

## 核心原则

1. **单一职责** - 每个类/模块只负责一件事
2. **依赖倒置** - 依赖抽象而非具体实现
3. **数据流清晰** - 单向数据流，状态变化可预测
4. **可测试性** - 架构设计便于单元测试
5. **模块化** - 功能模块独立，可复用

---

## 架构模式对比

### MVC (Model-View-Controller)

Apple 传统架构，适合小型项目。

```swift
// Model
struct User {
    let id: String
    let name: String
}

// View
class UserCell: UITableViewCell {
    func configure(with user: User) {
        textLabel?.text = user.name
    }
}

// Controller
class UserViewController: UIViewController {
    var users: [User] = []

    func loadUsers() {
        users = UserService.fetchUsers()
        tableView.reloadData()
    }
}
```

**优点**：简单、Apple 原生支持
**缺点**：ViewController 容易臃肿

---

### MVVM (Model-View-ViewModel) - 推荐

适合中大型项目，逻辑分离清晰。

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│    Model    │ ←→  │  ViewModel  │ ←→  │    View     │
│  (数据层)   │     │ (业务逻辑)  │     │  (UI 层)    │
└─────────────┘     └─────────────┘     └─────────────┘
```

**职责划分**：
- **Model**：数据结构、数据持久化
- **ViewModel**：业务逻辑、数据转换、状态管理
- **View**：ViewController + UIView，只负责 UI 展示

**实现示例**：

```swift
// Model
struct User {
    let id: String
    let name: String
    let email: String
}

// ViewModel
@MainActor
class UserViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var users: [User] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?

    // MARK: - Dependencies
    private let userService: UserServiceProtocol

    // MARK: - Initialization
    init(userService: UserServiceProtocol = UserService()) {
        self.userService = userService
    }

    // MARK: - Business Logic
    func loadUsers() async {
        isLoading = true
        defer { isLoading = false }

        do {
            users = try await userService.fetchUsers()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteUser(id: String) {
        users.removeAll { $0.id == id }
    }
}

// View (ViewController)
class UserListViewController: UIViewController {

    // MARK: - Properties
    @ObservedObject var viewModel: UserViewModel
    private let tableView = UITableView()

    // MARK: - Initialization
    init(viewModel: UserViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
        Task { await viewModel.loadUsers() }
    }

    // MARK: - Binding
    private func bindViewModel() {
        viewModel.$users.receive(on: DispatchQueue.main).sink { [weak self] _ in
            self?.tableView.reloadData()
        }.store(in: &cancellables)

        viewModel.$isLoading.receive(on: DispatchQueue.main).sink { [weak self] isLoading in
            isLoading ? self?.showLoading() : self?.hideLoading()
        }.store(in: &cancellables)
    }
}
```

**优点**：
- 逻辑分离，易于测试
- ViewController 轻量化
- 数据流清晰

**缺点**：
- 需要额外学习成本
- 小项目可能过度设计

---

### VIPER (View-Interactor-Presenter-Entity-Router)

适合超大型项目，职责极度细分。

```
┌─────────┐     ┌─────────┐     ┌─────────┐
│  View   │ ←→  │Presenter│ ←→  │Interactor│
└─────────┘     └─────────┘     └─────────┘
     ↑                ↑                ↑
  Router           Entity          Worker
```

**职责**：
- **View**：纯 UI，无逻辑
- **Presenter**：UI 逻辑、数据转换
- **Interactor**：业务逻辑、数据获取
- **Entity**：纯数据对象
- **Router**：页面跳转逻辑

---

## 依赖注入 (Dependency Injection)

### 协议注入（推荐）

```swift
// 定义协议
protocol UserServiceProtocol {
    func fetchUsers() async throws -> [User]
    func fetchUser(id: String) async throws -> User
}

// 具体实现
class UserService: UserServiceProtocol {
    func fetchUsers() async throws -> [User] {
        // 网络请求实现
    }
}

// Mock 实现（测试用）
class MockUserService: UserServiceProtocol {
    var shouldSucceed = true

    func fetchUsers() async throws -> [User] {
        if shouldSucceed {
            return [.mockUser]
        }
        throw NSError(domain: "Mock", code: -1)
    }
}

// 使用注入
class UserViewModel {
    private let userService: UserServiceProtocol

    init(userService: UserServiceProtocol = UserService()) {
        self.userService = userService
    }
}
```

### 工厂模式

```swift
class ServiceFactory {
    static func makeUserService() -> UserServiceProtocol {
        #if DEBUG
        return MockUserService()
        #else
        return UserService()
        #endif
    }
}
```

### 容器模式（大型项目）

```swift
final class DIContainer {
    static let shared = DIContainer()

    private var services: [String: Any] = [:]

    func register<Service>(_ service: Service, for type: Service.Type) {
        services[String(describing: type)] = service
    }

    func resolve<Service>(_ type: Service.Type) -> Service {
        services[String(describing: type)] as! Service
    }
}

// 使用
DIContainer.shared.register(UserService(), for: UserServiceProtocol.self)
let service: UserServiceProtocol = DIContainer.shared.resolve(UserServiceProtocol.self)
```

---

## 项目结构组织

### 按功能模块组织（推荐）

```
MyApp/
├── App/
│   ├── AppDelegate.swift
│   ├── SceneDelegate.swift
│   └── AppCoordinator.swift
├── Features/
│   ├── User/
│   │   ├── UserListViewController.swift
│   │   ├── UserViewModel.swift
│   │   ├── Views/
│   │   └── Cells/
│   ├── Login/
│   │   ├── LoginViewController.swift
│   │   └── LoginViewModel.swift
│   └── Settings/
│       └── ...
├── Core/
│   ├── Network/
│   │   ├── APIEndpoint.swift
│   │   └── NetworkService.swift
│   ├── Database/
│   └── Utils/
├── Resources/
│   ├── Assets.xcassets
│   ├── Localizable.strings
│   └── Fonts/
└── Tests/
    ├── UserTests/
    └── NetworkTests/
```

### 按层级组织（传统）

```
MyApp/
├── Models/
├── Views/
├── ViewControllers/
├── ViewModels/
├── Services/
├── Utils/
└── Resources/
```

---

## 模块化设计

### 定义模块边界

```swift
// UserModule.swift - 模块对外暴露的接口
public enum UserModule {
    public static func makeUserListViewController(
        onSelectUser: @escaping (User) -> Void
    ) -> UIViewController {
        let viewModel = UserViewModel()
        return UserListViewController(viewModel: viewModel, onSelectUser: onSelectUser)
    }
}

// 模块内部私有实现
fileprivate class UserListViewController: UIViewController {
    // 内部实现，外部不可见
}
```

### 模块间通信

```swift
// 使用协议解耦
protocol NavigationDelegate: AnyObject {
    func navigateToDetail(user: User)
}

class UserListViewController: UIViewController {
    weak var delegate: NavigationDelegate?

    private func userDidTap(user: User) {
        delegate?.navigateToDetail(user: user)
    }
}
```

---

## 检查清单

在提交架构相关代码前，请确认：

- [ ] 选择了适合项目规模的架构模式
- [ ] 依赖注入使用协议而非具体类型
- [ ] 项目结构清晰，按功能或层级组织
- [ ] 模块边界清晰，内部实现不暴露
- [ ] ViewModel/Presenter 可独立测试
- [ ] 数据流单向，状态变化可预测
- [ ] 避免了循环依赖

---

## 参考资源

- [Apple Architecture Guidelines](https://developer.apple.com/documentation/)
- [MVVM in Swift](https://www.kodeco.com/ios/tutorials/mvvm-tutorial-for-ios)
- [Dependency Injection in Swift](https://www.swiftbysundell.com/articles/dependency-injection-defined/)
