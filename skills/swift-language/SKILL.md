---
name: swift-language
description: Swift language best practices. Use this skill whenever the user mentions Swift programming, Swift syntax, memory management, async/await, generics, protocols, or needs guidance on writing idiomatic Swift code.
---

# Swift 语言最佳实践

本技能提供 Swift 语言开发的标准工作流程和最佳实践。

## 核心原则

1. **Swift 风格** - 遵循 Swift API Design Guidelines
2. **值类型优先** - struct 优于 class
3. **协议导向** - Protocol-Oriented Programming
4. **类型安全** - 充分利用类型系统
5. **现代 Swift** - 使用最新 Swift 特性

---

## 内存管理

### ARC 基础规则

```swift
// ✅ 正确：class 使用 weak 避免循环引用
class ViewController: UIViewController {
    weak var delegate: DataSourceDelegate?

    var completionBlock: (() -> Void)?  // 闭包默认不持有 self
}

// ✅ 正确：闭包中使用 [weak self]
viewModel.onUpdate = { [weak self] in
    self?.updateUI()
}

// ✅ 正确：@escaping 闭包必须使用 weak
func loadData(completion: @escaping (Result<Data, Error>) -> Void) {
    service.fetch { [weak self] result in
        self?.handleResult(result)
        completion(result)
    }
}

// ❌ 错误：循环引用
class MyViewController: UIViewController {
    var handler: (() -> Void)?

    func setup() {
        handler = {
            self.doSomething()  // self 被闭包强引用
        }
    }
}
```

### 值类型 vs 引用类型

```swift
// ✅ 正确：优先使用 struct
struct User {
    let id: String
    let name: String
}

// ✅ 正确：需要引用语义时使用 class
final class UserService {
    static let shared = UserService()
    private init() {}
}

// ✅ 正确：使用 final 避免不必要的继承
final class FeatureViewModel {
    // ...
}
```

---

## 并发编程

### async/await（iOS 15+ 推荐）

```swift
// ✅ 正确：使用 async/await
@MainActor
class UserViewModel: ObservableObject {
    @Published var users: [User] = []
    @Published var isLoading: Bool = false

    func loadUsers() async {
        isLoading = true
        defer { isLoading = false }

        do {
            // 并行请求
            async let users = userService.fetchUsers()
            async let stats = statsService.fetchStats()

            self.users = try await users
            let statistics = try await stats
        } catch {
            handleError(error)
        }
    }
}

// ✅ 正确：使用 Task 从同步上下文调用
@IBAction func refreshTapped(_ sender: UIButton) {
    Task {
        await viewModel.loadUsers()
    }
}

// ✅ 正确：使用 Task.detached 进行后台任务
func processInBackground() {
    Task.detached {
        let result = try await heavyComputation()
        await MainActor.run {
            self.updateUI(with: result)
        }
    }
}
```

### Actor（iOS 15+）

```swift
// ✅ 正确：使用 Actor 保护可变状态
actor Counter {
    private var count = 0

    func increment() {
        count += 1
    }

    func getValue() -> Int {
        count
    }
}

// 使用
let counter = Counter()
Task {
    await counter.increment()
    let value = await counter.getValue()
}
```

### GCD（传统方式，仍然有效）

```swift
// ✅ 正确：GCD 后台执行 + 主线程更新
func loadData() {
    DispatchQueue.global(qos: .userInitiated).async {
        let data = self.fetchData()

        DispatchQueue.main.async {
            self.updateUI(with: data)
        }
    }
}

// ✅ 正确：使用 dispatch group 等待多个异步任务
func fetchAllData(completion: @escaping ([Data]) -> Void) {
    let group = DispatchGroup()
    var results: [Data] = []
    let queue = DispatchQueue(label: "com.app.fetch", attributes: .concurrent)

    group.enter()
    queue.async {
        let data1 = self.fetchData1()
        results.append(data1)
        group.leave()
    }

    group.enter()
    queue.async {
        let data2 = self.fetchData2()
        results.append(data2)
        group.leave()
    }

    group.notify(queue: .main) {
        completion(results)
    }
}
```

---

## 协议导向编程

### 基础协议

```swift
// ✅ 正确：定义清晰的协议
protocol DataSourceDelegate: AnyObject {
    func didUpdateData(_ sender: Any)
    func didFailWithError(_ error: Error)
}

// ✅ 正确：使用协议扩展提供默认实现
protocol Identifiable {
    var id: String { get }
}

extension Identifiable {
    var hashedId: Int {
        id.hashValue
    }
}

// ✅ 正确：协议组合
func process(item: Identifiable & CustomStringConvertible) {
    print("Processing \(item.description) with id \(item.id)")
}
```

### 类型擦除

```swift
// ✅ 正确：使用 any 进行类型擦除（Swift 5.7+）
class DataService {
    private var handlers: [any DataHandler] = []

    func addHandler(_ handler: some DataHandler) {
        handlers.append(handler)
    }
}

// ✅ 正确：使用 erased type
protocol AnyCancellable {
    func cancel()
}

class Subscription: AnyCancellable {
    func cancel() { }
}

var cancellables: Set<any AnyCancellable> = []
```

