---
name: networking-data
description: iOS networking and data persistence best practices. Use this skill whenever the user mentions URLSession, API requests, Codable, JSON, CoreData, Realm, UserDefaults, FileManager, or data persistence in iOS apps.
---

# 网络与数据最佳实践

本技能提供 iOS 网络通信和数据持久化的标准工作流程和最佳实践。

## 核心原则

1. **异步优先** - 网络请求必须异步执行
2. **类型安全** - 使用 Codable 进行类型映射
3. **错误处理** - 明确的错误类型和处理
4. **数据缓存** - 合理使用缓存提升体验
5. **安全性** - HTTPS、证书校验、数据加密

---

## 网络请求

### URLSession 基础

```swift
// ✅ 正确：使用 async/await (iOS 15+)
@MainActor
class UserService {

    private let session: URLSession
    private let baseURL: URL

    init(session: URLSession = .shared, baseURL: URL) {
        self.session = session
        self.baseURL = baseURL
    }

    func fetchUser(id: String) async throws -> User {
        let url = baseURL.appendingPathComponent("/users/\(id)")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200:
            return try JSONDecoder().decode(User.self, from: data)
        case 404:
            throw NetworkError.notFound
        case 401:
            throw NetworkError.unauthorized
        default:
            throw NetworkError.httpError(statusCode: httpResponse.statusCode)
        }
    }
}

// 使用
Task {
    do {
        let user = try await userService.fetchUser(id: "123")
        await MainActor.run {
            self.updateUI(with: user)
        }
    } catch {
        await MainActor.run {
            self.showError(error)
        }
    }
}
```

### 定义网络错误类型

```swift
// ✅ 正确：使用 enum 定义网络错误
enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case noData
    case decodingError(String)
    case notFound
    case unauthorized
    case httpError(Int)
    case networkUnavailable
    case timeout
    case sslError

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的 URL"
        case .invalidResponse:
            return "服务器响应异常"
        case .noData:
            return "未收到数据"
        case .decodingError(let message):
            return "数据解析失败：\(message)"
        case .notFound:
            return "请求的资源不存在"
        case .unauthorized:
            return "未授权访问，请登录"
        case .httpError(let code):
            return "服务器错误 (\(code))"
        case .networkUnavailable:
            return "网络连接不可用，请检查网络设置"
        case .timeout:
            return "请求超时，请重试"
        case .sslError:
            return "安全连接失败"
        }
    }
}
```

### API Endpoint 设计

```swift
// ✅ 正确：使用 enum 组织 API 端点
enum APIEndpoint {
    case user(id: String)
    case users
    case login(email: String, password: String)
    case updateUser(id: String, data: [String: Any])

    var path: String {
        switch self {
        case .user(let id):
            return "/users/\(id)"
        case .users:
            return "/users"
        case .login:
            return "/auth/login"
        case .updateUser(let id, _):
            return "/users/\(id)"
        }
    }

    var method: String {
        switch self {
        case .user, .users, .login:
            return "GET"
        case .updateUser:
            return "PUT"
        }
    }

    func body() -> Data? {
        switch self {
        case .updateUser(_, let data):
            return try? JSONSerialization.data(withJSONObject: data)
        default:
            return nil
        }
    }

    func request(baseURL: URL) -> URLRequest {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = body()
        return request
    }
}

// 使用
let request = APIEndpoint.user(id: "123").request(baseURL: baseURL)
```

### 并发请求

```swift
// ✅ 正确：使用 async let 并行请求
@MainActor
func loadDashboardData() async throws -> DashboardData {
    // 并行请求多个接口
    async let users = userService.fetchUsers()
    async let stats = statsService.fetchStats()
    async let notifications = notificationService.fetchNotifications()

    // 等待所有请求完成
    let (usersData, statsData, notificationsData) = try await (users, stats, notifications)

    return DashboardData(
        users: usersData,
        stats: statsData,
        notifications: notificationsData
    )
}

// ✅ 正确：使用 TaskGroup 处理动态数量的请求
func fetchAllUserData(userIds: [String]) async throws -> [User] {
    try await withThrowingTaskGroup(of: User.self) { group in
        for id in userIds {
            group.addTask {
                try await self.userService.fetchUser(id: id)
            }
        }

        var users: [User] = []
        for try await user in group {
            users.append(user)
        }
        return users
    }
}
```

---

## 数据模型

### Codable 使用

```swift
// ✅ 正确：使用 Codable
struct User: Codable, Identifiable {
    let id: String
    let name: String
    let email: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case email
        case createdAt = "created_at"  // 映射蛇形命名
    }
}

// ✅ 正确：自定义日期解码
let decoder = JSONDecoder()
decoder.dateDecodingStrategy = .custom { decoder in
    let container = try decoder.singleValueContainer()
    let dateString = try container.decode(String.self)

    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
    formatter.locale = Locale(identifier: "en_US_POSIX")

    if let date = formatter.date(from: dateString) {
        return date
    }
    throw DecodingError.dataCorruptedError(
        in: container,
        debugDescription: "日期格式错误"
    )
}

let user = try decoder.decode(User.self, from: data)
```

