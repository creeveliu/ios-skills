---
name: app-stability
description: iOS app stability and crash prevention best practices. Use this skill whenever the user mentions crashes, stability, exception handling, thread safety, error handling, defensive programming, or app reliability.
---

# 稳定性与崩溃治理

本技能提供 iOS 应用稳定性保障和崩溃预防的最佳实践。

## 核心原则

1. **预防为主** - 通过代码质量减少崩溃
2. **快速发现** - 完善的崩溃监控和上报
3. **优雅降级** - 错误发生时不影响核心功能
4. **线程安全** - 正确的并发处理
5. **防御性编程** - 假设一切皆可能失败

---

## 崩溃类型与预防

### 常见崩溃类型

| 崩溃类型 | 原因 | 预防方案 |
|----------|------|----------|
| EXC_BAD_ACCESS | 访问已释放内存 | 使用 ARC，weak 引用检查 |
| EXC_CRASH (SIGABRT) | 未捕获异常 | try-catch，断言检查 |
| EXC_CRASH (SIGSEGV) | 野指针/数组越界 | 边界检查，可选绑定 |
| EXC_CRASH (SIGKILL) | 内存超限/ watchdog | 内存优化，后台任务管理 |
| EXC_RESOURCE | 资源超限 | CPU/内存监控 |

### 野指针预防

```swift
// ✅ 正确：访问前检查对象有效性
class DataProcessor {
    weak var delegate: DataDelegate?

    func processData() {
        // 访问前检查
        delegate?.didProcessData?(self)
    }
}

// ✅ 正确：使用 optional chaining
let firstName = user?.profile?.name?.components(separatedBy: " ").first

// ❌ 错误：强制解包可能导致崩溃
let name = user!.profile!.name!  // 任何一步为 nil 就崩溃
```

### 数组越界预防

```swift
// ✅ 正确：访问前检查边界
func getItem(at index: Int) -> Item? {
    guard index >= 0 && index < items.count else {
        return nil
    }
    return items[index]
}

// ✅ 正确：使用 safe subscript
extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// 使用
let item = items[safe: 5]

// ❌ 错误：直接访问可能越界
let item = items[5]  // count < 5 时崩溃
```

### 除零预防

```swift
// ✅ 正确：除零检查
func calculate(value: Double, divisor: Double) -> Double? {
    guard divisor != 0 else {
        return nil
    }
    return value / divisor
}

// ✅ 正确：使用 Result
func safeDivide(_ a: Int, by b: Int) -> Result<Int, DivisionError> {
    guard b != 0 else {
        return .failure(.divisionByZero)
    }
    return .success(a / b)
}
```

---

## 异常处理

### Swift 错误处理

```swift
// ✅ 正确：使用 do-catch 处理可能失败的 operasi
func loadUserData() {
    do {
        let user = try userService.fetchUser()
        updateUserUI(user)
    } catch NetworkError.unauthorized {
        // 特定错误处理
        showLoginScreen()
    } catch {
        // 通用错误处理
        showErrorAlert("加载失败：\(error.localizedDescription)")
    }
}

// ✅ 正确：使用 try? 转换为可选
let user = try? await userService.fetchUser()  // 失败返回 nil

// ✅ 正确：使用 try! 仅在测试中（确定不会失败）
// try! 在生产环境使用需极度谨慎
```

### NSAssert 使用

```swift
// ✅ 正确：使用断言检查前置条件
func updateUser(_ user: User) {
    // 开发环境检查，发布环境不执行
    assert(!user.id.isEmpty, "User ID 不能为空")
    precondition(user.age >= 0, "年龄不能为负数")
}

// ✅ 正确：检查不变量
class Counter {
    private var count = 0

    func increment() {
        count += 1
        assertion(count >= 0, "Counter 不应该为负数")
    }
}
```

### Objective-C 异常捕获

```objective-c
// ✅ 正确：@try-@catch 捕获 NSException
@try {
    [dangerousObject dangerousMethod];
} @catch (NSException *exception) {
    NSLog(@"捕获异常：%@", exception.name);
    // 记录日志，但不崩溃
} @finally {
    // 总是执行
}

// ⚠️ 注意：NSException 通常无法捕获 Swift 错误
```

---

## 线程安全

### 主线程更新 UI

```swift
// ✅ 正确：确保 UI 更新在主线程
func updateUI() {
    if Thread.isMainThread {
        _updateUI()
    } else {
        DispatchQueue.main.async {
            self._updateUI()
        }
    }
}

private func _updateUI() {
    label.text = "Updated"
}

// ✅ 正确：使用@MainActor (Swift 5.5+)
@MainActor
class ViewController: UIViewController {
    // 所有方法自动在主线程执行
    func updateUI() {
        label.text = "Updated"  // 安全
    }
}
```

### 线程同步