---

## 泛型

### 基础泛型

```swift
// ✅ 正确：泛型函数
func swapValues<T>(_ a: inout T, _ b: inout T) {
    let temp = a
    a = b
    b = temp
}

// ✅ 正确：泛型类型
struct Stack<Element> {
    private var items: [Element] = []

    mutating func push(_ item: Element) {
        items.append(item)
    }

    mutating func pop() -> Element? {
        items.popLast()
    }
}
```

### 泛型约束

```swift
// ✅ 正确：where 子句约束
func process<T: Sequence>(_ items: T) where T.Element: Identifiable {
    for item in items {
        print(item.id)
    }
}

// ✅ 正确：associatedtype 约束
protocol Repository {
    associatedtype Entity: Identifiable

    func fetch(id: String) async throws -> Entity
    func save(_ entity: Entity) async throws
}

// ✅ 正确：some 关键字（Swift 5.7+）
func makeCounter() -> some CounterProtocol {
    Counter()
}
```

---

## 错误处理

### 定义错误类型

```swift
// ✅ 正确：使用 enum 定义错误
enum APIError: LocalizedError {
    case networkUnavailable
    case unauthorized
    case serverError(Int)
    case decodingError(String)

    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "网络连接不可用"
        case .unauthorized:
            return "未授权访问"
        case .serverError(let code):
            return "服务器错误 (\(code))"
        case .decodingError(let message):
            return "数据解析失败：\(message)"
        }
    }
}
```

### 错误处理模式

```swift
// ✅ 正确：do-catch 处理
func loadUserData() {
    do {
        let user = try await userService.fetchUser()
        updateUserUI(user)
    } catch APIError.unauthorized {
        showLoginScreen()
    } catch {
        showErrorAlert(error.localizedDescription)
    }
}

// ✅ 正确：使用 Result 类型
enum LoadState {
    case idle
    case loading
    case success(User)
    case failure(Error)
}

// ✅ 正确：try? 转换为可选
let user = try? await userService.fetchUser()

// ✅ 正确：try! 仅在确定成功时使用（测试中）
let user = try! await userService.fetchUser()  // 失败会崩溃
```

---

## 属性包装器

### 内置包装器

```swift
// @State - 视图私有状态
@State private var count = 0

// @Binding - 与父视图共享状态
@Binding var value: Int

// @StateObject - 拥有并创建可观察对象
@StateObject private var viewModel = ViewModel()

// @ObservedObject - 引用外部可观察对象
@ObservedObject var viewModel: ViewModel

// @EnvironmentObject - 跨层级共享
@EnvironmentObject var settings: UserSettings

// @Published - 标记可变属性
@Published var data: String = ""
```

### 自定义包装器

```swift
// ✅ 正确：自定义属性包装器
@propertyWrapper
struct UserDefault<T> {
    let key: String
    let defaultValue: T

    var wrappedValue: T {
        get {
            UserDefaults.standard.object(forKey: key) as? T ?? defaultValue
        }
        set {
            UserDefaults.standard.set(newValue, forKey: key)
        }
    }
}

// 使用
class Settings {
    @UserDefault(key: "isDarkMode", defaultValue: false)
    static var isDarkMode: Bool
}
```

---

## 字符串与插值

```swift
// ✅ 正确：字符串插值
let greeting = "Hello, \(name)!"

// ✅ 正确：多行字符串
let json = """
{
    "name": "\(name)",
    "age": \(age)
}
"""

// ✅ 正确：字符串性能优化
var result = ""
result.reserveCapacity(100)  // 预分配容量
for i in 0..<10 {
    result.append("\(i)")
}

// ❌ 错误：循环中频繁拼接
for i in 0..<1000 {
    result += "\(i)"  // 每次都创建新字符串
}
```

---

## 集合操作

```swift
// ✅ 正确：函数式操作
let names = users.map { $0.name }
let adults = users.filter { $0.age >= 18 }
let totalAge = users.reduce(0) { $0 + $1.age }

// ✅ 正确：链式调用
let adultNames = users
    .filter { $0.age >= 18 }
    .map { $0.name.uppercased() }
    .sorted()

// ✅ 正确：字典分组
let usersByAge = Dictionary(grouping: users, by: { $0.age })

// ✅ 正确：集合操作
let set1: Set = [1, 2, 3]
let set2: Set = [3, 4, 5]
let union = set1.union(set2)
let intersection = set1.intersection(set2)
```

---

## 检查清单

在提交 Swift 代码前，请确认：

- [ ] 遵循 Swift API Design Guidelines
- [ ] 优先使用 struct 而非 class
- [ ] 闭包正确使用 [weak self]
- [ ] 使用 async/await 处理并发
- [ ] 错误类型定义清晰
- [ ] 协议定义简洁，有默认实现
- [ ] 泛型约束明确
- [ ] 使用 latest Swift 特性

---

## 参考资源

- [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- [Swift Documentation](https://docs.swift.org/swift-book/)
- [WWDC Swift Concurrency](https://developer.apple.com/videos/play/wwdc2021/10132/)
