---
name: testing-debugging
description: iOS testing and debugging best practices. Use this skill whenever the user mentions unit tests, UI tests, XCTest, debugging, Instruments, crash analysis, or app quality assurance.
---

# 测试与调试最佳实践

本技能提供 iOS 应用测试和调试的标准工作流程和最佳实践。

## 核心原则

1. **测试驱动** - 关键功能先写测试
2. **自动化** - CI/CD 集成测试
3. **快速反馈** - 测试执行要快
4. **可重复** - 测试结果稳定可靠
5. **覆盖率** - 核心业务逻辑 80%+ 覆盖

---

## 单元测试

### XCTest 基础

```swift
import XCTest
@testable import MyApp

// ✅ 正确：标准测试类结构
final class UserViewModelTests: XCTestCase {

    // MARK: - Properties
    var viewModel: UserViewModel!
    var mockService: MockUserService!

    // MARK: - Setup
    override func setUp() {
        super.setUp()
        mockService = MockUserService()
        viewModel = UserViewModel(service: mockService)
    }

    override func tearDown() {
        viewModel = nil
        mockService = nil
        super.tearDown()
    }

    // MARK: - Tests
    func testLoadUsers_Success() async throws {
        // Given
        mockService.shouldSucceed = true
        let expectedUsers = [User(id: "1", name: "Test")]
        mockService.mockUsers = expectedUsers

        // When
        await viewModel.loadUsers()

        // Then
        XCTAssertEqual(viewModel.users.count, 1)
        XCTAssertEqual(viewModel.users[0].name, "Test")
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testLoadUsers_Failure() async throws {
        // Given
        mockService.shouldSucceed = false

        // When
        await viewModel.loadUsers()

        // Then
        XCTAssertTrue(viewModel.users.isEmpty)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    func testDeleteUser() {
        // Given
        viewModel.users = [
            User(id: "1", name: "User 1"),
            User(id: "2", name: "User 2")
        ]

        // When
        viewModel.deleteUser(id: "1")

        // Then
        XCTAssertEqual(viewModel.users.count, 1)
        XCTAssertEqual(viewModel.users[0].id, "2")
    }
}
```

### Mock 对象

```swift
// ✅ 正确：创建 Mock 服务
class MockUserService: UserServiceProtocol {

    var shouldSucceed = true
    var mockUsers: [User] = []
    var fetchCalled = false
    var fetchId: String?

    func fetchUsers() async throws -> [User] {
        fetchCalled = true
        if shouldSucceed {
            return mockUsers
        }
        throw NetworkError.networkUnavailable
    }

    func fetchUser(id: String) async throws -> User {
        fetchId = id
        if shouldSucceed {
            return mockUsers.first ?? User(id: id, name: "Mock")
        }
        throw NetworkError.notFound
    }
}

// ✅ 正确：使用 Protocol 便于 Mock
protocol UserServiceProtocol {
    func fetchUsers() async throws -> [User]
    func fetchUser(id: String) async throws -> User
}

// 生产环境使用真实实现
class UserService: UserServiceProtocol {
    // 真实网络请求
}
```

### 测试异步代码

```swift
// ✅ 正确：测试 async/await
func testAsyncMethod() async throws {
    let result = try await service.fetchData()
    XCTAssertEqual(result.count, 10)
}

// ✅ 正确：测试 Completion Handler
func testCompletionHandler() {
    let expectation = XCTestExpectation(description: "Fetch completes")

    service.fetchData { result in
        switch result {
        case .success(let data):
            XCTAssertEqual(data.count, 10)
        case .failure:
            XCTFail("Should not fail")
        }
        expectation.fulfill()
    }

    wait(for: [expectation], timeout: 5.0)
}

// ✅ 正确：测试 Combine
func testCombinePublisher() {
    let expectation = XCTestExpectation(description: "Receive value")

    viewModel.$users
        .dropFirst()  // 跳过初始值
        .sink { users in
            XCTAssertEqual(users.count, 1)
            expectation.fulfill()
        }
        .store(in: &cancellables)

    Task {
        await viewModel.loadUsers()
    }

    wait(for: [expectation], timeout: 5.0)
}

// ✅ 正确：测试 NotificationCenter
func testNotificationCenter() {
    let expectation = expectation(forNotification: .userDidLogin,
                                   object: nil) { notification in
        XCTAssertEqual(notification.userInfo?["userId"] as? String, "123")
        return true
    }

    NotificationCenter.default.post(name: .userDidLogin,
                                     object: nil,
                                     userInfo: ["userId": "123"])

    wait(for: [expectation], timeout: 1.0)
}
```

### 测试性能

```swift
// ✅ 正确：性能测试
func testPerformance() {
    measure {
        // 执行 10 次，记录平均时间
        let result = parser.parse(largeData)
        XCTAssertGreaterThan(result.count, 0)
    }
}

// ✅ 正确：内存测试
func testMemoryUsage() {
    let startMemory = VMTracker.memoryUsage

    // 执行操作
    let images = (0..<100).map { _ in UIImage() }

    let endMemory = VMTracker.memoryUsage
    let delta = endMemory - startMemory

    XCTAssertLessThan(delta, 50 * 1024 * 1024)  // 小于 50MB
}
```

---

## UI 测试

### XCUIRecord 基础