### 处理可选字段

```swift
// ✅ 正确：优雅处理可选和缺失字段
struct Product: Codable {
    let id: String
    let name: String
    let price: Decimal
    let discountPrice: Decimal?  // 可选字段
    let tags: [String]

    enum CodingKeys: String, CodingKey {
        case id, name, price
        case discountPrice = "discount_price"
        case tags
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        price = try container.decode(Decimal.self, forKey: .price)

        // 优雅处理可选字段
        discountPrice = try container.decodeIfPresent(Decimal.self, forKey: .discountPrice)

        // 优雅处理可能类型不匹配的字段
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
    }
}
```

---

## 本地存储

### UserDefaults

```swift
// ✅ 正确：使用@propertyWrapper 封装 UserDefaults
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
class AppSettings {
    @UserDefault(key: "isDarkMode", defaultValue: false)
    static var isDarkMode: Bool

    @UserDefault(key: "hasSeenOnboarding", defaultValue: false)
    static var hasSeenOnboarding: Bool

    @UserDefault(key: "selectedLanguage", defaultValue: "zh-CN")
    static var selectedLanguage: String
}
```

### FileManager

```swift
// ✅ 正确：安全使用 FileManager
class LocalStorage {

    private let fileManager = FileManager.default
    private let documentsURL: URL

    init() {
        documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    func save(data: Data, fileName: String) throws {
        let fileURL = documentsURL.appendingPathComponent(fileName)
        try data.write(to: fileURL, options: .atomic)
    }

    func load(fileName: String) throws -> Data {
        let fileURL = documentsURL.appendingPathComponent(fileName)
        return try Data(contentsOf: fileURL)
    }

    func delete(fileName: String) throws {
        let fileURL = documentsURL.appendingPathComponent(fileName)
        try fileManager.removeItem(at: fileURL)
    }

    func fileExists(fileName: String) -> Bool {
        let fileURL = documentsURL.appendingPathComponent(fileName)
        return fileManager.fileExists(atPath: fileURL.path)
    }
}
```

### 缓存策略

```swift
// ✅ 正确：实现内存 + 磁盘缓存
class ImageCache {

    private let memoryCache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL

    init() {
        let urls = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        cacheDirectory = urls[0].appendingPathComponent("images")
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    func getImage(for url: String, completion: @escaping (UIImage?) -> Void) {
        // 1. 检查内存缓存
        if let image = memoryCache.object(forKey: url as NSString) {
            completion(image)
            return
        }

        // 2. 检查磁盘缓存
        let fileURL = cacheDirectory.appendingPathComponent(url.md5)
        if let data = try? Data(contentsOf: fileURL),
           let image = UIImage(data: data) {
            memoryCache.setObject(image, forKey: url as NSString)
            completion(image)
            return
        }

        // 3. 网络请求
        URLSession.shared.dataTask(with: URL(string: url)!) { data, _, _ in
            guard let data = data, let image = UIImage(data: data) else {
                completion(nil)
                return
            }

            // 存入缓存
            self.memoryCache.setObject(image, forKey: url as NSString)
            try? data.write(to: fileURL)
            completion(image)
        }.resume()
    }
}
```

---

## 数据持久化

### CoreData 基础

```swift
// ✅ 正确：CoreData 封装
class CoreDataStack {

    static let shared = CoreDataStack()

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "AppModel")
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("CoreData 加载失败：\(error)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()

    var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    func save() throws {
        if context.hasChanges {
            try context.save()
        }
    }
}

// Model
@NSManaged public class User: NSManagedObject {
    @NSManaged public var id: String
    @NSManaged public var name: String
    @NSManaged public var email: String?
}

// 使用
func fetchUsers() -> [User] {
    let request: NSFetchRequest<User> = User.fetchRequest()
    request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
    return try? CoreDataStack.shared.context.fetch(request) ?? []
}
```

---

## 检查清单

在提交网络/数据相关代码前，请确认：

- [ ] 网络请求使用异步方式
- [ ] 错误类型定义清晰
- [ ] 使用 Codable 进行 JSON 解析
- [ ] 敏感数据加密存储
- [ ] 实现了适当的缓存策略
- [ ] 处理了网络错误和超时
- [ ] UI 更新在主线程执行
- [ ] 释放了网络资源（cancel）

---

## 参考资源

- [URLSession](https://developer.apple.com/documentation/foundation/urlsession)
- [Codable](https://developer.apple.com/documentation/foundation/archives_and_serialization/encoding_and_decoding_custom_types)
- [CoreData](https://developer.apple.com/documentation/coredata)