```swift
// ✅ 正确：使用 DispatchQueue 保护共享资源
class ThreadSafeCounter {
    private var count = 0
    private let queue = DispatchQueue(label: "com.counter.queue", attributes: .concurrent)

    func increment() {
        queue.async(flags: .barrier) {
            self.count += 1
        }
    }

    func getValue() -> Int {
        queue.sync {
            self.count
        }
    }
}

// ✅ 正确：使用 NSLock
class ThreadSafeCache {
    private var cache: [String: Any] = [:]
    private let lock = NSLock()

    func set(_ value: Any, forKey key: String) {
        lock.lock()
        defer { lock.unlock() }
        cache[key] = value
    }

    func get(forKey key: String) -> Any? {
        lock.lock()
        defer { lock.unlock() }
        return cache[key]
    }
}

// ✅ 正确：使用 Actor (Swift 5.5+)
actor Counter {
    private var count = 0

    func increment() {
        count += 1
    }

    func getValue() -> Int {
        count
    }
}
```

### 避免死锁

```swift
// ❌ 错误：主队列同步调用导致死锁
func badExample() {
    DispatchQueue.main.sync {  // 死锁！
        doSomething()
    }
}

// ✅ 正确：使用 async 异步调用
func goodExample() {
    DispatchQueue.main.async {
        doSomething()
    }
}

// ✅ 正确：如果不是在主线程才同步调用
func safeSync() {
    if Thread.isMainThread {
        doSomething()
    } else {
        DispatchQueue.main.sync {
            doSomething()
        }
    }
}
```

---

## 防御性编程

### 输入验证

```swift
// ✅ 正确：验证所有输入
func register(email: String, password: String) -> Result<User, ValidationError> {
    // 验证邮箱格式
    guard isValidEmail(email) else {
        return .failure(.invalidEmail)
    }

    // 验证密码强度
    guard password.count >= 8 else {
        return .failure(.weakPassword)
    }

    // 验证字符串不为空
    guard !email.isEmpty && !password.isEmpty else {
        return .failure(.emptyInput)
    }

    return .success(User(email: email))
}

private func isValidEmail(_ email: String) -> Bool {
    let regex = #"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"#
    return email.range(of: regex, options: .regularExpression) != nil
}
```

### 降级策略

```swift
// ✅ 正确：优雅降级
class ImageLoader {
    func loadImage(url: URL, completion: @escaping (UIImage?) -> Void) {
        // 1. 尝试从网络加载
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let data = data, let image = UIImage(data: data) {
                completion(image)
                return
            }

            // 2. 网络失败，尝试本地缓存
            if let cachedImage = self.loadFromCache(url: url) {
                completion(cachedImage)
                return
            }

            // 3. 缓存失败，返回占位图
            completion(UIImage(named: "placeholder"))
        }.resume()
    }
}

// ✅ 正确：特性开关
class FeatureFlag {
    static var isNewCheckoutEnabled: Bool {
        #if DEBUG
        return true
        #else
        return UserDefaults.standard.bool(forKey: "new_checkout_enabled")
        #endif
    }
}

// 使用
if FeatureFlag.isNewCheckoutEnabled {
    showNewCheckout()
} else {
    showOldCheckout()
}
```

---

## 崩溃监控

### 崩溃上报

```swift
// ✅ 正确：全局异常捕获
class CrashReporter {

    static let shared = CrashReporter()

    func start() {
        // Swift 全局未捕获异常
        NSSetUncaughtExceptionHandler { exception in
            self.reportException(exception)
        }

        // C++ 异常
        std::set_terminate {
            self.reportCPPException()
        }
    }

    private func reportException(_ exception: NSException) {
        let crashInfo = [
            "type": "NSException",
            "name": exception.name.rawValue,
            "reason": exception.reason ?? "",
            "stack": exception.callStackSymbols,
            "timestamp": Date().iso8601String
        ]
        sendToServer(crashInfo)
    }

    private func sendToServer(_ info: [String: Any]) {
        // 发送到崩溃监控服务器
    }
}
```

### 内存警告处理

```swift
// ✅ 正确：处理内存警告
class ViewController: UIViewController {

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()

        // 释放可重建的资源
        imageCache.removeAll()
        loadedData = nil

        // 记录日志
        Logger.warning("收到内存警告")
    }
}

// ✅ 正确：后台任务清理
var backgroundTask: UIBackgroundTaskIdentifier = .invalid

func beginBackgroundTask() {
    backgroundTask = UIApplication.shared.beginBackgroundTask {
        // 时间耗尽，清理资源
        self.cleanup()
        UIApplication.shared.endBackgroundTask(self.backgroundTask)
        self.backgroundTask = .invalid
    }
}
```

---

## 检查清单

在提交代码前，请确认：

- [ ] 所有可选值安全解包（无强制 unwrap）
- [ ] 数组访问有边界检查
- [ ] UI 更新在主线程执行
- [ ] 共享资源有线程保护
- [ ] 网络请求有超时和错误处理
- [ ] 关键操作有 try-catch
- [ ] 内存警告正确处理
- [ ] 崩溃监控已集成

---

## 参考资源

- [Exception Programming Topics](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/Exceptions/)
- [Thread Safety](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/Multithreading/)
- [WWDC Understanding Crashes](https://developer.apple.com/videos/)