```swift
import XCTest

// ✅ 正确：UI 测试标准结构
class MyAppUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    func testLoginFlow() {
        // 输入账号密码
        app.textFields["emailField"].tap()
        app.textFields["emailField"].typeText("test@example.com")

        app.secureTextFields["passwordField"].tap()
        app.secureTextFields["passwordField"].typeText("password123")

        // 点击登录
        app.buttons["登录"].tap()

        // 验证跳转
        XCTAssertTrue(app.staticTexts["欢迎"].exists)
    }

    func testListScrolling() {
        let table = app.tables["mainTable"]

        // 滑动到底部
        table.swipeUp()
        table.swipeUp()

        // 验证内容
        XCTAssertTrue(table.cells.element(boundBy: 10).exists)
    }
}
```

### 测试启动参数

```swift
// ✅ 正确：使用 Launch Argument 控制测试环境
func testWithMockServer() {
    app.launchArguments = ["-UITesting", "-MockServer"]
    app.launch()

    // 使用 Mock 数据测试
    XCTAssertTrue(app.staticTexts["Mock Data"].exists)
}

// App 中检测
if ProcessInfo.processInfo.arguments.contains("-UITesting") {
    // 使用 Mock 服务
}
```

### 等待元素

```swift
// ✅ 正确：等待元素出现
func testWaitForElement() {
    let loadingIndicator = app.activityIndicators.first

    // 等待加载完成
    let exists = NSPredicate(format: "exists == 0")
    expectation(for: exists, evaluatedWith: loadingIndicator)
    waitForExpectations(timeout: 10)

    // 验证内容显示
    XCTAssertTrue(app.staticTexts["Content"].exists)
}
```

---

## 调试技巧

### LLDB 常用命令

```bash
# 打印变量
print variableName
p variableName

# 打印对象描述
po objectName

# 查看调用栈
bt
thread backtrace

# 查看变量类型
typeOf variableName

# 条件断点
breakpoint set -name methodName -c "variable == 5"

# 自动继续
breakpoint set -o true -c "condition"

# 查看 UI 层级
recursiveDescription

# 网络请求调试
CFNetworkDiagnosticTool
```

### 断点类型

```swift
// ✅ 正确：使用符号断点
// Exception Breakpoint - 捕获所有异常
// NSError Breakpoint - 捕获错误

// ✅ 正确：使用条件断点
func process(value: Int) {
    // 只在 value > 100 时中断
    breakpoint()  // 手动断点
    if value > 100 {
        // 特殊处理
    }
}

// ✅ 正确：使用 os_log 调试
import os

class Logger {
    static let log = OSLog(subsystem: "com.app", category: "Debug")

    static func debug(_ message: String) {
        os_log("🐛 %{public}@", log: log, type: .debug, message)
    }

    static func error(_ message: String) {
        os_log("❌ %{public}@", log: log, type: .error, message)
    }
}

// 使用
Logger.debug("用户登录：\(email)")
```

### 视图调试

```swift
// ✅ 正确：使用 Xcode View Debugger
// 1. 运行 App
// 2. Debug → View Debugging → Capture View Hierarchy
// 3. 检查视图层级和约束

// ✅ 正确：使用 Reveal App
// 第三方工具，更强大的视图调试

// ✅ 正确：代码打印约束
func debugConstraints() {
    for constraint in view.constraints {
        print(constraint.debugDescription)
    }
}
```

---

## Instruments 使用

### 常用工具

| 工具 | 用途 | 典型场景 |
|------|------|----------|
| Time Profiler | CPU 分析 | 查找卡顿原因 |
| Allocations | 内存分配 | 内存泄漏检测 |
| Leaks | 内存泄漏 | 对象未释放 |
| VM Tracker | 虚拟内存 | 内存压力分析 |
| Energy Log | 电量消耗 | 耗电优化 |
| Network | 网络分析 | 请求性能 |
| Core Animation | 渲染性能 | FPS 检测 |

### 使用流程

```
1. Xcode → Product → Profile (Cmd+I)
2. 选择 Instruments 工具
3. 执行操作
4. 分析数据
5. 定位问题
6. 修复验证
```

---

## 持续集成

### GitHub Actions 示例

```yaml
# ✅ 正确：CI 配置
name: iOS CI

on: [push, pull_request]

jobs:
  build-and-test:
    runs-on: macos-latest

    steps:
    - uses: actions/checkout@v3

    - name: Select Xcode
      run: sudo xcode-select -s /Applications/Xcode_15.0.app

    - name: Build
      run: xcodebuild -scheme MyApp -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 15' build

    - name: Run Tests
      run: xcodebuild test -scheme MyApp -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 15'

    - name: Upload Coverage
      uses: codecov/codecov-action@v3
```

---

## 检查清单

在发布前，请确认：

- [ ] 单元测试通过率 100%
- [ ] 核心功能有测试覆盖
- [ ] UI 测试关键流程
- [ ] 无内存泄漏
- [ ] 无明显性能问题
- [ ] Crash-free 率 > 99%

---

## 参考资源

- [XCTest Documentation](https://developer.apple.com/documentation/xctest)
- [WWDC Testing](https://developer.apple.com/videos/testing/)
- [Instruments](https://developer.apple.com/documentation/instruments)
